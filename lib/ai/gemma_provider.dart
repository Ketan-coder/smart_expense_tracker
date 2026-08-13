// lib/ai/gemma_provider.dart
//
// Concrete AiProvider backed by flutter_gemma (0.13.x+).
// ModelConfig is PUBLIC so SmartSpendAI can pass the right tier config.
// To upgrade model: change one constant below — nothing else changes.

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider.dart';

// ─────────────────────────────────────────────────────────────
// PUBLIC MODEL CONFIG  (used by SmartSpendAI for tier selection)
// ─────────────────────────────────────────────────────────────

class ModelConfig {
  final String name;
  final String huggingFaceUrl;
  final ModelType modelType;
  final String modelFileName;
  final int sizeBytes;
  final PreferredBackend preferredBackend;
  final int maxTokens;

  const ModelConfig({
    required this.name,
    required this.huggingFaceUrl,
    required this.modelType,
    required this.modelFileName,
    required this.sizeBytes,
    required this.preferredBackend,
    required this.maxTokens,
  });

  String get downloadSizeLabel {
    final mb = sizeBytes ~/ (1024 * 1024);
    return mb >= 1000
        ? '${(mb / 1024).toStringAsFixed(1)} GB'
        : '${mb} MB';
  }
}

// ── HIGH tier: Gemma 4 E2B — 6GB+ RAM, ~2.4GB storage ───────
const kHighTierModel = ModelConfig(
  name: 'Gemma 4 E2B',
  huggingFaceUrl:
  'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
  modelType: ModelType.gemmaIt,
  modelFileName: 'gemma-4-E2B-it.litertlm',
  sizeBytes: 2400 * 1024 * 1024,
  preferredBackend: PreferredBackend.gpu,
  maxTokens: 2048,
);

// ── MID tier: Gemma 3 1B — 4GB+ RAM, ~500MB storage ─────────
const kMidTierModel = ModelConfig(
  name: 'Gemma 3 1B',
  huggingFaceUrl:
  'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task',
  modelType: ModelType.gemmaIt,
  modelFileName: 'gemma3-1b-it-int4.task',
  sizeBytes: 500 * 1024 * 1024,
  preferredBackend: PreferredBackend.gpu,
  maxTokens: 1024,
);

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

class GemmaProvider implements AiProvider {
  final ModelConfig _config;
  final String? _huggingFaceToken;

  InferenceModel? _model;
  bool _isReady = false;
  bool _isInitializing = false;
  static bool _pluginInitialized = false;

  GemmaProvider({
    required ModelConfig config,
    String? huggingFaceToken,
  })  : _config = config,
        _huggingFaceToken = huggingFaceToken;

  @override
  bool get isReady => _isReady;

  @override
  String get modelName => _config.name;

  @override
  int get modelSizeBytes => _config.sizeBytes;

  Future<void> _ensurePluginInitialized() async {
    if (!_pluginInitialized) {
      try {
        // FlutterGemma is initialized globally in main.dart
        _pluginInitialized = true;
      } catch (e) {
        debugPrint('⚠️ [GemmaProvider] initialization error: $e');
      }
    }
  }

  // ── Initialize ─────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    if (_isReady || _isInitializing) return;

    _isInitializing = true;

