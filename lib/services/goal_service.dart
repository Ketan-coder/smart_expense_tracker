// services/goal_service.dart
import 'dart:async';
import 'package:expense_tracker/services/progress_calendar_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../data/model/category.dart';
import '../data/model/goal.dart';
import 'notification_service.dart';
import '../data/local/universal_functions.dart';

class GoalService {
  static final GoalService _instance = GoalService._internal();
  factory GoalService() => _instance;
  GoalService._internal();

  static const String _goalChannel = 'goal_alerts';

  // Battery optimization: Throttle notifications
  static const Duration _notificationCooldown = Duration(hours: 4);
  final Map<String, DateTime> _lastNotificationTime = {};

  // Cache for frequently accessed data
  List<int>? _cachedGoalCategoryKeys;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Add a new goal
  Future<bool> addGoal(Goal goal) async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      await goalBox.add(goal);

      debugPrint("🎯 [GoalService] Goal added: ${goal.name}");

      // Schedule ONLY essential notifications (not frequent ones)
      await _scheduleEssentialGoalNotifications(goal);

      return true;
    } catch (e, st) {
      debugPrint("❌ [GoalService] Error adding goal: $e\n$st");
      return false;
    }
  }

  /// Add installment to goal and automatically create income transaction
  Future<bool> addGoalInstallment(int goalKey, double amount, {String? description}) async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      final goal = goalBox.get(goalKey);

      if (goal == null) {
        debugPrint("❌ [GoalService] Goal not found for key: $goalKey");
        return false;
      }

      if (goal.isCompleted) {
        debugPrint("⚠️ [GoalService] Goal already completed: ${goal.name}");
        return false;
      }

      // Add installment to goal
      goal.addInstallment(amount);
      await goalBox.put(goalKey, goal);

      debugPrint("💰 [GoalService] Installment added to goal: ${goal.name} - $amount");

      // Automatically create income transaction for the installment
      final success = await UniversalHiveFunctions().addIncome(
        amount: amount,
        description: description ?? "Goal Installment: ${goal.name}",
        method: goal.walletType,
        categoryKeys: await _getGoalCategoryKeys(),
        date: DateTime.now(),
      );

      if (success) {
        debugPrint("✅ [GoalService] Income transaction created for goal installment");

        // Check progress with throttling
        await _checkGoalProgressThrottled(goal);
        await ProgressCalendarService().refreshTodayProgress();

        return true;
      } else {
        debugPrint("❌ [GoalService] Failed to create income transaction");
        // Rollback goal installment
        goal.currentAmount -= amount;
        await goalBox.put(goalKey, goal);
        return false;
      }
    } catch (e, st) {
      debugPrint("❌ [GoalService] Error adding installment: $e\n$st");
      return false;
    }
  }

  /// Add income and automatically allocate to matching goals
  Future<bool> addIncomeAndAllocateToGoals({
    required double amount,
    required String description,
    required String method,
    required List<int> categoryKeys,
    DateTime? date,
    List<int>? goalKeys,
  }) async {
    try {
      // First create the income transaction
      final incomeSuccess = await UniversalHiveFunctions().addIncome(
        amount: amount,
        description: description,
        method: method,
        categoryKeys: categoryKeys,
        date: date,
      );

      if (!incomeSuccess) {
        return false;
      }

      // If specific goals are provided, allocate to them
      if (goalKeys != null && goalKeys.isNotEmpty) {
        double remainingAmount = amount;

        for (final goalKey in goalKeys) {
          if (remainingAmount <= 0) break;

          final goal = Hive.box<Goal>(AppConstants.goals).get(goalKey);
          if (goal != null && !goal.isCompleted) {
            final allocationAmount = remainingAmount.clamp(0, goal.remainingAmount);
            if (allocationAmount > 0) {
              // Don't create duplicate income - just update goal
              goal.addInstallment(allocationAmount as double);
              await Hive.box<Goal>(AppConstants.goals).put(goalKey, goal);
              remainingAmount -= allocationAmount;
            }
          }
        }
      }

      debugPrint("✅ [GoalService] Income allocated to goals successfully");
      return true;
    } catch (e, st) {
      debugPrint("❌ [GoalService] Error allocating income to goals: $e\n$st");
      return false;
    }
  }

  /// Get goals that need attention (low progress, nearing deadline)
  Future<List<Goal>> getGoalsNeedingAttention() async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      final allGoals = goalBox.values.where((goal) => !goal.isCompleted).toList();

      return allGoals.where((goal) {
        final progress = goal.progressPercentage;
        final daysLeft = goal.daysRemaining;

        // Goals with less than 50% progress and less than 30 days left
        return progress < 50 && daysLeft < 30;
      }).toList();
    } catch (e) {
      debugPrint("❌ [GoalService] Error getting goals needing attention: $e");
      return [];
    }
  }

  /// Check goal progress with throttling (battery optimization)
  Future<void> _checkGoalProgressThrottled(Goal goal) async {
    final notificationKey = 'goal_${goal.name}_progress';

    // Check if we've sent a notification recently
    if (_lastNotificationTime.containsKey(notificationKey)) {
      final timeSinceLastNotification = DateTime.now().difference(_lastNotificationTime[notificationKey]!);
      if (timeSinceLastNotification < _notificationCooldown) {
        debugPrint("⏱️ [GoalService] Notification throttled for ${goal.name}");
        return;
      }
    }

    await _checkGoalProgress(goal);
    _lastNotificationTime[notificationKey] = DateTime.now();
  }

  /// Check goal progress and send ONLY important notifications
  Future<void> _checkGoalProgress(Goal goal) async {
    final progress = goal.progressPercentage;
    final remaining = goal.remainingAmount;
    final daysLeft = goal.daysRemaining;

    // ONLY send critical notifications to save battery
    if (progress >= 100 && !goal.isCompleted) {
      await _sendGoalCompletionNotification(goal);
    } else if (progress >= 75 && !await _hasSeenMilestone(goal, 75)) {
      await _sendGoalProgressNotification(
        goal,
        "Almost There! 🎯",
        "Only ₹${remaining.toStringAsFixed(0)} left for ${goal.name}",
      );
      await _markMilestoneSeen(goal, 75);
    } else if (daysLeft <= 3 && progress < 90) {
      // Critical deadline warning
      await _sendGoalProgressNotification(
        goal,
        "Urgent: Goal Deadline ⏰",
        "Only $daysLeft days left for ${goal.name}. ₹${remaining.toStringAsFixed(0)} remaining.",
      );
    } else if (daysLeft <= 0 && !goal.isCompleted) {
      await _sendGoalProgressNotification(
        goal,
        "Goal Deadline Passed ❌",
        "${goal.name} deadline passed. Consider extending or adjusting your goal.",
      );
    }
  }

  /// Schedule ONLY essential notifications (not frequent ones)
  Future<void> _scheduleEssentialGoalNotifications(Goal goal) async {
    // Only schedule deadline reminder (not weekly/monthly)
    if (goal.daysRemaining > 7) {
      final reminderDate = goal.targetDate.subtract(const Duration(days: 7));
      if (reminderDate.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: _generateGoalNotificationId(goal, 'deadline_reminder'),
          title: "Goal Deadline Approaching 📅",
          body: "1 week left for '${goal.name}'. Current progress: ${goal.progressPercentage.toInt()}%",
          scheduledDate: reminderDate,
        );
      }
    }
  }

  /// Check if milestone notification was already sent
  Future<bool> _hasSeenMilestone(Goal goal, int milestone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'goal_${goal.name}_milestone_$milestone';
      return prefs.getBool(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark milestone as seen
  Future<void> _markMilestoneSeen(Goal goal, int milestone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'goal_${goal.name}_milestone_$milestone';
      await prefs.setBool(key, true);
    } catch (e) {
      debugPrint("❌ Error marking milestone: $e");
    }
  }

  /// Send goal progress notification
  Future<void> _sendGoalProgressNotification(Goal goal, String title, String body) async {
    await NotificationService.showNotification(
      id: _generateGoalNotificationId(goal, 'progress'),
      title: title,
      body: body,
      channelId: _goalChannel,
      channelName: 'Goal Alerts',
      payload: 'open_goal_page',
    );
  }

  /// Send goal completion notification
  Future<void> _sendGoalCompletionNotification(Goal goal) async {
    await NotificationService.showNotification(
      id: _generateGoalNotificationId(goal, 'completion'),
      title: "Goal Achieved! 🎉",
      body: "Congratulations! You've successfully achieved your goal: ${goal.name}",
      channelId: _goalChannel,
      channelName: 'Goal Alerts',
      payload: 'open_goal_page',
    );
  }

  /// Get category keys for goal-related transactions (with caching)
  Future<List<int>> _getGoalCategoryKeys() async {
    // Return cached value if still valid
    if (_cachedGoalCategoryKeys != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
      return _cachedGoalCategoryKeys!;
    }

    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final goalCategory = categoryBox.values.firstWhere(
            (cat) => cat.name.toLowerCase() == 'savings',
        orElse: () => categoryBox.values.firstWhere(
              (cat) => cat.type.toLowerCase() == 'income',
        ),
      );
      final categoryKey = categoryBox.keyAt(categoryBox.values.toList().indexOf(goalCategory)) as int;

      // Cache the result
      _cachedGoalCategoryKeys = [categoryKey];
      _cacheTime = DateTime.now();

      return _cachedGoalCategoryKeys!;
    } catch (e) {
      debugPrint("⚠️ [GoalService] Error getting goal category, using fallback");
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final incomeCategories = categoryBox.values.where((cat) => cat.type.toLowerCase() == 'income').toList();
      if (incomeCategories.isNotEmpty) {
        final key = [categoryBox.keyAt(categoryBox.values.toList().indexOf(incomeCategories.first)) as int];
        _cachedGoalCategoryKeys = key;
        _cacheTime = DateTime.now();
        return key;
      }
      return [1];
    }
  }

  /// Generate unique notification ID for goals
  int _generateGoalNotificationId(Goal goal, String type) {
    return ('goal_${goal.name}_$type').hashCode.abs() % 100000;
  }

  /// Get all active goals
  Future<List<Goal>> getActiveGoals() async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      return goalBox.values.where((goal) => !goal.isCompleted).toList();
    } catch (e) {
      debugPrint("❌ [GoalService] Error getting active goals: $e");
      return [];
    }
  }

  /// Get completed goals
  Future<List<Goal>> getCompletedGoals() async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      return goalBox.values.where((goal) => goal.isCompleted).toList();
    } catch (e) {
      debugPrint("❌ [GoalService] Error getting completed goals: $e");
      return [];
    }
  }

  /// Update goal
  Future<bool> updateGoal(int key, Goal updatedGoal) async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      await goalBox.put(key, updatedGoal);
      debugPrint("✅ [GoalService] Goal updated: ${updatedGoal.name}");
      return true;
    } catch (e, st) {
      debugPrint("❌ [GoalService] Error updating goal: $e\n$st");
      return false;
    }
  }

  /// Delete goal
  Future<bool> deleteGoal(int key) async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      final goal = goalBox.get(key);

      // Clear milestone tracking
      if (goal != null) {
        final prefs = await SharedPreferences.getInstance();
        for (int milestone in [25, 50, 75]) {
          await prefs.remove('goal_${goal.name}_milestone_$milestone');
        }
      }

      await goalBox.delete(key);
      debugPrint("✅ [GoalService] Goal deleted");
      return true;
    } catch (e, st) {
      debugPrint("❌ [GoalService] Error deleting goal: $e\n$st");
      return false;
    }
  }

  /// Calculate recommended installment amount based on goal
  double calculateRecommendedInstallment(Goal goal) {
    final daysRemaining = goal.daysRemaining;
    if (daysRemaining <= 0) return goal.remainingAmount;

    final dailyAmount = goal.remainingAmount / daysRemaining;

    switch (goal.installmentFrequency.toLowerCase()) {
      case 'daily':
        return dailyAmount;
      case 'weekly':
        return dailyAmount * 7;
      case 'monthly':
        return dailyAmount * 30;
      default:
        return dailyAmount * 30;
    }
  }

  /// Clear notification cache (call when app starts)
  void clearNotificationCache() {
    _lastNotificationTime.clear();
  }
}