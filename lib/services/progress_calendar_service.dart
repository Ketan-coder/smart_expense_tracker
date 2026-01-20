// services/progress_calendar_service.dart
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../core/app_constants.dart';
import '../data/model/daily_progress.dart';
import '../data/model/goal.dart';
import '../data/model/habit.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';

class ProgressCalendarService {
  static final ProgressCalendarService _instance =
  ProgressCalendarService._internal();
  factory ProgressCalendarService() => _instance;
  ProgressCalendarService._internal();

  /// Initialize daily progress tracking
  Future<void> initialize() async {
    await Hive.openBox<DailyProgress>('daily_progress');
    debugPrint("✅ DailyProgress box initialized");
  }

  /// Get or create today's progress
  Future<DailyProgress> getTodayProgress() async {
    final box = Hive.box<DailyProgress>('daily_progress');
    final today = _normalizeDate(DateTime.now());
    final key = today.toIso8601String();

    DailyProgress? progress = box.get(key);
    if (progress == null) {
      progress = await _calculateDailyProgress(today);
      await box.put(key, progress);
    }

    return progress;
  }

  /// Calculate progress for a specific date
  Future<DailyProgress> _calculateDailyProgress(DateTime date) async {
    final normalizedDate = _normalizeDate(date);

    // Check goals
    final goalBox = Hive.box<Goal>(AppConstants.goals);
    final goalsWithProgress = <String>[];
    bool hasGoalProgress = false;

    for (final goal in goalBox.values) {
      if (goal.lastInstallmentDate != null &&
          _isSameDay(goal.lastInstallmentDate!, normalizedDate)) {
        hasGoalProgress = true;
        goalsWithProgress.add(goal.name);
      }
    }

    // Check habits
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    final completedHabits = <String>[];
    bool hasHabitCompletion = false;

    for (final habit in habitBox.values) {
      final isCompletedOnDate = habit.completionHistory.any((completionDate) =>
          _isSameDay(_normalizeDate(completionDate), normalizedDate));

      if (isCompletedOnDate) {
        hasHabitCompletion = true;
        completedHabits.add(habit.name);
      }
    }

    // Check productive transactions (income from freelancing, etc.)
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    bool hasProductiveTransaction = false;
    double totalSavings = 0.0;

    final dayIncomes = incomeBox.values.where(
            (income) => _isSameDay(_normalizeDate(income.date), normalizedDate));

    for (final income in dayIncomes) {
      if (_isProductiveIncome(income.description)) {
        hasProductiveTransaction = true;
        totalSavings += income.amount;
      }
    }

    return DailyProgress(
      date: normalizedDate,
      hasGoalProgress: hasGoalProgress,
      hasHabitCompletion: hasHabitCompletion,
      hasProductiveTransaction: hasProductiveTransaction,
      completedGoalNames: goalsWithProgress,
      completedHabitNames: completedHabits,
      totalSavings: totalSavings,
    );
  }

  /// Get year progress (365/366 days)
  Future<List<DailyProgress>> getYearProgress(int year) async {
    final box = Hive.box<DailyProgress>('daily_progress');
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    final dayCount = endDate.difference(startDate).inDays + 1;

    List<DailyProgress> yearProgress = [];

    for (int i = 0; i < dayCount; i++) {
      final date = startDate.add(Duration(days: i));
      final key = date.toIso8601String();

      DailyProgress? progress = box.get(key);
      if (progress == null && date.isBefore(DateTime.now())) {
        progress = await _calculateDailyProgress(date);
        await box.put(key, progress);
      }

      yearProgress.add(progress ??
          DailyProgress(
            date: date,
            hasGoalProgress: false,
            hasHabitCompletion: false,
            hasProductiveTransaction: false,
          ));
    }

    return yearProgress;
  }

  /// Recalculate today's progress (call after new transaction/habit/goal)
  Future<void> refreshTodayProgress() async {
    final box = Hive.box<DailyProgress>('daily_progress');
    final today = _normalizeDate(DateTime.now());
    final key = today.toIso8601String();

    final progress = await _calculateDailyProgress(today);
    await box.put(key, progress);

    debugPrint("✅ Today's progress refreshed: ${progress.status}");
  }

  // Helper methods
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isProductiveIncome(String description) {
    final productiveKeywords = [
      'freelance',
      'freelancing',
      'project',
      'work',
      'client',
      'gig',
      'consulting',
      'revenue'
    ];
    final lower = description.toLowerCase();
    return productiveKeywords.any((keyword) => lower.contains(keyword));
  }
}