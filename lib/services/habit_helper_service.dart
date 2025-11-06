import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../core/app_constants.dart';
import '../data/model/habit.dart';

/// Helper functions for habit management across the app
class HabitHelpers {
  /// Get all active habits
  static List<Habit> getActiveHabits() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.where((h) => h.isActive).toList();
  }

  /// Get habits due today
  static List<Habit> getHabitsDueToday() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.where((h) {
      return h.isActive && !h.isCompletedToday();
    }).toList();
  }

  /// Get completed habits today
  static List<Habit> getCompletedHabitsToday() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.where((h) {
      return h.isActive && h.isCompletedToday();
    }).toList();
  }

  /// Get overdue habits
  static List<Habit> getOverdueHabits() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.where((h) => h.isOverdue()).toList();
  }

  /// Get habits with active streaks
  static List<Habit> getHabitsWithStreaks() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.where((h) => h.streakCount > 0).toList()
      ..sort((a, b) => b.streakCount.compareTo(a.streakCount));
  }

  /// Get total habits count
  static int getTotalHabitsCount() {
    return Hive.box<Habit>(AppConstants.habits).length;
  }

  /// Get today's completion rate
  static double getTodayCompletionRate() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0.0;

    final completed = habits.where((h) => h.isCompletedToday()).length;
    return completed / habits.length;
  }

  /// Get overall completion rate (last 30 days)
  static double getOverallCompletionRate() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0.0;

    final totalRate = habits.fold<double>(
      0.0,
          (sum, h) => sum + h.getCompletionRate(30),
    );

    return totalRate / habits.length;
  }

  /// Get longest current streak
  static int getLongestStreak() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0;

    return habits.map((h) => h.streakCount).reduce((a, b) => a > b ? a : b);
  }

  /// Get habit by name
  static Habit? getHabitByName(String name) {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    try {
      return habitBox.values.firstWhere(
            (h) => h.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if any habits are due for notification
  static List<Habit> getHabitsNeedingReminder() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    final now = DateTime.now();

    return habitBox.values.where((habit) {
      if (!habit.isActive || habit.isCompletedToday()) return false;

      // If habit has a target time, check if it's within 30 minutes
      if (habit.targetTime != null) {
        final timeParts = habit.targetTime!.split(':');
        final targetHour = int.parse(timeParts[0]);
        final targetMinute = int.parse(timeParts[1]);

        final timeDiff = (now.hour * 60 + now.minute) - (targetHour * 60 + targetMinute);
        return timeDiff >= 0 && timeDiff <= 30;
      }

      return false;
    }).toList();
  }

  /// Get habits by category
  static List<Habit> getHabitsByCategory(int categoryKey) {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.where((h) {
      return h.categoryKeys.contains(categoryKey);
    }).toList();
  }

  /// Get habits by type
  static List<Habit> getHabitsByType(String type) {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.where((h) => h.type == type).toList();
  }

  /// Calculate total days tracked across all habits
  static int getTotalDaysTracked() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    return habitBox.values.fold<int>(
      0,
          (sum, h) => sum + h.completionHistory.length,
    );
  }

  /// Get habit statistics summary
  static Map<String, dynamic> getHabitStats() {
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    final habits = habitBox.values.toList();

    if (habits.isEmpty) {
      return {
        'totalHabits': 0,
        'activeHabits': 0,
        'completedToday': 0,
        'longestStreak': 0,
        'totalDaysTracked': 0,
        'completionRate': 0.0,
        'overdueHabits': 0,
      };
    }

    return {
      'totalHabits': habits.length,
      'activeHabits': habits.where((h) => h.isActive).length,
      'completedToday': habits.where((h) => h.isCompletedToday()).length,
      'longestStreak': getLongestStreak(),
      'totalDaysTracked': getTotalDaysTracked(),
      'completionRate': getOverallCompletionRate(),
      'overdueHabits': habits.where((h) => h.isOverdue()).length,
    };
  }

  /// Format streak text
  static String formatStreak(int streak) {
    if (streak == 0) return 'No streak';
    if (streak == 1) return '1 day';
    if (streak < 7) return '$streak days';
    if (streak < 30) return '${(streak / 7).floor()} weeks';
    if (streak < 365) return '${(streak / 30).floor()} months';
    return '${(streak / 365).floor()} years';
  }

  /// Get motivational message based on streak
  static String getStreakMessage(int streak) {
    if (streak == 0) return 'Start your streak today! 🌱';
    if (streak < 3) return 'Good start! Keep going! 💪';
    if (streak < 7) return 'Great momentum! 🚀';
    if (streak < 14) return 'You\'re on fire! 🔥';
    if (streak < 30) return 'Incredible dedication! ⭐';
    if (streak < 100) return 'You\'re a champion! 🏆';
    return 'Legendary! You\'re unstoppable! 👑';
  }

  /// Get habit icon emoji
  static String getHabitEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'expense':
        return '💸';
      case 'income':
        return '💰';
      case 'fitness':
        return '💪';
      case 'food':
        return '🍽️';
      case 'study':
        return '📚';
      case 'work':
        return '💼';
      default:
        return '🎯';
    }
  }

  /// Check if habit should trigger notification
  static bool shouldNotifyHabit(Habit habit) {
    if (!habit.isActive || habit.isCompletedToday()) return false;

    // Check if habit is overdue
    if (habit.isOverdue()) return true;

    // Check if it's time for reminder
    if (habit.targetTime != null) {
      final now = DateTime.now();
      final timeParts = habit.targetTime!.split(':');
      final targetHour = int.parse(timeParts[0]);
      final targetMinute = int.parse(timeParts[1]);

      return now.hour == targetHour && now.minute == targetMinute;
    }

    return false;
  }

  /// Get next milestone
  static String getNextMilestone(int currentStreak) {
    if (currentStreak < 7) return '7 days - One Week!';
    if (currentStreak < 14) return '14 days - Two Weeks!';
    if (currentStreak < 30) return '30 days - One Month!';
    if (currentStreak < 100) return '100 days - Century!';
    if (currentStreak < 365) return '365 days - One Year!';
    return '${((currentStreak / 365).ceil()) * 365} days - ${(currentStreak / 365).ceil()} Year${(currentStreak / 365).ceil() > 1 ? 's' : ''}!';
  }

  /// Calculate days until next milestone
  static int daysToNextMilestone(int currentStreak) {
    if (currentStreak < 7) return 7 - currentStreak;
    if (currentStreak < 14) return 14 - currentStreak;
    if (currentStreak < 30) return 30 - currentStreak;
    if (currentStreak < 100) return 100 - currentStreak;
    if (currentStreak < 365) return 365 - currentStreak;
    return ((currentStreak / 365).ceil() * 365) - currentStreak;
  }
}

