import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../data/model/habit.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import '../services/notification_service.dart';

/// OPTIMIZED: Intelligent habit detection with caching and rate limiting
class HabitDetectionService {
  static final HabitDetectionService _instance = HabitDetectionService._internal();
  factory HabitDetectionService() => _instance;
  HabitDetectionService._internal();

  // CRITICAL: Cache to prevent re-analysis
  static DateTime? _lastDetectionTime;
  static List<Map<String, dynamic>>? _cachedPatterns;
  static const int _cacheValidityHours = 24; // Cache for 24 hours

  // Detection thresholds (INCREASED to reduce false positives)
  static const int minOccurrences = 7; // Increased from 5
  static const int dayWindow = 30;
  static const double similarityThreshold = 0.7;

  /// Check if detection should run (rate limiting)
  static bool _shouldRunDetection() {
    if (_lastDetectionTime == null) return true;

    final hoursSinceLastRun = DateTime.now().difference(_lastDetectionTime!).inHours;
    return hoursSinceLastRun >= _cacheValidityHours;
  }

  /// OPTIMIZED: Analyze expenses and incomes with caching
  Future<List<Map<String, dynamic>>> detectPotentialHabits() async {
    debugPrint("🔍 Habit detection requested...");

    // CHECK CACHE FIRST (critical optimization)
    if (!_shouldRunDetection() && _cachedPatterns != null) {
      debugPrint("✅ Using cached patterns (${_cachedPatterns!.length} patterns)");
      return _cachedPatterns!;
    }

    debugPrint("🔍 Running fresh habit detection...");
    _lastDetectionTime = DateTime.now();

    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);

    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: dayWindow));

    // Get recent transactions (with limit to prevent huge datasets)
    final recentExpenses = expenseBox.values
        .where((e) => e.date.isAfter(cutoffDate))
        .take(100) // LIMIT: Only analyze last 100 expenses
        .toList();

    final recentIncomes = incomeBox.values
        .where((i) => i.date.isAfter(cutoffDate))
        .take(50) // LIMIT: Only analyze last 50 incomes
        .toList();

    debugPrint("📊 Analyzing ${recentExpenses.length} expenses and ${recentIncomes.length} incomes (limited)");

    List<Map<String, dynamic>> detectedPatterns = [];

    // Detect patterns with timeout protection
    try {
      // Use Future.timeout to prevent hanging
      detectedPatterns.addAll(
        await Future.value(_detectExpensePatterns(recentExpenses))
            .timeout(const Duration(seconds: 5)),
      );

      detectedPatterns.addAll(
        await Future.value(_detectIncomePatterns(recentIncomes))
            .timeout(const Duration(seconds: 3)),
      );
    } catch (e) {
      debugPrint("⚠️ Detection timeout or error: $e");
      _cachedPatterns = [];
      return [];
    }

    // Cache results
    _cachedPatterns = detectedPatterns;

    debugPrint("✅ Detected ${detectedPatterns.length} potential habits (cached)");
    return detectedPatterns;
  }

  /// OPTIMIZED: Detect patterns in expenses (simplified)
  List<Map<String, dynamic>> _detectExpensePatterns(List<Expense> expenses) {
    if (expenses.length < minOccurrences) return [];

    List<Map<String, dynamic>> patterns = [];

    // Group by description only (faster than complex keys)
    Map<String, List<Expense>> grouped = {};

    for (var expense in expenses) {
      final key = expense.description.toLowerCase().trim();
      if (key.isEmpty) continue; // Skip empty descriptions

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(expense);
    }

    // Analyze each group (with early exit optimization)
    int processed = 0;
    for (var entry in grouped.entries) {
      if (processed >= 10) break; // LIMIT: Max 10 patterns to prevent overload

      if (entry.value.length >= minOccurrences) {
        final pattern = _analyzePatternSimplified(
          entry.value.map((e) => {
            'date': e.date,
            'amount': e.amount,
            'description': e.description,
            'categoryKeys': e.categoryKeys,
          }).toList(),
          'expense',
        );

        if (pattern != null) {
          patterns.add(pattern);
          processed++;
        }
      }
    }

    return patterns;
  }

  /// OPTIMIZED: Detect patterns in incomes (simplified)
  List<Map<String, dynamic>> _detectIncomePatterns(List<Income> incomes) {
    if (incomes.length < minOccurrences) return [];

    List<Map<String, dynamic>> patterns = [];
    Map<String, List<Income>> grouped = {};

    for (var income in incomes) {
      final key = income.description.toLowerCase().trim();
      if (key.isEmpty) continue;

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(income);
    }

    int processed = 0;
    for (var entry in grouped.entries) {
      if (processed >= 5) break; // LIMIT: Max 5 income patterns

      if (entry.value.length >= minOccurrences) {
        final pattern = _analyzePatternSimplified(
          entry.value.map((i) => {
            'date': i.date,
            'amount': i.amount,
            'description': i.description,
            'categoryKeys': i.categoryKeys,
          }).toList(),
          'income',
        );

        if (pattern != null) {
          patterns.add(pattern);
          processed++;
        }
      }
    }

    return patterns;
  }

  /// SIMPLIFIED: Faster pattern analysis (removed complex math)
  Map<String, dynamic>? _analyzePatternSimplified(
      List<Map<String, dynamic>> transactions,
      String type,
      ) {
    if (transactions.length < minOccurrences) return null;

    // Sort by date
    transactions.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Calculate SIMPLE average interval (no std dev)
    List<int> intervals = [];
    for (int i = 1; i < transactions.length && i < 10; i++) { // LIMIT: Only check first 10
      final diff = (transactions[i]['date'] as DateTime)
          .difference(transactions[i - 1]['date'] as DateTime)
          .inDays;
      intervals.add(diff);
    }

    if (intervals.isEmpty) return null;

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // SIMPLIFIED: Determine frequency (no complex variance checks)
    String frequency;
    int confidence;

    if (avgInterval <= 2) {
      frequency = 'daily';
      confidence = 80;
    } else if (avgInterval <= 9) {
      frequency = 'weekly';
      confidence = 75;
    } else if (avgInterval <= 35) {
      frequency = 'monthly';
      confidence = 70;
    } else {
      return null; // Too irregular
    }

    // Calculate average amount (simple)
    final avgAmount = transactions
        .take(10) // LIMIT: Only use first 10 for average
        .map((t) => t['amount'] as double)
        .reduce((a, b) => a + b) / transactions.take(10).length;

    return {
      'name': transactions.first['description'] as String,
      'description': 'Auto-detected from your $type patterns',
      'frequency': frequency,
      'type': type,
      'categoryKeys': transactions.first['categoryKeys'] as List<int>,
      'targetAmount': avgAmount,
      'targetTime': null, // Simplified: No time extraction
      'confidence': confidence,
      'occurrences': transactions.length,
      'avgInterval': avgInterval.round(),
      'isAutoDetected': true,
    };
  }

  /// OPTIMIZED: Send notification (with rate limiting)
  Future<void> notifyUserAboutHabit(Map<String, dynamic> pattern) async {
    // Check if we already notified about this habit
    final prefs = await SharedPreferences.getInstance();
    final notifiedHabits = prefs.getStringList('notified_habits') ?? [];
    final habitKey = '${pattern['name']}_${pattern['type']}';

    if (notifiedHabits.contains(habitKey)) {
      debugPrint("⏭️ Already notified about: ${pattern['name']}");
      return;
    }

    // Send notification
    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    await NotificationService.showNotification(
      id: id,
      title: '🎯 New Habit Detected!',
      body: 'We noticed you ${pattern['name']} ${pattern['frequency']}. Track it as a habit?',
      channelId: 'habit_detection',
      channelName: 'Habit Detection',
    );

    // Mark as notified
    notifiedHabits.add(habitKey);
    await prefs.setStringList('notified_habits', notifiedHabits);

    debugPrint("📬 Notification sent for habit: ${pattern['name']}");
  }

  /// Check if habit already exists
  Future<bool> habitExists(String name, List<int> categoryKeys) async {
    final habitBox = Hive.box<Habit>(AppConstants.habits);

    return habitBox.values.any((habit) {
      return habit.name.toLowerCase().trim() == name.toLowerCase().trim();
    });
  }

  /// OPTIMIZED: Run detection with strict rate limiting
  Future<void> runAutoDetection() async {
    debugPrint("🤖 Auto-detection requested...");

    // CRITICAL: Check if we ran recently
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getString('last_habit_detection');

    if (lastRun != null) {
      final lastRunTime = DateTime.parse(lastRun);
      final hoursSince = DateTime.now().difference(lastRunTime).inHours;

      if (hoursSince < 24) {
        debugPrint("⏭️ Skipping: Last run was $hoursSince hours ago (need 24h)");
        return;
      }
    }

    debugPrint("🤖 Running automatic habit detection (first time in 24h)...");

    try {
      final patterns = await detectPotentialHabits();

      int notified = 0;
      for (var pattern in patterns) {
        if (notified >= 3) break; // LIMIT: Max 3 notifications per day

        final exists = await habitExists(
          pattern['name'],
          pattern['categoryKeys'],
        );

        if (!exists && pattern['confidence'] >= 75) {
          await notifyUserAboutHabit(pattern);
          notified++;
        }
      }

      // Update last run time
      await prefs.setString('last_habit_detection', DateTime.now().toIso8601String());

      debugPrint("✅ Auto-detection complete: $notified notifications sent");
    } catch (e) {
      debugPrint("❌ Auto-detection error: $e");
    }
  }

  /// Clear cache (call when new transactions added)
  static void clearCache() {
    _cachedPatterns = null;
    _lastDetectionTime = null;
    debugPrint("🗑️ Habit detection cache cleared");
  }
}