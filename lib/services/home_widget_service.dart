import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import 'package:hive_ce/hive.dart';
import '../core/app_constants.dart';

class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  Future<void> updateWidget() async {
    try {
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final prefs = await SharedPreferences.getInstance();

      final currency = prefs.getString('current_currency') ?? '₹';

      // Get today's data
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayExpenses = expenseBox.values.where((e) =>
      e.date.isAfter(todayStart) && e.date.isBefore(todayEnd)
      ).fold(0.0, (sum, e) => sum + e.amount);

      final todayIncome = incomeBox.values.where((i) =>
      i.date.isAfter(todayStart) && i.date.isBefore(todayEnd)
      ).fold(0.0, (sum, i) => sum + i.amount);

      // Update widget data
      await HomeWidget.saveWidgetData<String>('currency', currency);
      await HomeWidget.saveWidgetData<double>('todayExpense', todayExpenses);
      await HomeWidget.saveWidgetData<double>('todayIncome', todayIncome);
      await HomeWidget.saveWidgetData<int>('lastUpdate', DateTime.now().millisecondsSinceEpoch);

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: 'ExpenseTrackerWidget',
        iOSName: 'ExpenseTrackerWidget',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  Future<void> handleWidgetAction(String? action) async {
    if (action == null) return;

    switch (action) {
      case 'add_expense':
      // Handle add expense action
        break;
      case 'add_income':
      // Handle add income action
        break;
      case 'view_stats':
      // Handle view stats action
        break;
    }
  }
}