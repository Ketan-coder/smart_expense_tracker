// lib/services/ai/ai_provider.dart
//
// Abstract AI provider interface.
// Everything in SmartSpend talks to THIS, never directly to flutter_gemma.
// Swapping models = implement a new class, change one line in SmartSpendAI.

// ─────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────

/// A single message in the conversation history.
class AiMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  const AiMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

/// Result from any AI analysis call.
class AiInsight {
  final String title;
  final String body;
  final double confidence; // 0.0 – 1.0
  final Map<String, dynamic> rawData; // the pre-computed Dart data used

  const AiInsight({
    required this.title,
    required this.body,
    required this.confidence,
    this.rawData = const {},
  });
}

/// Device capability tier — drives model selection and UX messaging.
enum DeviceTier {
  high,   // NPU + 8GB+  → Gemma3n E4B
  mid,    // 4–8 GB      → Gemma3n E2B / Gemma 3 1B
  low,    // <4 GB       → Gemma 3 1B with warning
  unsupported, // <2 GB  → cloud fallback only
}

// ─────────────────────────────────────────────────────────────
// ABSTRACT PROVIDER
// ─────────────────────────────────────────────────────────────

/// Every AI backend (Gemma 3, Gemma3n, future Gemma 4, cloud) implements this.
abstract class AiProvider {
  /// Whether the model is loaded and ready.
  bool get isReady;

  /// Human-readable model name shown in the UI.
  String get modelName;

  /// Approximate model size in bytes (for storage checks).
  int get modelSizeBytes;

  /// Initialize / load the model. Safe to call multiple times.
  Future<void> initialize();

  /// Stream tokens for a user message given the full conversation history.
  /// [systemContext] is the JSON financial snapshot built by ContextBuilder.
  Stream<String> chat({
    required List<AiMessage> history,
    required String userMessage,
    required String systemContext,
  });

  /// Single-shot analysis — no streaming, returns complete response.
  Future<String> analyze({
    required String prompt,
    required String systemContext,
  });

  /// Free model memory. Called when app backgrounds for >10 min.
  Future<void> dispose();
}

// ─────────────────────────────────────────────────────────────
// MOCK PROVIDER  (used in tests and when AI is disabled)
// ─────────────────────────────────────────────────────────────

class MockAiProvider implements AiProvider {
  @override
  bool get isReady => true;

  @override
  String get modelName => 'Mock (Testing)';

  @override
  int get modelSizeBytes => 0;

  @override
  Future<void> initialize() async {}

  @override
  Stream<String> chat({
    required List<AiMessage> history,
    required String userMessage,
    required String systemContext,
  }) async* {
    await Future.delayed(const Duration(milliseconds: 300));
    yield 'This is a mock response for: "$userMessage". ';
    await Future.delayed(const Duration(milliseconds: 200));
    yield 'AI features are working correctly in test mode.';
  }

  @override
  Future<String> analyze({
    required String prompt,
    required String systemContext,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Mock analysis complete.';
  }

  @override
  Future<void> dispose() async {}
}