    try {
      debugPrint('🤖 [GemmaProvider] Loading ${_config.name}...');

      await _ensurePluginInitialized();

      final modelManager = FlutterGemmaPlugin.instance.modelManager;

      debugPrint(
        '📦 [GemmaProvider] Checking model readiness...',
      );

      // IMPORTANT:
      // ensureModelReady() handles both cases:
      //
      // 1. Model already exists:
      //      → restore/use it
      //      → do NOT download it again
      //
      // 2. Model doesn't exist:
      //      → download it from the supplied URL
      //
      // This is important because after an Android restart
      // the model file can exist while no active model is set.
      await modelManager.ensureModelReady(
        _config.modelFileName,
        _config.huggingFaceUrl,
      );

      debugPrint(
        '✅ [GemmaProvider] Model is ready.',
      );

      debugPrint(
        '🔍 [GemmaProvider] Active model: '
            '${FlutterGemma.hasActiveModel()}',
      );

      _model = await FlutterGemma.getActiveModel(
        maxTokens: _config.maxTokens,
        preferredBackend: _config.preferredBackend,
      );

      _isReady = true;
      _isInitializing = false;

      debugPrint(
        '✅ [GemmaProvider] ${_config.name} ready',
      );
    } catch (e, stackTrace) {
      _isInitializing = false;

      debugPrint(
        '❌ [GemmaProvider] initialize failed: $e',
      );

      debugPrint(
        '📍 StackTrace:\n$stackTrace',
      );

      rethrow;
    }
  }

  // ── Download ───────────────────────────────────────────────

  Future<void> downloadModel({
    void Function(double progress)? onProgress,
    void Function(String error)? onError,
  }) async {
    debugPrint('📥 [GemmaProvider] Downloading ${_config.name}...');
    try {
      await _ensurePluginInitialized();

      await FlutterGemma.installModel(modelType: _config.modelType)
          .fromNetwork(
        _config.huggingFaceUrl,
        token: _huggingFaceToken,
      )
          .withProgress((int percent) {
        onProgress?.call(percent / 100.0);
      })
          .install();

      // Record our own "this device has downloaded this model" flag.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_downloadedPrefsKey, true);

      debugPrint('✅ [GemmaProvider] Download complete');
    } catch (e) {
      debugPrint('❌ [GemmaProvider] Download failed: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  String get _downloadedPrefsKey =>
      'gemma_model_downloaded_${_config.modelFileName}';

  Future<bool> isDownloaded() async {
    try {
      await _ensurePluginInitialized();

      final prefs = await SharedPreferences.getInstance();
      final recordedDownloaded = prefs.getBool(_downloadedPrefsKey) ?? false;

      // 🛠️ FIX FOR WEB APP REFRESH:
      // Cache API might take a moment to be readable after a fast refresh,
      // causing isModelInstalled to return false and erase your model.
      // If we previously recorded a complete download locally, we trust it
      // first. If it's truly not there, getActiveModel will throw safely later.
      if (kIsWeb && recordedDownloaded) {
        return true;
      }

      final installed = await FlutterGemma.isModelInstalled(_config.modelFileName);
      if (installed) {
        await prefs.setBool(_downloadedPrefsKey, true);
        return true;
      }

      // Final fallback for edge cases
      if (recordedDownloaded) {
        await Future.delayed(const Duration(milliseconds: 500));
        return await FlutterGemma.isModelInstalled(_config.modelFileName);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Chat ───────────────────────────────────────────────────

  @override
  Stream<String> chat({
    required List<AiMessage> history,
    required String userMessage,
    required String systemContext,
  }) async* {
    if (!_isReady || _model == null) {
      yield 'AI is not ready yet.';
      return;
    }

    try {
      final chat = await _model!.createChat(
        systemInstruction: systemContext.isNotEmpty ? systemContext : null,
        temperature: 0.7,
        topK: 40,
      );

      // Last 8 messages = 4 exchanges — keeps context tight
      for (final m in history.takeLast(8)) {
        await chat.addQueryChunk(
          Message.text(text: m.content, isUser: m.isUser),
        );
      }

      await chat.addQueryChunk(
        Message.text(text: userMessage, isUser: true),
      );

      await for (final chunk in chat.generateChatResponseAsync()) {
        if (chunk is TextResponse) {
          yield chunk.token;
        }
      }

      await chat.close();
    } catch (e) {
      debugPrint('❌ [GemmaProvider] Chat error: $e');
      yield '\n\nSomething went wrong. Please try again.';
    }
  }

  // ── Analyze ────────────────────────────────────────────────

  @override
  Future<String> analyze({
    required String prompt,
    required String systemContext,
  }) async {
    if (!_isReady || _model == null) return 'AI is not ready.';
    final buf = StringBuffer();
    await for (final token in chat(
      history: [],
      userMessage: prompt,
      systemContext: systemContext,
    )) {
      buf.write(token);
    }
    return buf.toString();
  }

  // ── Dispose ────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    _isReady = false;
    _isInitializing = false;
    debugPrint('🧹 [GemmaProvider] Disposed');
  }
}

// ─────────────────────────────────────────────────────────────

class ModelNotDownloadedException implements Exception {
  final String message;
  const ModelNotDownloadedException(this.message);
  @override
  String toString() => 'ModelNotDownloadedException: $message';
}

extension _IterableExt<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    return list.length <= n ? list : list.sublist(list.length - n);
  }
}