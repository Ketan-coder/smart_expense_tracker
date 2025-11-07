import 'package:expense_tracker/data/local/universal_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';

import '../core/app_constants.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import '../data/model/wallet.dart';
import 'notification_service.dart';

/// Notification helper methods
class NotificationHelper {
  /// Check wallet balance and notify if negative or low
  static Future<void> checkWalletBalance(Wallet wallet, String operationType) async {
    try {
      if (wallet.balance < 0) {
        await NotificationService.showNotification(
          id: _generateNotificationId('negative_balance_${wallet.name}'),
          title: '⚠️ Negative Balance Alert',
          body: '${wallet.name} wallet is in negative: ${wallet.balance.toStringAsFixed(2)}',
          channelId: 'wallet_alerts',
          channelName: 'Wallet Alerts',
        );
        debugPrint("💰 [Notification] Negative balance alert for ${wallet.name}");
      }
      else if (wallet.balance < 50 && wallet.balance > 0) {
        await NotificationService.showNotification(
          id: _generateNotificationId('low_balance_${wallet.name}'),
          title: '💸 Low Balance Warning',
          body: '${wallet.name} wallet is running low: ${wallet.balance.toStringAsFixed(2)}',
          channelId: 'wallet_alerts',
          channelName: 'Wallet Alerts',
        );
        debugPrint("💰 [Notification] Low balance warning for ${wallet.name}");
      }
    } catch (e) {
      debugPrint("⚠️ [Notification] Error checking wallet balance: $e");
    }
  }

  /// Notify about large transactions
  static Future<void> notifyLargeTransaction(double amount, String type, String description) async {
    try {
      if (amount > 1000) {
        await NotificationService.showNotification(
          id: _generateNotificationId('large_${type}_${DateTime.now().millisecondsSinceEpoch}'),
          title: '💳 Large ${type.capitalize()}',
          body: '${amount.toStringAsFixed(2)} - $description',
          channelId: 'transaction_alerts',
          channelName: 'Transaction Alerts',
        );
        debugPrint("💳 [Notification] Large $type alert: $amount");
      }
    } catch (e) {
      debugPrint("⚠️ [Notification] Error sending large transaction alert: $e");
    }
  }

  /// Notify about monthly spending trends
  static Future<void> notifyMonthlySpending(double totalSpent, double budget) async {
    try {
      if (budget > 0 && totalSpent > budget * 0.8) {
        final percentage = (totalSpent / budget * 100).toInt();
        await NotificationService.showNotification(
          id: _generateNotificationId('monthly_budget_${DateTime.now().month}'),
          title: '📊 Budget Alert',
          body: 'You\'ve used $percentage% of your monthly budget',
          channelId: 'budget_alerts',
          channelName: 'Budget Alerts',
        );
        debugPrint("📊 [Notification] Monthly budget alert: $percentage% used");
      }
    } catch (e) {
      debugPrint("⚠️ [Notification] Error sending budget alert: $e");
    }
  }

  /// Notify about successful habit completion streaks
  static Future<void> notifyHabitStreak(String habitName, int streakCount) async {
    try {
      if (streakCount % 7 == 0 && streakCount > 0) { // Notify every 7 days
        await NotificationService.showNotification(
          id: _generateNotificationId('habit_streak_$habitName'),
          title: '🔥 Amazing Streak!',
          body: '$habitName: $streakCount days in a row! Keep going!',
          channelId: 'habit_alerts',
          channelName: 'Habit Alerts',
        );
        debugPrint("🔥 [Notification] Habit streak: $habitName - $streakCount days");
      }
    } catch (e) {
      debugPrint("⚠️ [Notification] Error sending habit streak alert: $e");
    }
  }

  /// Notify about savings milestones
  static Future<void> notifySavingsMilestone(double totalBalance) async {
    try {
      // Check for milestone amounts
      final milestones = [1000, 5000, 10000, 25000, 50000, 100000];
      for (final milestone in milestones) {
        if (totalBalance >= milestone && totalBalance < milestone + 100) {
          await NotificationService.showNotification(
            id: _generateNotificationId('savings_milestone_$milestone'),
            title: '🎉 Savings Milestone!',
            body: 'You\'ve saved ₹${milestone.toStringAsFixed(0)}! Great job!',
            channelId: 'savings_alerts',
            channelName: 'Savings Alerts',
          );
          debugPrint("🎉 [Notification] Savings milestone: ₹$milestone");
          break;
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Notification] Error sending savings milestone: $e");
    }
  }

  /// Generate unique notification ID
  static int _generateNotificationId(String key) {
    return key.hashCode.abs() % 100000;
  }

  /// Send daily/weekly financial summary
  Future<void> sendFinancialSummary() async {
    try {
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));

      // Calculate today's expenses
      final todayExpenses = expenseBox.values
          .where((expense) => expense.date.isAfter(today))
          .fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate weekly expenses
      final weeklyExpenses = expenseBox.values
          .where((expense) => expense.date.isAfter(weekAgo))
          .fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate total balance
      final totalBalance = await UniversalHiveFunctions().getTotalBalance();

      // Send summary notification
      await NotificationService.showNotification(
        id: NotificationHelper._generateNotificationId('daily_summary_${now.millisecondsSinceEpoch}'),
        title: '📈 Daily Summary',
        body: 'Today: ₹${todayExpenses.toStringAsFixed(0)} | Week: ₹${weeklyExpenses.toStringAsFixed(0)} | Total: ₹${totalBalance.toStringAsFixed(0)}',
        channelId: 'summary_alerts',
        channelName: 'Financial Summary',
      );

      debugPrint("📈 [Notification] Daily summary sent");
    } catch (e) {
      debugPrint("⚠️ [Notification] Error sending financial summary: $e");
    }
  }

  /// Check for unusual spending patterns
  Future<void> checkSpendingPatterns() async {
    try {
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // Get this month's expenses by category
      final monthlyExpenses = expenseBox.values
          .where((expense) => expense.date.isAfter(monthStart))
          .toList();

      if (monthlyExpenses.length > 10) {
        // Simple pattern: if more than 50% of expenses are in one category
        final categoryCounts = <String, double>{};
        for (final expense in monthlyExpenses) {
          // You'd need to get category names here
          // This is a simplified version
          final category = expense.categoryKeys.isNotEmpty ? 'Category' : 'Unknown';
          categoryCounts[category] = (categoryCounts[category] ?? 0) + expense.amount;
        }

        final total = categoryCounts.values.fold(0.0, (sum, amount) => sum + amount);
        for (final entry in categoryCounts.entries) {
          if (entry.value / total > 0.5) {
            await NotificationService.showNotification(
              id: NotificationHelper._generateNotificationId('spending_pattern_${entry.key}'),
              title: '📊 Spending Pattern',
              body: '${entry.key} makes up ${(entry.value / total * 100).toInt()}% of your spending this month',
              channelId: 'pattern_alerts',
              channelName: 'Spending Patterns',
            );
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Notification] Error checking spending patterns: $e");
    }
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}