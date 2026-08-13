// lib/ai/memory_store.dart
//
// On-device durable memory about the user.
//
// Memory types:
//   - profile     → stable facts about the user
//   - preference  → things the user likes / prefers
//   - goal        → things the user wants to achieve
//   - project     → projects / work the user is currently involved in
//
// Episodic memory is intentionally NOT stored.
//
// Everything stays on-device using SharedPreferences.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


// ═══════════════════════════════════════════════════════════════
// MEMORY TYPE
// ═══════════════════════════════════════════════════════════════

enum MemoryType {
  profile,
  preference,
  goal,
  project,
}


// ═══════════════════════════════════════════════════════════════
// USER MEMORY
// ═══════════════════════════════════════════════════════════════

class UserMemory {
  final String id;

  /// Stable identifier for the information.
  ///
  /// Example:
  ///   "occupation"
  ///   "response_style"
  ///   "current_project"
  ///   "savings_goal"
  final String key;

  /// Human-readable information.
  final String fact;

  /// What kind of memory this is.
  final MemoryType type;

  /// How certain we are that this information is correct.
  ///
  /// 0.0 = uncertain
  /// 1.0 = very certain
  final double confidence;

  /// How useful this memory is for future conversations.
  ///
  /// 0.0 = almost useless
  /// 1.0 = extremely useful
  final double importance;

  final DateTime createdAt;

  /// Updated whenever the same memory key changes.
  final DateTime updatedAt;

  const UserMemory({
    required this.id,
    required this.key,
    required this.fact,
    required this.type,
    required this.confidence,
    required this.importance,
    required this.createdAt,
    required this.updatedAt,
  });

  // ─────────────────────────────────────────────────────────────
  // JSON
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'fact': fact,
      'type': type.name,
      'confidence': confidence,
      'importance': importance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserMemory.fromJson(
      Map<String, dynamic> json,
      ) {
    final createdAtRaw = json['createdAt'];

    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();

    final updatedAtRaw = json['updatedAt'];

    final updatedAt = updatedAtRaw is String
        ? DateTime.tryParse(updatedAtRaw) ?? createdAt
        : createdAt;

    final typeName = json['type'];

    final type = MemoryType.values.firstWhere(
          (e) => e.name == typeName,
      orElse: () => MemoryType.profile,
    );

    return UserMemory(
      id: json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),

      // Backwards compatibility:
      //
      // Old memories did not have a key.
      // Use the old fact as a temporary key.
      key: json['key'] as String? ??
          (json['fact'] as String? ?? 'unknown'),

      fact: json['fact'] as String? ?? '',

      type: type,

      confidence:
      (json['confidence'] as num?)?.toDouble() ?? 1.0,

      importance:
      (json['importance'] as num?)?.toDouble() ?? 0.5,

      createdAt: createdAt,

      updatedAt: updatedAt,
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// MEMORY STORE
// ═══════════════════════════════════════════════════════════════

class MemoryStore {
  static const _key = 'ai_user_memories_v1';

  /// Maximum number of memories stored locally.
  ///
  /// We deliberately keep this small because SmartSpend AI runs
  /// a relatively small local model and we don't want memories
  /// consuming a large part of its context window.
  static const maxMemories = 40;


  // ═══════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════

  Future<List<UserMemory>> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => UserMemory.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .where((memory) => memory.fact.trim().isNotEmpty)
          .toList();
    } catch (e) {
      // A corrupted memory cache should never break the AI.
      return [];
    }
  }


  // ═══════════════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════════════

  Future<void> _saveAll(
      List<UserMemory> memories,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      memories
          .map((memory) => memory.toJson())
          .toList(),
    );