/// Extension methods for Habit
extension HabitExtensions on Habit {
  /// Get color as Color object
  Color get colorObject => Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);

  /// Get icon as IconData
  IconData get iconData {
    switch (icon) {
      case 'restaurant': return Icons.restaurant;
      case 'fitness_center': return Icons.fitness_center;
      case 'local_cafe': return Icons.local_cafe;
      case 'book': return Icons.book;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'sports': return Icons.sports;
      case 'music_note': return Icons.music_note;
      case 'brush': return Icons.brush;
      case 'directions_run': return Icons.directions_run;
      default: return Icons.track_changes;
    }
  }

  /// Get frequency display text
  String get frequencyDisplay {
    switch (frequency.toLowerCase()) {
      case 'daily': return 'Every Day';
      case 'weekly': return 'Every Week';
      case 'monthly': return 'Every Month';
      default: return frequency;
    }
  }

  /// Get type display text
  String get typeDisplay {
    switch (type.toLowerCase()) {
      case 'expense': return '💸 Expense';
      case 'income': return '💰 Income';
      case 'custom': return '🎯 Custom';
      default: return type;
    }
  }

  /// Is habit high performing? (>80% completion rate)
  bool get isHighPerforming => getCompletionRate(30) >= 0.8;

  /// Is habit at risk? (<50% completion rate in last week)
  bool get isAtRisk => getCompletionRate(7) < 0.5;

  /// Get habit age in days
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Get total completions
  int get totalCompletions => completionHistory.length;

  /// Get average completions per week
  double get avgCompletionsPerWeek {
    if (ageInDays < 7) return totalCompletions.toDouble();
    return (totalCompletions / ageInDays) * 7;
  }
}

/// Example usage in your widgets:
///
/// ```dart
/// // Get today's completion rate
/// final rate = HabitHelpers.getTodayCompletionRate();
/// Text('Today: ${(rate * 100).toInt()}% complete');
///
/// // Show overdue habits
/// final overdue = HabitHelpers.getOverdueHabits();
/// if (overdue.isNotEmpty) {
///   SnackBar(content: Text('${overdue.length} habits overdue!'));
/// }
///
/// // Get habit stats for dashboard
/// final stats = HabitHelpers.getHabitStats();
/// Text('${stats['completedToday']}/${stats['activeHabits']} habits done');
///
/// // Use extensions
/// final habit = getHabit();
/// Container(color: habit.colorObject);
/// Icon(habit.iconData);
/// Text(habit.frequencyDisplay);
/// ```