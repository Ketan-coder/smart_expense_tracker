// services/goal_service.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
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

  /// Add a new goal
  Future<bool> addGoal(Goal goal) async {
    try {
      final goalBox = Hive.box<Goal>(AppConstants.goals);
      await goalBox.add(goal);

      debugPrint("🎯 [GoalService] Goal added: ${goal.name}");

      // Schedule progress notifications
      await _scheduleGoalNotifications(goal);

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

        // Check and send progress notifications
        await _checkGoalProgress(goal);

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
    List<int>? goalKeys, // Specific goals to allocate to
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
              await addGoalInstallment(
                goalKey,
                allocationAmount as double,
                description: "Income Allocation: $description",
              );
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

  /// Check goal progress and send notifications
  Future<void> _checkGoalProgress(Goal goal) async {
    final progress = goal.progressPercentage;
    final remaining = goal.remainingAmount;
    final daysLeft = goal.daysRemaining;

    // Milestone notifications
    if (progress >= 100 && !goal.isCompleted) {
      await _sendGoalCompletionNotification(goal);
    } else if (progress >= 75) {
      await _sendGoalProgressNotification(
          goal,
          "Almost There! 🎯",
          "Only ${remaining.toStringAsFixed(0)} left for ${goal.name} (${progress.toInt()}% complete)"
      );
    } else if (progress >= 50) {
      await _sendGoalProgressNotification(
          goal,
          "Halfway There! 🚀",
          "You're 50% towards your goal: ${goal.name}"
      );
    } else if (progress >= 25) {
      await _sendGoalProgressNotification(
          goal,
          "Great Start! 👍",
          "You've saved 25% for ${goal.name}. Keep going!"
      );
    }

    // Deadline warnings
    if (daysLeft <= 7 && daysLeft > 0) {
      await _sendGoalProgressNotification(
          goal,
          "Goal Deadline Approaching ⏰",
          "Only $daysLeft days left for ${goal.name}. ${remaining.toStringAsFixed(0)} remaining."
      );
    } else if (daysLeft <= 0 && !goal.isCompleted) {
      await _sendGoalProgressNotification(
          goal,
          "Goal Deadline Passed ❌",
          "Your goal '${goal.name}' deadline has passed. ${remaining.toStringAsFixed(0)} still needed."
      );
    }

    // Low progress warnings
    if (daysLeft < (goal.totalDays * 0.3) && progress < 30) {
      await _sendGoalProgressNotification(
          goal,
          "Goal Behind Schedule 📉",
          "Your goal '${goal.name}' is behind schedule. Consider increasing your installments."
      );
    }
  }

  /// Schedule regular goal notifications
  Future<void> _scheduleGoalNotifications(Goal goal) async {
    // Weekly progress notifications
    await NotificationService.scheduleNotification(
      id: _generateGoalNotificationId(goal, 'weekly'),
      title: "Goal Progress Update 📊",
      body: "Check your progress for '${goal.name}'. Current: ${goal.progressPercentage.toInt()}%",
      scheduledDate: DateTime.now().add(Duration(days: 7)),
    );

    // Monthly progress notifications
    await NotificationService.scheduleNotification(
      id: _generateGoalNotificationId(goal, 'monthly'),
      title: "Monthly Goal Review 📈",
      body: "Monthly update for '${goal.name}'. ${goal.remainingAmount.toStringAsFixed(0)} remaining.",
      scheduledDate: DateTime.now().add(Duration(days: 30)),
    );
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

  /// Get category keys for goal-related transactions
  Future<List<int>> _getGoalCategoryKeys() async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final goalCategory = categoryBox.values.firstWhere(
            (cat) => cat.name.toLowerCase() == 'savings',
        orElse: () => categoryBox.values.firstWhere(
              (cat) => cat.type.toLowerCase() == 'income',
        ),
      );
      return [categoryBox.keyAt(categoryBox.values.toList().indexOf(goalCategory)) as int];
    } catch (e) {
      debugPrint("⚠️ [GoalService] Error getting goal category, using first income category");
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final incomeCategories = categoryBox.values.where((cat) => cat.type.toLowerCase() == 'income').toList();
      if (incomeCategories.isNotEmpty) {
        return [categoryBox.keyAt(categoryBox.values.toList().indexOf(incomeCategories.first)) as int];
      }
      return [1]; // Fallback to first category
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
        return dailyAmount * 30; // Default to monthly
    }
  }
}