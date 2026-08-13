// lib/ai/chat_history_store.dart
//
// Persists the Fin conversation on-device so it survives navigating away
// from the chat page or fully closing the app.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider.dart';

class ChatHistoryStore {
  static const _messagesKey = 'ai_chat_history_v1';
  static const _savedAtKey = 'ai_chat_history_saved_at_v1';

  // 🛠️ FIX: Extended TTL to 7 days based on your request.
  static const ttl = Duration(days: 7);

  /// Keep the persisted history bounded — old messages roll off, but we
  /// still keep enough for the conversation to feel continuous.
  static const maxMessages = 100;

  Future<List<AiMessage>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAtMs = prefs.getInt(_savedAtKey);
    if (savedAtMs == null) return [];

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    if (DateTime.now().difference(savedAt) > ttl) {
      await clear();
      return [];
    }

    final raw = prefs.getString(_messagesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list.map((m) {
        final map = m as Map<String, dynamic>;
        return AiMessage(
          content: map['content'] as String,
          isUser: map['isUser'] as bool,
          timestamp: DateTime.parse(map['timestamp'] as String),
        );
      }).toList();
    } catch (_) {
      // Don't let a corrupt cache crash the chat page — just start fresh.
      await clear();
      return [];
    }
  }

  Future<void> save(List<AiMessage> history) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = history.length > maxMessages
        ? history.sublist(history.length - maxMessages)
        : history;

    final encoded = jsonEncode(trimmed
        .map((m) => {
      'content': m.content,
      'isUser': m.isUser,
      'timestamp': m.timestamp.toIso8601String(),
    })
        .toList());

    await prefs.setString(_messagesKey, encoded);
    await prefs.setInt(_savedAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
    await prefs.remove(_savedAtKey);
  }
}