    await prefs.setString(
      _key,
      encoded,
    );
  }


  // ═══════════════════════════════════════════════════════════
  // UPSERT MEMORY
  // ═══════════════════════════════════════════════════════════
  //
  // "Upsert" means:
  //
  //   memory doesn't exist → create it
  //
  //   memory already exists → update it
  //
  // Example:
  //
  //   savings_goal = "₹5 lakh"
  //
  // later:
  //
  //   savings_goal = "₹10 lakh"
  //
  // Instead of storing two memories, the old one is updated.
  //
  // ═══════════════════════════════════════════════════════════

  Future<void> upsertMemory({
    required String key,
    required String fact,
    required MemoryType type,
    required double confidence,
    required double importance,
  }) async {
    final trimmedKey = key.trim();
    final trimmedFact = fact.trim();

    if (trimmedKey.isEmpty) {
      return;
    }

    if (trimmedFact.isEmpty) {
      return;
    }

    // Prevent enormous memory entries.
    if (trimmedFact.length > 200) {
      return;
    }

    final memories = await load();

    final normalizedKey =
    trimmedKey.toLowerCase();

    final now = DateTime.now();

    final existingIndex = memories.indexWhere(
          (memory) =>
      memory.key.trim().toLowerCase() ==
          normalizedKey,
    );

    final safeConfidence =
    confidence.clamp(0.0, 1.0).toDouble();

    final safeImportance =
    importance.clamp(0.0, 1.0).toDouble();

    // ─────────────────────────────────────────────────────────
    // UPDATE EXISTING MEMORY
    // ─────────────────────────────────────────────────────────

    if (existingIndex >= 0) {
      final existing = memories[existingIndex];

      memories[existingIndex] = UserMemory(
        id: existing.id,
        key: trimmedKey,
        fact: trimmedFact,
        type: type,
        confidence: safeConfidence,
        importance: safeImportance,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
    }

    // ─────────────────────────────────────────────────────────
    // CREATE NEW MEMORY
    // ─────────────────────────────────────────────────────────

    else {
      memories.add(
        UserMemory(
          id: now.microsecondsSinceEpoch.toString(),
          key: trimmedKey,
          fact: trimmedFact,
          type: type,
          confidence: safeConfidence,
          importance: safeImportance,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // ─────────────────────────────────────────────────────────
    // SORT
    // ─────────────────────────────────────────────────────────
    //
    // Important memories stay at the top.
    //
    // We combine:
    //
    //   70% importance
    //   30% confidence
    //
    // This prevents uncertain memories from outranking
    // important and reliable memories.
    //
    memories.sort(
          (a, b) {
        final scoreA =
            (a.importance * 0.7) +
                (a.confidence * 0.3);

        final scoreB =
            (b.importance * 0.7) +
                (b.confidence * 0.3);

        return scoreB.compareTo(scoreA);
      },
    );

    // ─────────────────────────────────────────────────────────
    // ENFORCE MEMORY LIMIT
    // ─────────────────────────────────────────────────────────

    if (memories.length > maxMemories) {
      memories.removeRange(
        maxMemories,
        memories.length,
      );
    }

    await _saveAll(memories);
  }


  // ═══════════════════════════════════════════════════════════
  // GET RELEVANT MEMORIES
  // ═══════════════════════════════════════════════════════════
  //
  // We don't send all 40 memories to Gemma.
  //
  // Instead:
  //
  //       40 memories
  //            ↓
  //     importance +
  //       confidence
  //            ↓
  //        best 12
  //            ↓
  //          Gemma
  //
  // ═══════════════════════════════════════════════════════════

  List<UserMemory> getRelevantMemories(
      List<UserMemory> memories, {
        int limit = 12,
      }) {
    final sorted = [...memories];

    sorted.sort(
          (a, b) {
        final scoreA =
            (a.importance * 0.7) +
                (a.confidence * 0.3);

        final scoreB =
            (b.importance * 0.7) +
                (b.confidence * 0.3);

        return scoreB.compareTo(scoreA);
      },
    );

    return sorted.take(limit).toList();
  }


  // ═══════════════════════════════════════════════════════════
  // REMOVE ONE MEMORY
  // ═══════════════════════════════════════════════════════════

  Future<void> removeMemory(
      String id,
      ) async {
    final memories = await load();

    memories.removeWhere(
          (memory) => memory.id == id,
    );

    await _saveAll(memories);
  }


  // ═══════════════════════════════════════════════════════════
  // REMOVE MEMORY BY KEY
  // ═══════════════════════════════════════════════════════════

  Future<void> removeMemoryByKey(
      String key,
      ) async {
    final memories = await load();

    final normalizedKey =
    key.trim().toLowerCase();

    memories.removeWhere(
          (memory) =>
      memory.key.trim().toLowerCase() ==
          normalizedKey,
    );

    await _saveAll(memories);
  }


  // ═══════════════════════════════════════════════════════════
  // CLEAR ALL MEMORIES
  // ═══════════════════════════════════════════════════════════

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }


  // ═══════════════════════════════════════════════════════════
  // MEMORY CONTEXT FOR GEMMA
  // ═══════════════════════════════════════════════════════════

  String toContextBlock(
      List<UserMemory> memories,
      ) {
    if (memories.isEmpty) {
      return '';
    }

    // Only use the highest-value memories.
    final relevant = getRelevantMemories(
      memories,
      limit: 12,
    );

    if (relevant.isEmpty) {
      return '';
    }

    final groups =
    <MemoryType, List<UserMemory>>{
      for (final type in MemoryType.values)
        type: [],
    };

    for (final memory in relevant) {
      groups[memory.type]!.add(memory);
    }

    final buffer = StringBuffer();

    buffer.writeln(
      'USER MEMORY',
    );

    buffer.writeln(
      'The following are durable facts/preferences/goals/projects '
          'about the user.',
    );

    buffer.writeln(
      'Use them only when relevant to the current conversation.',
    );

    buffer.writeln(
      'Do not mention the memory system or say that you remember them.',
    );

    // ─────────────────────────────────────────────────────────
    // PROFILE
    // ─────────────────────────────────────────────────────────

    _writeMemoryGroup(
      buffer,
      'PROFILE',
      groups[MemoryType.profile]!,
    );

    // ─────────────────────────────────────────────────────────
    // PREFERENCES
    // ─────────────────────────────────────────────────────────

    _writeMemoryGroup(
      buffer,
      'PREFERENCES',
      groups[MemoryType.preference]!,
    );

    // ─────────────────────────────────────────────────────────
    // GOALS
    // ─────────────────────────────────────────────────────────

    _writeMemoryGroup(
      buffer,
      'GOALS',
      groups[MemoryType.goal]!,
    );

    // ─────────────────────────────────────────────────────────
    // PROJECTS
    // ─────────────────────────────────────────────────────────

    _writeMemoryGroup(
      buffer,
      'PROJECTS',
      groups[MemoryType.project]!,
    );

    return buffer.toString();
  }


  // ═══════════════════════════════════════════════════════════
  // WRITE MEMORY GROUP
  // ═══════════════════════════════════════════════════════════

  void _writeMemoryGroup(
      StringBuffer buffer,
      String title,
      List<UserMemory> memories,
      ) {
    if (memories.isEmpty) {
      return;
    }

    buffer.writeln();
    buffer.writeln('$title:');

    for (final memory in memories) {
      buffer.writeln(
        '- ${memory.key}: ${memory.fact}',
      );
    }
  }


  // ═══════════════════════════════════════════════════════════
  // DEBUG / STATS
  // ═══════════════════════════════════════════════════════════

  Future<int> count() async {
    final memories = await load();

    return memories.length;
  }
}