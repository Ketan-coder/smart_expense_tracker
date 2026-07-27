// lib/services/ai/smart_spend_ai.dart
//
// THE single file that orchestrates everything.
// Features talk to SmartSpendAI, never to GemmaProvider directly.
//
// Toggle AI on/off:  SmartSpendAI.instance.isEnabled = true/false
// Chat:              SmartSpendAI.instance.chat(message)
// Analyze:           SmartSpendAI.instance.analyzeHabits()

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/helpers.dart';
import 'ai_provider.dart';
import 'context_builder.dart';
import 'gemma_provider.dart';

// ─────────────────────────────────────────────────────────────
// DEVICE CAPABILITY CHECKER
// ─────────────────────────────────────────────────────────────

class DeviceCapabilityChecker {
  static DeviceTier? _cached;

  /// Returns the device tier, cached after first call.
  static Future<DeviceTier> getTier() async {
    if (_cached != null) return _cached!;

    try {
      final info = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        final ramGB = android.systemFeatures.contains('android.hardware.ram.low')
            ? 2
            : 6;

        final sdk = android.version.sdkInt;

        if (sdk >= 34) {
          _cached = DeviceTier.mid;
        } else if (sdk >= 31) {
          _cached = DeviceTier.mid;
        } else {
          _cached = DeviceTier.low;
        }
      } else {
        _cached = DeviceTier.mid;
      }
    } catch (_) {
      _cached = DeviceTier.mid;
    }

