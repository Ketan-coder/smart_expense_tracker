// lib/services/ai/gemma_provider.dart
//
// Concrete AiProvider backed by flutter_gemma (0.13.0+).
// Gemma 4 E2B — using NPU backend (required for Qualcomm variant).

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'ai_provider.dart';

// ─────────────────────────────────────────────────────────────
// MODEL CONFIGS
// ─────────────────────────────────────────────────────────────

class _ModelConfig {
  final String name;
  final String huggingFaceUrl;
  final ModelType modelType;
  final String modelName;
  final int sizeBytes;

  const _ModelConfig({
    required this.name,
    required this.huggingFaceUrl,
    required this.modelType,
    required this.modelName,
    required this.sizeBytes,
  });
}

// ✅ Gemma 4 E2B (Qualcomm NPU-optimized)
const _kDefaultModel = _ModelConfig(
  name: 'Gemma 4 E2B',
  huggingFaceUrl:
  'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
  modelType: ModelType.gemmaIt,
  modelName: 'gemma-4-E2B-it.litertlm',
  sizeBytes: 2400 * 1024 * 1024,
);

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

class GemmaProvider implements AiProvider {
  final _ModelConfig _config;
  final String? _huggingFaceToken;

  InferenceModel? _model;
  bool _isReady = false;
  bool _isInitializing = false;

  GemmaProvider({
    _ModelConfig? config,
    String? huggingFaceToken,
  })  : _config = config ?? _kDefaultModel,
        _huggingFaceToken = huggingFaceToken;

  @override
  bool get isReady => _isReady;

  @override
  String get modelName => _config.name;

  @override
  int get modelSizeBytes => _config.sizeBytes;

  @override
  Future<void> initialize() async {
    if (_isReady || _isInitializing) return;
    _isInitializing = true;

    try {
      debugPrint('🤖 [GemmaProvider] Loading ${_config.name}...');

      await FlutterGemma.initialize(huggingFaceToken: _huggingFaceToken);

      final isInstalled = await FlutterGemma.isModelInstalled(_config.modelName);
      if (!isInstalled) {
        throw ModelNotDownloadedException(
          'Model ${_config.name} is not downloaded yet. '
              'Call GemmaProvider.downloadModel() first.',
        );
      }

      debugPrint('🔄 [GemmaProvider] Setting model as active...');
      await FlutterGemma.installModel(modelType: _config.modelType)
          .fromNetwork(
        _config.huggingFaceUrl,
        token: _huggingFaceToken,
      )
          .install();

      // ←←← THIS IS THE FIX
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,   // NPU is required for this model
      );

      _isReady = true;
      debugPrint('✅ [GemmaProvider] ${_config.name} ready');
    } catch (e) {
      _isInitializing = false;
      debugPrint('❌ [GemmaProvider] Failed to initialize: $e');
      rethrow;
    }

    _isInitializing = false;
  }

  // downloadModel, isDownloaded, chat, analyze, dispose remain the same
  Future<void> downloadModel({
    void Function(double progress)? onProgress,
    void Function(String error)? onError,
  }) async {
    debugPrint('📥 [GemmaProvider] Starting download of ${_config.name}...');

    try {
      await FlutterGemma.installModel(modelType: _config.modelType)
          .fromNetwork(
        _config.huggingFaceUrl,
        token: _huggingFaceToken,
      )
          .withProgress((int percent) {
        onProgress?.call(percent / 100.0);
      })
          .install();

      debugPrint('✅ [GemmaProvider] Download complete');
    } catch (e) {
      debugPrint('❌ [GemmaProvider] Download failed: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  Future<bool> isDownloaded() async {
    try {
      return await FlutterGemma.isModelInstalled(_config.modelName);
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<String> chat({
    required List<AiMessage> history,
    required String userMessage,
    required String systemContext,
  }) async* {
    if (!_isReady || _model == null) {
      yield 'AI is not ready yet. Please wait for the model to load.';
      return;
    }

    try {
      final chat = await _model!.createChat();

      await chat.addQueryChunk(Message.systemInfo(text: systemContext));

      for (final m in history.takeLast(6)) {
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
    } catch (e) {
      debugPrint('❌ [GemmaProvider] Chat error: $e');
      yield '\n\n_Something went wrong. Please try again._';
    }
  }

  @override
  Future<String> analyze({
    required String prompt,
    required String systemContext,
  }) async {
    if (!_isReady || _model == null) return 'AI is not ready.';

    final buffer = StringBuffer();
    await for (final token in chat(
      history: [],
      userMessage: prompt,
      systemContext: systemContext,
    )) {
      buffer.write(token);
    }
    return buffer.toString();
  }

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    _isReady = false;
    _isInitializing = false;
    debugPrint('🧹 [GemmaProvider] Model disposed');
  }
}

// ─────────────────────────────────────────────────────────────
// EXCEPTIONS + EXTENSION
// ─────────────────────────────────────────────────────────────

class ModelNotDownloadedException implements Exception {
  final String message;
  const ModelNotDownloadedException(this.message);
  @override
  String toString() => 'ModelNotDownloadedException: $message';
}

extension _IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    if (list.length <= n) return list;
    return list.sublist(list.length - n);
  }
}