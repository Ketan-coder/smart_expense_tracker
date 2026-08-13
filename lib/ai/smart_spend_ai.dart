// lib/ai/smart_spend_ai.dart
//
// 3-tier AI orchestrator. All features talk to this — never to GemmaProvider.
//
// Tiers:
//   HIGH  (Android 14+ / 6GB+) → Gemma 4 E2B  (kHighTierModel)
//   MID   (Android 12-13)      → Gemma 3 1B   (kMidTierModel)
//   LOW   (<Android 12 / <4GB) → InsightsOnly  (no model, no download)
//
// AiState.unsupported is the LOW tier state — ai_chat_page handles it.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/helpers.dart';
import 'ai_provider.dart';
import 'context_builder.dart';
import 'gemma_provider.dart';
import 'memory_store.dart';

// ─────────────────────────────────────────────────────────────
// DEVICE CAPABILITY CHECKER
// ─────────────────────────────────────────────────────────────

class DeviceCapabilityChecker {
  static DeviceTier? _cached;

  static Future<DeviceTier> getTier() async {
    if (_cached != null) return _cached!;

    try {
      if (!Platform.isAndroid) {
        _cached = DeviceTier.mid;
        return _cached!;
      }

      final android = await DeviceInfoPlugin().androidInfo;
      final sdk = android.version.sdkInt;
      final isLowRam =
      android.systemFeatures.contains('android.hardware.ram.low');

      if (isLowRam) {
        _cached = DeviceTier.low;
      } else if (sdk >= 34) {
        _cached = DeviceTier.high;
      } else if (sdk >= 31) {
        _cached = DeviceTier.mid;
      } else {
        _cached = DeviceTier.low;
      }
    } catch (_) {
      _cached = DeviceTier.mid;
    }

    debugPrint('📱 [DeviceCapability] Tier: $_cached');
    return _cached!;
  }

  /// Which ModelConfig this device should use. Null = LOW tier (no model).
  static Future<ModelConfig?> getModelConfig() async {
    final tier = await getTier();
    switch (tier) {
      case DeviceTier.high:
        return kHighTierModel;
      case DeviceTier.mid:
        return kMidTierModel;
      case DeviceTier.low:
      case DeviceTier.unsupported:
        return null;
    }
  }

  /// Short label for AppBar subtitle — "Gemma 4 E2B", "Gemma 3 1B", or "Insights Mode".
  static Future<String> getModelLabel() async {
    final config = await getModelConfig();
    return config?.name ?? 'Insights Mode';
  }

  /// Download size shown in the download prompt button.
  static Future<String> getDownloadSizeLabel() async {
    final config = await getModelConfig();
    return config?.downloadSizeLabel ?? '';
  }

  /// Friendly one-liner shown at the top of chat. Null = high tier (silent).
  static Future<String?> getFriendlyPerformanceMessage() async {
    final tier = await getTier();
    switch (tier) {
      case DeviceTier.high:
        return null;
      case DeviceTier.mid:
        return '✨ Thinking privately on your device — may take a few seconds.';
      case DeviceTier.low:
      case DeviceTier.unsupported:
        return null; // InsightsOnly has its own UI
    }
  }

  static Future<bool> hasEnoughStorage(int requiredBytes) async => true;
}

// ─────────────────────────────────────────────────────────────
// AI STATE  — matches what ai_chat_page.dart switch-cases on
// ─────────────────────────────────────────────────────────────

enum AiState {
  disabled,       // User toggled AI off
  unsupported,    // LOW tier device — InsightsOnly mode
  notDownloaded,  // Model not on device yet
  downloading,    // Download in progress
  loading,        // Model on disk, loading into memory
  ready,          // Full AI chat available
  error,          // Something went wrong
}

// ─────────────────────────────────────────────────────────────
// SMART SPEND AI
// ─────────────────────────────────────────────────────────────

class SmartSpendAI {
  static final SmartSpendAI instance = SmartSpendAI._();
  SmartSpendAI._();

  // ── State ──────────────────────────────────────────────────

  AiState _state = AiState.notDownloaded;
  AiState get state => _state;

  DeviceTier _deviceTier = DeviceTier.mid;
  DeviceTier get deviceTier => _deviceTier;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Returns the name of the active model, or a default label.
  String get modelName => _activeConfig?.name ?? 'Insights Mode';

