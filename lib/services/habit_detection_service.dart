import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../core/app_constants.dart';
import '../data/model/habit.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import '../services/notification_service.dart';

/// Intelligent habit detection from expense and income patterns
class HabitDetectionService {
  static final HabitDetectionService _instance = HabitDetectionService._internal();
  factory HabitDetectionService() => _instance;
  HabitDetectionService._internal();

  // Detection thresholds
  static const int minOccurrences = 5; // Minimum times to consider as habit
  static const int dayWindow = 30; // Look back 30 days
  static const double similarityThreshold = 0.7; // 70% similarity for pattern matching

  /// Analyze expenses and incomes to detect potential habits
  Future<List<Map<String, dynamic>>> detectPotentialHabits() async {
    debugPrint("🔍 Starting habit detection...");

    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: dayWindow));

    // Get recent transactions
    final recentExpenses = expenseBox.values.where((e) {
      return e.date.isAfter(cutoffDate);
    }).toList();

    final recentIncomes = incomeBox.values.where((i) {
      return i.date.isAfter(cutoffDate);
    }).toList();

    debugPrint("📊 Analyzing ${recentExpenses.length} expenses and ${recentIncomes.length} incomes");

    List<Map<String, dynamic>> detectedPatterns = [];

    // Detect expense patterns
    detectedPatterns.addAll(_detectExpensePatterns(recentExpenses));

    // Detect income patterns
    detectedPatterns.addAll(_detectIncomePatterns(recentIncomes));

    debugPrint("✅ Detected ${detectedPatterns.length} potential habits");

    return detectedPatterns;
  }

  /// Detect patterns in expenses
  List<Map<String, dynamic>> _detectExpensePatterns(List<Expense> expenses) {
    List<Map<String, dynamic>> patterns = [];

    // Group by description similarity and category
    Map<String, List<Expense>> grouped = {};

    for (var expense in expenses) {
      final key = "${expense.description.toLowerCase()}_${expense.categoryKeys.join('-')}";
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(expense);
    }

    // Analyze each group
    for (var entry in grouped.entries) {
      if (entry.value.length >= minOccurrences) {
        final pattern = _analyzePattern(
          entry.value.map((e) => {
            'date': e.date,
            'amount': e.amount,
            'description': e.description,
            'categoryKeys': e.categoryKeys,
            'method': e.method,
          }).toList(),
          'expense',
        );

        if (pattern != null) {
          patterns.add(pattern);
        }
      }
    }

    return patterns;
  }

  /// Detect patterns in incomes
  List<Map<String, dynamic>> _detectIncomePatterns(List<Income> incomes) {
    List<Map<String, dynamic>> patterns = [];

    // Group by description and category
    Map<String, List<Income>> grouped = {};

    for (var income in incomes) {
      final key = "${income.description.toLowerCase()}_${income.categoryKeys.join('-')}";
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(income);
    }

    // Analyze each group
    for (var entry in grouped.entries) {
      if (entry.value.length >= minOccurrences) {
        final pattern = _analyzePattern(
          entry.value.map((i) => {
            'date': i.date,
            'amount': i.amount,
            'description': i.description,
            'categoryKeys': i.categoryKeys,
            'method': i.method,
          }).toList(),
          'income',
        );

        if (pattern != null) {
          patterns.add(pattern);
        }
      }
    }

    return patterns;
  }

  /// Analyze a group of transactions to determine if it's a habit
  Map<String, dynamic>? _analyzePattern(List<Map<String, dynamic>> transactions, String type) {
    if (transactions.length < minOccurrences) return null;

    // Sort by date
    transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Calculate average interval between transactions
    List<int> intervals = [];
    for (int i = 1; i < transactions.length; i++) {
      final diff = (transactions[i]['date'] as DateTime)
          .difference(transactions[i - 1]['date'] as DateTime)
          .inDays;
      intervals.add(diff);
    }

    if (intervals.isEmpty) return null;

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final stdDev = _calculateStdDev(intervals, avgInterval);

    // Determine frequency based on average interval
    String frequency;
    int confidence;

    if (avgInterval <= 1.5 && stdDev < 2) {
      frequency = 'daily';
      confidence = 95;
    } else if (avgInterval > 1.5 && avgInterval <= 2.5 && stdDev < 3) {
      frequency = 'daily';
      confidence = 75;
    } else if (avgInterval > 5 && avgInterval <= 9 && stdDev < 4) {
      frequency = 'weekly';
      confidence = 85;
    } else if (avgInterval > 25 && avgInterval <= 35 && stdDev < 7) {
      frequency = 'monthly';
      confidence = 80;
    } else {
      // Pattern too irregular
      return null;
    }

    // Calculate average amount
    final avgAmount = transactions.map((t) => t['amount'] as double).reduce((a, b) => a + b) / transactions.length;

    // Extract common time if available
    String? preferredTime = _extractPreferredTime(transactions);

    return {
      'name': transactions.first['description'] as String,
      'description': 'Auto-detected from your $type patterns',
      'frequency': frequency,
      'type': type,
      'categoryKeys': transactions.first['categoryKeys'] as List<int>,
      'targetAmount': avgAmount,
      'targetTime': preferredTime,
      'confidence': confidence,
      'occurrences': transactions.length,
      'avgInterval': avgInterval.round(),
      'isAutoDetected': true,
    };
  }

  /// Extract preferred time from transactions (if timestamps are available)
  String? _extractPreferredTime(List<Map<String, dynamic>> transactions) {
    // If your DateTime includes time, extract hour
    final times = transactions.map((t) {
      final date = t['date'] as DateTime;
      return date.hour;
    }).toList();

    if (times.isEmpty) return null;

    // Find most common hour
    Map<int, int> hourCount = {};
    for (var hour in times) {
      hourCount[hour] = (hourCount[hour] ?? 0) + 1;
    }

    final mostCommonHour = hourCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // If more than 50% of transactions happen at similar hour, consider it
    if ((hourCount[mostCommonHour]! / times.length) > 0.5) {
      return '${mostCommonHour.toString().padLeft(2, '0')}:00';
    }

    return null;
  }

  /// Calculate standard deviation
  double _calculateStdDev(List<int> values, double mean) {
    if (values.isEmpty) return 0;

    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    return variance.isNaN ? 0 : variance.squareRoot();
  }

  /// Send notification to user about detected habit
  Future<void> notifyUserAboutHabit(Map<String, dynamic> pattern) async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    await NotificationService.showNotification(
      id: id,
      title: '🎯 New Habit Detected!',
      body: 'We noticed you ${pattern['name']} ${pattern['frequency']}. Track it as a habit?',
      channelId: 'habit_detection',
      channelName: 'Habit Detection',
    );

    debugPrint("📬 Notification sent for habit: ${pattern['name']}");
  }

  /// Check if habit already exists
  Future<bool> habitExists(String name, List<int> categoryKeys) async {
    final habitBox = Hive.box<Habit>(AppConstants.habits);

    return habitBox.values.any((habit) {
      final nameSimilar = habit.name.toLowerCase().trim() == name.toLowerCase().trim();
      final categoriesSame = _listsEqual(habit.categoryKeys, categoryKeys);
      return nameSimilar && categoriesSame;
    });
  }

  /// Compare two lists
  bool _listsEqual(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Run detection and notify user (call this periodically, e.g., daily)
  Future<void> runAutoDetection() async {
    debugPrint("🤖 Running automatic habit detection...");

    final patterns = await detectPotentialHabits();

    for (var pattern in patterns) {
      // Check if habit already exists
      final exists = await habitExists(
        pattern['name'],
        pattern['categoryKeys'],
      );

      if (!exists && pattern['confidence'] >= 75) {
        // Notify user about high-confidence pattern
        await notifyUserAboutHabit(pattern);
      }
    }
  }
}

extension on double {
  double squareRoot() {
    return this < 0 ? 0 : this.sign * (this.abs().sign * this.abs());
  }
}