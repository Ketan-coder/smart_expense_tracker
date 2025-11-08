// services/goal_notification_helper.dart
import 'package:flutter/cupertino.dart';
import '../data/model/goal.dart';
import 'goal_service.dart';
import 'notification_service.dart';

class GoalNotificationHelper {
  static final GoalNotificationHelper _instance = GoalNotificationHelper._internal();
  factory GoalNotificationHelper() => _instance;
  GoalNotificationHelper._internal();

  /// Check all goals and send appropriate notifications
  Future<void> checkAllGoalsProgress() async {
    try {
      final goalService = GoalService();
      final activeGoals = await goalService.getActiveGoals();

      for (final goal in activeGoals) {
        await _checkIndividualGoalProgress(goal);
      }

      // Check for goals needing attention
      final goalsNeedingAttention = await goalService.getGoalsNeedingAttention();
      if (goalsNeedingAttention.isNotEmpty) {
        await _sendGoalsSummaryNotification(goalsNeedingAttention);
      }
    } catch (e) {
      debugPrint("❌ [GoalNotificationHelper] Error checking goals progress: $e");
    }
  }

  /// Check individual goal progress
  Future<void> _checkIndividualGoalProgress(Goal goal) async {
    final progress = goal.progressPercentage;
    final daysLeft = goal.daysRemaining;

    // Send encouragement for good progress
    if (progress > 70 && daysLeft > 14) {
      await _sendEncouragementNotification(goal);
    }

    // Send warning for behind-schedule goals
    if (progress < 30 && daysLeft < (goal.totalDays * 0.4)) {
      await _sendBehindScheduleNotification(goal);
    }

    // Send urgent notification for critical goals
    if (daysLeft <= 3 && progress < 90) {
      await _sendUrgentNotification(goal);
    }
  }

  /// Send encouragement notification
  Future<void> _sendEncouragementNotification(Goal goal) async {
    await NotificationService.showNotification(
      id: _generateNotificationId(goal, 'encouragement'),
      title: "Great Progress! 🎯",
      body: "You're ${goal.progressPercentage.toInt()}% towards ${goal.name}. Keep up the great work!",
      channelId: 'goal_alerts',
      channelName: 'Goal Alerts',
      payload: 'open_goal_page',
    );
  }

  /// Send behind schedule notification
  Future<void> _sendBehindScheduleNotification(Goal goal) async {
    await NotificationService.showNotification(
      id: _generateNotificationId(goal, 'behind'),
      title: "Goal Needs Attention 📉",
      body: "${goal.name} is behind schedule. Consider increasing your savings rate.",
      channelId: 'goal_alerts',
      channelName: 'Goal Alerts',
      payload: 'open_goal_page',
    );
  }

  /// Send urgent notification
  Future<void> _sendUrgentNotification(Goal goal) async {
    await NotificationService.showNotification(
      id: _generateNotificationId(goal, 'urgent'),
      title: "Goal Deadline Approaching! ⚠️",
      body: "Only ${goal.daysRemaining} days left for ${goal.name}. ${goal.remainingAmount.toStringAsFixed(0)} remaining.",
      channelId: 'goal_alerts',
      channelName: 'Goal Alerts',
      payload: 'open_goal_page',
    );
  }

  /// Send weekly goals summary
  Future<void> _sendGoalsSummaryNotification(List<Goal> goals) async {
    final totalGoals = goals.length;
    final completedGoals = goals.where((g) => g.progressPercentage >= 100).length;
    final behindGoals = goals.where((g) => g.progressPercentage < 30 && g.daysRemaining < 30).length;

    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: "Weekly Goals Update 📊",
      body: "$completedGoals/$totalGoals goals on track. $behindGoals need attention.",
      channelId: 'goal_alerts',
      channelName: 'Goal Alerts',
      payload: 'open_goal_page',
    );
  }

  int _generateNotificationId(Goal goal, String type) {
    return ('goal_${goal.name}_$type${DateTime.now().day}').hashCode.abs() % 100000;
  }
}