    return _cached!;
  }

  static Future<String?> getFriendlyPerformanceMessage() async {
    final tier = await getTier();
    switch (tier) {
      case DeviceTier.high:
        return null;
      case DeviceTier.mid:
        return '✨ Thinking on your device for complete privacy. '
            'Responses may take a few seconds — worth the wait!';
      case DeviceTier.low:
        return '☕ Your device is doing a lot of work to keep your data '
            'private and offline. Responses might be a little slow — '
            'but they\'re all yours!';
      case DeviceTier.unsupported:
        return '📱 Your device may struggle with on-device AI. '
            'We\'ll do our best!';
    }
  }

  static Future<bool> hasEnoughStorage(int requiredBytes) async {
    try {
      final stat = await FileStat.stat(
          Platform.isAndroid ? '/data' : '/');
      return true;
    } catch (_) {
      return true;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// AI STATE
// ─────────────────────────────────────────────────────────────

enum AiState {
  disabled,
  notDownloaded,
  downloading,
  loading,
  ready,
  error,
}

// ─────────────────────────────────────────────────────────────
// SMART SPEND AI
// ─────────────────────────────────────────────────────────────

class SmartSpendAI {
  // Singleton
  static final SmartSpendAI instance = SmartSpendAI._();
  SmartSpendAI._();

  // ── State ──────────────────────────────────────────────────

  AiState _state = AiState.notDownloaded;
  AiState get state => _state;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in _listeners) {
      cb();
    }
  }

  // ── Config ─────────────────────────────────────────────────

  static const _kEnabledKey = 'ai_enabled';

  bool _enabled = true;
  bool get isEnabled => _enabled;
  set isEnabled(bool value) {
    _enabled = value;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_kEnabledKey, value));
    if (!value) {
      _provider?.dispose();
      _state = AiState.disabled;
    } else {
      _state = AiState.notDownloaded;
      _checkAndLoad();
    }
    _notify();
  }

  // ── Internals ──────────────────────────────────────────────

  AiProvider? _provider;
  final ContextBuilder _contextBuilder = ContextBuilder();
  String? _cachedContext;
  DateTime? _contextBuiltAt;

  // ── Initialise ─────────────────────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? true;

    if (!_enabled) {
      _state = AiState.disabled;
      _notify();
      return;
    }

    await _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    if (!_enabled) return;

    if (kDebugMode && const bool.fromEnvironment('AI_MOCK', defaultValue: false)) {
      _provider = MockAiProvider();
      await _provider!.initialize();
      _state = AiState.ready;
      _notify();
      return;
    }

    String? token = await Helpers().getEnvValue('HUGGING_FACE_TOKEN');

    _provider = GemmaProvider(
        huggingFaceToken: token
    );
    final gemma = _provider as GemmaProvider;

    final isDownloaded = await gemma.isDownloaded();

    if (!isDownloaded) {
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

  Future<void> downloadModel({
    void Function(double progress)? onProgress,
  }) async {
    String? token = await Helpers().getEnvValue('HUGGING_FACE_TOKEN');
    _provider ??= GemmaProvider(huggingFaceToken: token);
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

  // Complete system prompt (restored from original)
  String get _systemPrompt => '''
You are Fin, a friendly and insightful personal finance assistant built into SmartSpend. You have access to the user's financial data (provided as JSON context below).

Your personality:
- Warm, encouraging, never judgmental about spending
- Specific and data-driven — always reference actual numbers from the context
- Concise — 2-4 sentences for simple questions, more for complex analysis
- Indian context — understand ₹, UPI, local merchants, Indian spending patterns
- Never make up numbers not present in the context

When you detect patterns:
- Connect spending to habits when you see correlations in the data
- Celebrate savings wins, however small
- Suggest actionable, realistic changes — not generic advice

If asked something you can't answer from the context, say so honestly.
''';

  // ── Chat ───────────────────────────────────────────────────

  Stream<String> chat({
    required List<AiMessage> history,
    required String userMessage,
  }) async* {
    if (!_enabled) {
      yield 'AI assistant is currently disabled. Enable it in Settings.';
      return;
    }

    if (_state != AiState.ready || _provider == null) {
      yield _stateMessage();
      return;
    }

    final context = await _getContext();

    // Build the complete prompt with proper formatting
    final fullPrompt = _buildCompletePrompt(
      systemPrompt: _systemPrompt,
      context: context,
      userMessage: userMessage,
    );

    yield* _provider!.chat(
      history: history,
      userMessage: fullPrompt,
      systemContext: '', // Empty because we've embedded everything
    );
  }

  /// Builds a complete prompt that includes system instructions, context, and the question
  String _buildCompletePrompt({
    required String systemPrompt,
    required String context,
    required String userMessage,
  }) {
    final buffer = StringBuffer();

    // Add system prompt
    buffer.writeln(systemPrompt);
    buffer.writeln();

    // Add the financial data (formatted for clarity)
    buffer.writeln('USER FINANCIAL DATA (JSON format):');
    buffer.writeln(context);
    buffer.writeln();

    // Add the user's question with clear instruction
    buffer.writeln('Based ONLY on the financial data above, answer this question:');
    buffer.writeln(userMessage);
    buffer.writeln();
    buffer.writeln('Remember to use actual numbers from the data and be specific:');

    return buffer.toString();
  }

  // ── Analysis ───────────────────────────────────────────────

  Future<AiInsight> analyzeSpendingPatterns() async {
    if (_state != AiState.ready || _provider == null) {
      return AiInsight(
        title: 'AI Unavailable',
        body: _stateMessage(),
        confidence: 0,
      );
    }

    final context = await _getContext();

    final analysisPrompt = '''
Based on the user's financial data above, identify the 2-3 most significant spending patterns or habits. Look for:
1. Time-of-day or day-of-week patterns
2. Correlations between categories
3. Trends vs previous weeks

Respond in 3-4 sentences, warm and specific. Start directly with the insight.
''';

    final fullPrompt = _buildCompletePrompt(
      systemPrompt: _systemPrompt,
      context: context,
      userMessage: analysisPrompt,
    );

    final result = await _provider!.analyze(
      prompt: fullPrompt,
      systemContext: '',
    );

    return AiInsight(
      title: 'Spending Patterns',
      body: result,
      confidence: 0.8,
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────

  Future<void> onAppBackground() async {
    await Future.delayed(const Duration(minutes: 10));
    if (_state == AiState.ready) {
      await _provider?.dispose();
      _state = AiState.loading;
      _notify();
    }
  }

  Future<void> onAppForeground() async {
    if (_enabled && _state == AiState.loading) {
      await _checkAndLoad();
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  String _stateMessage() {
    switch (_state) {
      case AiState.disabled:
        return 'AI is disabled. Enable it in Settings → AI Assistant.';
      case AiState.notDownloaded:
        return 'The AI model needs to be downloaded first. '
            'Go to Settings → AI Assistant to set it up.';
      case AiState.downloading:
        return 'Model is downloading '
            '(${(_downloadProgress * 100).toStringAsFixed(0)}%). '
            'Please wait a moment!';
      case AiState.loading:
        return 'AI is warming up, just a few seconds...';
      case AiState.error:
        return 'Something went wrong: ${_errorMessage ?? "unknown error"}. '
            'Try restarting the app.';
      case AiState.ready:
        return '';
    }
  }

  String get modelName => _provider?.modelName ?? 'Not loaded';
}