  /// True when this device can run a model.
  bool get isAiCapable =>
      _deviceTier == DeviceTier.high || _deviceTier == DeviceTier.mid;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in _listeners) cb();
  }

  // ── Config ─────────────────────────────────────────────────

  static const _kEnabledKey = 'ai_enabled';

  bool _enabled = true;
  bool get isEnabled => _enabled;
  set isEnabled(bool value) {
    _enabled = value;
    SharedPreferences.getInstance().then((p) => p.setBool(_kEnabledKey, value));
    if (!value) {
      _provider?.dispose();
      _state = AiState.disabled;
    } else {
      _checkAndLoad();
    }
    _notify();
  }

  AiProvider? _provider;
  ModelConfig? _activeConfig;
  final ContextBuilder _contextBuilder = ContextBuilder();
  final MemoryStore _memoryStore = MemoryStore();
  String? _cachedContext;
  DateTime? _contextBuiltAt;

  // ── Initialize ─────────────────────────────────────────────

  /// Call once at app startup, after Hive is ready.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? true;

    // Detect tier first — everything else depends on it
    _deviceTier = await DeviceCapabilityChecker.getTier();

    if (!_enabled) {
      _state = AiState.disabled;
      _notify();
      return;
    }

    if (!isAiCapable) {
      _state = AiState.unsupported;
      _notify();
      return;
    }

    await _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    if (!_enabled || !isAiCapable) return;

    // Dev shortcut: flutter run --dart-define=AI_MOCK=true
    if (kDebugMode &&
        const bool.fromEnvironment('AI_MOCK', defaultValue: false)) {
      _provider = MockAiProvider();
      await _provider!.initialize();
      _state = AiState.ready;
      _notify();
      return;
    }

    _activeConfig = await DeviceCapabilityChecker.getModelConfig();
    if (_activeConfig == null) {
      _state = AiState.unsupported;
      _notify();
      return;
    }

    final token = await Helpers().getEnvValue('HUGGING_FACE_TOKEN');

    _provider = GemmaProvider(
      config: _activeConfig!,
      huggingFaceToken: token,
    );
    final gemma = _provider as GemmaProvider;

    final downloaded = await gemma.isDownloaded();
    if (!downloaded) {
      _state = AiState.notDownloaded;
      _notify();
      return;
    }

    _state = AiState.loading;
    _notify();

    try {
      await gemma.initialize();
      _state = AiState.ready;
    } catch (e) {
      _state = AiState.error;
      _errorMessage = e.toString();
    }
    _notify();
  }

  // ── Download ───────────────────────────────────────────────

  Future<void> downloadModel({void Function(double)? onProgress}) async {
    if (_activeConfig == null) {
      _activeConfig = await DeviceCapabilityChecker.getModelConfig();
    }
    if (_activeConfig == null) return; // LOW tier device

    final token = await Helpers().getEnvValue('HUGGING_FACE_TOKEN');

    _provider ??= GemmaProvider(
      config: _activeConfig!,
      huggingFaceToken: token,
    );
    final gemma = _provider as GemmaProvider;

    _state = AiState.downloading;
    _downloadProgress = 0.0;
    _notify();

    try {
      await gemma.downloadModel(
        onProgress: (p) {
          _downloadProgress = p;
          onProgress?.call(p);
          _notify();
        },
        onError: (err) {
          _state = AiState.error;
          _errorMessage = err;
          _notify();
        },
      );

      _state = AiState.loading;
      _notify();
      await gemma.initialize();
      _state = AiState.ready;
    } catch (e) {
      _state = AiState.error;
      _errorMessage = e.toString();
    }
    _notify();
  }

  // ── Context ────────────────────────────────────────────────

  Future<String> _getContext() async {
    final now = DateTime.now();
    if (_cachedContext != null &&
        _contextBuiltAt != null &&
        now.difference(_contextBuiltAt!).inMinutes < 5) {
      return _cachedContext!;
    }
    _cachedContext = await _contextBuilder.buildFullContext();
    _contextBuiltAt = now;
    return _cachedContext!;
  }

  String _buildSystemContext(
      String financialContext, {
        String? userMessage,
      }) {
    final languageInstruction = _getLanguageInstruction(
      userMessage ?? '',
    );

    return '''
You are Fin, a personal finance assistant inside SmartSpend.

RULES:

1. Only use numbers and facts from the financial data below.

2. If data for something is missing, say "I don't see that in your data" —
   never guess.

3. Be warm, natural, and specific.
   Reference actual ₹ amounts instead of vague statements.

4. Keep answers concise:
   2-5 sentences unless the user asks for more detail.

5. You understand Indian context:
   ₹, UPI, EMI, Swiggy, Zomato, NACH, local merchants.

6. LANGUAGE:
   $languageInstruction

7. NEVER translate the user's question into another language before
   answering it.

8. Answer naturally in the requested language.
   Do not mention that you detected the language.

FINANCIAL DATA:
$financialContext
''';
  }

  String _getLanguageInstruction(
      String userMessage,
      ) {
    final message = userMessage.trim();

    if (message.isEmpty) {
      return '''
Respond in the same language used by the user.
''';
    }

    // Hindi / Devanagari
    if (RegExp(r'[\u0900-\u097F]').hasMatch(message)) {
      return '''
The user is writing in Hindi using Devanagari script.

Respond in Hindi using Devanagari script.

Do NOT answer in English unless the user explicitly asks for English.

Technical terms, product names, financial terms, and numbers may remain
in English when that sounds natural, but the sentence itself should be
Hindi.
''';
    }

    // Bengali
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(message)) {
      return '''
The user is writing in Bengali.

Respond in Bengali using Bengali script.
Do NOT answer in English unless the user explicitly asks for English.
''';
    }

    // Gujarati
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(message)) {
      return '''
The user is writing in Gujarati.

Respond in Gujarati using Gujarati script.
Do NOT answer in English unless the user explicitly asks for English.
''';
    }

    // Gurmukhi / Punjabi
    if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(message)) {
      return '''
The user is writing in Punjabi.

Respond in Punjabi using Gurmukhi script.
Do NOT answer in English unless the user explicitly asks for English.
''';
    }

    // Tamil
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(message)) {
      return '''
The user is writing in Tamil.

Respond in Tamil using Tamil script.
Do NOT answer in English unless the user explicitly asks for English.
''';
    }

    // Telugu
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(message)) {
      return '''
The user is writing in Telugu.

Respond in Telugu using Telugu script.
Do NOT answer in English unless the user explicitly asks for English.
''';
    }

    // Kannada
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(message)) {
      return '''
The user is writing in Kannada.

Respond in Kannada using Kannada script.
Do NOT answer in English unless the user explicitly asks for English.
''';
    }

    // Malayalam
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(message)) {
      return '''
The user is writing in Malayalam.

Respond in Malayalam using Malayalam script.
Do NOT answer in English unless the user explicitly asks for English.
''';
    }

    // Arabic / Urdu
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(message)) {
      return '''
The user is writing using Arabic-derived script.

Respond in the same language and script used by the user.
Do NOT switch to English unless explicitly requested.
''';
    }

    // Default: English / Latin script
    return '''
Respond in the same language used by the user.

If the user writes in English, respond in English.

If the user writes in another Latin-script language, respond in that
same language.

Do not unnecessarily translate the user's message.
''';
  }

  // ── Chat ───────────────────────────────────────────────────

  Stream<String> chat({
    required List<AiMessage> history,
    required String userMessage,
  }) async* {
    if (!_enabled) {
      yield 'AI assistant is disabled. Enable it in Settings.';
      return;
    }
    if (_state != AiState.ready || _provider == null) {
      yield 'AI is not ready yet.';
      return;
    }

    final systemContext = await _buildPersonalizedSystemContext();

    final buffer = StringBuffer();
    await for (final token in _provider!.chat(
      history: history,
      userMessage: userMessage,
      systemContext: systemContext,
    )) {
      buffer.write(token);
      yield token;
    }

    // Learn from this exchange in the background — never blocks the reply.
    unawaited(_maybeExtractMemories(userMessage, buffer.toString()));
  }

  /// Builds the financial-data + memories system prompt shared by chat()
  /// and ask().
  Future<String> _buildPersonalizedSystemContext() async {
    final financialContext = await _getContext();
    final memories = await _memoryStore.load();
    final memoryBlock = _memoryStore.toContextBlock(memories);
    final combined = memoryBlock.isEmpty
        ? financialContext
        : '$financialContext\n\n$memoryBlock';
    return _buildSystemContext(combined);
  }

  /// Fire-and-forget: asks the on-device model to pull out any new,
  /// durable facts about the user from the exchange that just happened,
  /// and stores them via [MemoryStore] for future personalization.
  Future<void> _maybeExtractMemories(
      String userMessage,
      String assistantReply,
      ) async {
    try {
      // Don't run memory extraction for empty conversations.
      if (userMessage.trim().isEmpty) {
        return;
      }

      final existingMemories =
      await _memoryStore.load();

      final existingList = existingMemories.isEmpty
          ? 'None'
          : existingMemories
          .map(
            (m) =>
        '- ${m.key}: ${m.fact} '
            '(type: ${m.type.name})',
      )
          .join('\n');

      final prompt = '''
You maintain durable memory about the user.

Your job is to extract ONLY information that is genuinely about
the user and useful for future conversations.

DO NOT store:
- One-off questions
- Temporary conversation details
- Facts about other people
- Information invented or assumed by the assistant
- Financial transaction information already available from SmartSpend
- Temporary emotions or moods
- Information that is not useful later
- Episodic memories

You MUST NOT create episodic memories.

Allowed memory types:

1. profile
   Stable facts about the user.

2. preference
   Things the user likes, dislikes, or prefers.

3. goal
   Things the user wants to achieve.

4. project
   Projects, studies, work, or technical projects the user
   is actively involved in.

Existing memories:

$existingList

User message:
"$userMessage"

Assistant response:
"$assistantReply"

Return ONLY valid JSON.

Format:

[
  {
    "key": "unique_stable_key",
    "type": "profile",
    "fact": "short factual statement",
    "confidence": 0.95,
    "importance": 0.90
  }
]

Allowed type values:
"profile"
"preference"
"goal"
"project"

Rules:

- Maximum 3 memories per conversation.
- Maximum 20 words per fact.
- confidence must be between 0.0 and 1.0.
- importance must be between 0.0 and 1.0.
- Do not invent information.
- Do not infer information that the user did not state.
- If an existing memory changed, use the SAME key so it can be updated.
- If nothing should be remembered, return [].
''';

      final result = await _provider?.analyze(
        prompt: prompt,
        systemContext: '''
You are a memory extraction system.

Return ONLY JSON.
Do not explain your answer.
Do not use markdown.
'''
      );

      if (result!.trim().isEmpty) {
        return;
      }

      // ---------------------------------------------------------
      // Remove accidental markdown fences.
      // ---------------------------------------------------------

      var cleaned = result.trim();

      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(
          RegExp(r'^```(?:json)?\s*'),
          '',
        )
            .replaceFirst(
          RegExp(r'\s*```$'),
          '',
        )
            .trim();
      }

      // ---------------------------------------------------------
      // Parse JSON.
      // ---------------------------------------------------------

      final decoded = jsonDecode(cleaned);

      if (decoded is! List) {
        return;
      }

      // ---------------------------------------------------------
      // Process extracted memories.
      // ---------------------------------------------------------

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        final key = item['key'];
        final typeName = item['type'];
        final fact = item['fact'];

        if (key is! String ||
            typeName is! String ||
            fact is! String) {
          continue;
        }

        final type = MemoryType.values.firstWhere(
              (type) => type.name == typeName,
          orElse: () => MemoryType.profile,
        );

        final confidence =
            (item['confidence'] as num?)
                ?.toDouble() ??
                0.5;

        final importance =
            (item['importance'] as num?)
                ?.toDouble() ??
                0.5;

        // -------------------------------------------------------
        // Ignore weak memories.
        // -------------------------------------------------------

        if (confidence < 0.65) {
          continue;
        }

        if (importance < 0.35) {
          continue;
        }

        // -------------------------------------------------------
        // Save/update structured memory.
        // -------------------------------------------------------

        await _memoryStore.upsertMemory(
          key: key,
          fact: fact,
          type: type,
          confidence: confidence,
          importance: importance,
        );
      }
    } catch (e) {
      // Memory extraction should NEVER break the main AI chat.
      debugPrint(
        '[Memory] Extraction failed: $e',
      );
    }
  }

  // ── Memories (for Settings / "What Fin remembers" UI) ────────

  Future<List<UserMemory>> getMemories() => _memoryStore.load();

  Future<void> forgetMemory(String id) => _memoryStore.removeMemory(id);

  Future<void> clearMemories() => _memoryStore.clear();

  // ── Universal AI entry point ──────────────────────────────────

  /// Single entry point for ANY feature in the app that wants an AI-backed
  /// answer — handles context (financial snapshot + on-device memories)
  /// and device-capability gating in one call. Every screen should call
  /// THIS, never GemmaProvider or ContextBuilder directly.
  ///
  /// Returns the model's answer as a [String] when this device currently
  /// has AI ready to use.
  ///
  /// Returns `false` when it can't currently produce an AI answer — LOW
  /// tier device, model not downloaded yet, AI disabled, etc.
  /// Callers MUST check for this and fall back to their own non-AI UX.
  Future<dynamic> ask(
      String prompt, {
        String? extraContext,
        bool includeMemories = true,
      }) async {

    // Fast fail if disabled or low-tier device
    if (!_enabled || !isAiCapable) {
      return false;
    }

    // Wait for readiness if it's still downloading or loading
    if (_state != AiState.ready || _provider == null) {
      return false;
    }

    try {
      final financialContext = await _getContext();
      String systemContext = financialContext;

      if (includeMemories) {
        final memories = await _memoryStore.load();
        final memoryBlock = _memoryStore.toContextBlock(memories);
        if (memoryBlock.isNotEmpty) {
          systemContext += '\n\n$memoryBlock';
        }
      }

      if (extraContext != null && extraContext.isNotEmpty) {
        systemContext += '\n\nADDITIONAL CONTEXT:\n$extraContext';
      }

      final finalContext = _buildSystemContext(systemContext);

      // Perform single-shot inference
      final answer = await _provider!.analyze(
        prompt: prompt,
        systemContext: finalContext,
      );

      return answer;
    } catch (e) {
      debugPrint('⚠️ [SmartSpendAI] ask() failed: $e');
      return false;
    }
  }
}