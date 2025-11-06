import 'package:hive_ce/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 3)
class Habit {
  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  @HiveField(2)
  String frequency; // daily, weekly, monthly, custom

  @HiveField(3)
  List<int> categoryKeys; // Links to Category box keys

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? lastCompletedAt;

  @HiveField(6)
  List<DateTime> completionHistory; // Track all completions

  @HiveField(7)
  double? targetAmount; // Optional: target amount (e.g., spend ₹200 on groceries)

  @HiveField(8)
  String? targetTime; // Optional: preferred time (e.g., "20:00" for 8 PM)

  @HiveField(9)
  bool isActive; // Can pause habits

  @HiveField(10)
  String type; // 'expense', 'income', 'custom'

  @HiveField(11)
  int streakCount; // Current streak

  @HiveField(12)
  int bestStreak; // Longest streak achieved

  @HiveField(13)
  String icon; // Icon name for display

  @HiveField(14)
  String color; // Hex color for the habit card

  @HiveField(15)
  bool isAutoDetected; // True if system detected this habit

  @HiveField(16)
  int detectionConfidence; // 0-100, how confident the system is

  @HiveField(17)
  String? notes; // Additional notes (optional)

  Habit({
    required this.name,
    required this.description,
    required this.frequency,
    required this.categoryKeys,
    required this.createdAt,
    this.lastCompletedAt,
    List<DateTime>? completionHistory,
    this.targetAmount,
    this.targetTime,
    this.isActive = true,
    this.type = 'custom',
    this.streakCount = 0,
    this.bestStreak = 0,
    this.icon = 'track_changes',
    this.color = '#FF6B6B',
    this.isAutoDetected = false,
    this.detectionConfidence = 0,
    this.notes,
  }) : completionHistory = completionHistory ?? [];

  /// Mark habit as completed for today
  void markCompleted() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Don't add duplicate for same day
    if (!isCompletedToday()) {
      completionHistory.add(today);
      lastCompletedAt = now;
      _updateStreak();
    }
  }

  /// Check if completed today
  bool isCompletedToday() {
    if (completionHistory.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return completionHistory.any((date) {
      final completionDate = DateTime(date.year, date.month, date.day);
      return completionDate.isAtSameMomentAs(today);
    });
  }

  /// Update streak based on completion history
  void _updateStreak() {
    if (completionHistory.isEmpty) {
      streakCount = 0;
      return;
    }

    // Sort dates
    completionHistory.sort();

    int currentStreak = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if last completion was yesterday or today
    final lastCompletion = completionHistory.last;
    final daysDiff = today.difference(lastCompletion).inDays;

    if (daysDiff > 1) {
      // Streak broken
      streakCount = 0;
      return;
    }

    // Count consecutive days backwards
    for (int i = completionHistory.length - 2; i >= 0; i--) {
      final current = completionHistory[i + 1];
      final previous = completionHistory[i];
      final diff = current.difference(previous).inDays;

      if (diff == 1) {
        currentStreak++;
      } else {
        break;
      }
    }

    streakCount = currentStreak;

    // Update best streak
    if (streakCount > bestStreak) {
      bestStreak = streakCount;
    }
  }

  /// Get completion rate for last N days
  double getCompletionRate(int days) {
    if (days <= 0) return 0.0;

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: days));

    final recentCompletions = completionHistory.where((date) {
      return date.isAfter(cutoffDate);
    }).length;

    return (recentCompletions / days).clamp(0.0, 1.0);
  }

  /// Get next expected completion date based on frequency
  DateTime? getNextExpectedDate() {
    if (lastCompletedAt == null) return null;

    switch (frequency.toLowerCase()) {
      case 'daily':
        return lastCompletedAt!.add(const Duration(days: 1));
      case 'weekly':
        return lastCompletedAt!.add(const Duration(days: 7));
      case 'monthly':
        final next = DateTime(
          lastCompletedAt!.year,
          lastCompletedAt!.month + 1,
          lastCompletedAt!.day,
        );
        return next;
      default:
        return null;
    }
  }

  /// Check if habit is overdue
  bool isOverdue() {
    if (!isActive) return false;

    final nextDate = getNextExpectedDate();
    if (nextDate == null) return false;

    return DateTime.now().isAfter(nextDate) && !isCompletedToday();
  }

  @override
  String toString() {
    return "Habit(name: $name, freq: $frequency, streak: $streakCount, "
        "categories: $categoryKeys, active: $isActive)";
  }
}