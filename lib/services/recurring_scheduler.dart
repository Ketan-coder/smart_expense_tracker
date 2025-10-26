import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../data/model/expense.dart';
import '../data/model/recurring.dart';
import '../data/model/wallet.dart';

const recurringTask = "checkRecurringPayments";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == recurringTask) {
      try {
        // Quick check: Skip if already processed today
        final prefs = await SharedPreferences.getInstance();
        final lastRun = prefs.getString('last_recurring_check');
        final today = DateTime.now().toIso8601String().substring(0, 10);

        if (lastRun == today) {
          return Future.value(true); // Already processed today
        }

        // Initialize Hive only once needed
        await Hive.initFlutter();

        // Register adapters with error handling
        if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
          Hive.registerAdapter(ExpenseAdapter());
        }
        if (!Hive.isAdapterRegistered(RecurringAdapter().typeId)) {
          Hive.registerAdapter(RecurringAdapter());
        }
        if (!Hive.isAdapterRegistered(WalletAdapter().typeId)) {
          Hive.registerAdapter(WalletAdapter());
        }

        // Open boxes
        final recurringBox = await Hive.openBox<Recurring>(AppConstants.recurrings);

        // Quick check: If no recurring payments exist, skip everything
        if (recurringBox.isEmpty) {
          await prefs.setString('last_recurring_check', today);
          return Future.value(true);
        }

        final walletBox = await Hive.openBox<Wallet>(AppConstants.wallets);
        final expenseBox = await Hive.openBox<Expense>(AppConstants.expenses);

        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        int processedCount = 0;

        // Process only active and due recurring payments
        for (var r in recurringBox.values) {
          // Skip expired recurrences
          if (r.endDate != null && todayDate.isAfter(r.endDate!)) continue;

          final lastDeduct = r.deductionDate != null
              ? DateTime(r.deductionDate!.year, r.deductionDate!.month, r.deductionDate!.day)
              : null;

          // Calculate next due date
          final nextDue = _nextDueDate(r.startDate, r.interval, lastDeduct);

          // Deduct if due today and not already deducted
          if (nextDue == todayDate && (lastDeduct == null || lastDeduct.isBefore(todayDate))) {
            await _deductRecurring(r, walletBox, expenseBox);
            r.deductionDate = now;
            await r.save();
            processedCount++;
          }
        }

        // Update last run date
        await prefs.setString('last_recurring_check', today);

        // Close boxes to free resources
        await recurringBox.close();
        await walletBox.close();
        await expenseBox.close();

        print('Processed $processedCount recurring payments');
      } catch (e) {
        print('Error in recurring task: $e');
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

DateTime _nextDueDate(DateTime start, String interval, DateTime? lastDeduct) {
  final base = lastDeduct ?? start;
  final baseDate = DateTime(base.year, base.month, base.day);

  switch (interval.toLowerCase()) {
    case 'daily':
      return DateTime(baseDate.year, baseDate.month, baseDate.day + 1);
    case 'weekly':
      return DateTime(baseDate.year, baseDate.month, baseDate.day + 7);
    case 'monthly':
    // Handle month-end edge cases
      int targetMonth = baseDate.month + 1;
      int targetYear = baseDate.year;
      if (targetMonth > 12) {
        targetMonth = 1;
        targetYear++;
      }
      return DateTime(targetYear, targetMonth, baseDate.day);
    case 'yearly':
      return DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
    default:
      return baseDate;
  }
}

Future<void> _deductRecurring(
    Recurring r,
    Box<Wallet> walletBox,
    Box<Expense> expenseBox,
    ) async {
  // Get default wallet
  final wallet = walletBox.isNotEmpty ? walletBox.values.first : null;
  if (wallet == null) return;

  // Check sufficient balance
  if (wallet.balance < r.amount) {
    print('Insufficient balance for recurring payment: ${r.description}');
    return;
  }

  // Deduct from wallet
  wallet.balance -= r.amount;
  await wallet.save();

  // Add to expenses history
  final expense = Expense(
    amount: r.amount,
    date: DateTime.now(),
    description: '🔁 ${r.description}', // Mark as recurring
    categoryKeys: r.categoryKeys,
  );
  await expenseBox.add(expense);
}

Future<void> registerRecurringTask() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode, // CRITICAL: Set to false in production
  );

  // Cancel any existing tasks first
  await Workmanager().cancelAll();

  // Register with much longer interval - daily is sufficient for recurring payments
  await Workmanager().registerPeriodicTask(
    "recurring_payments_check",
    recurringTask,
    frequency: const Duration(hours: 24), // Changed from 1 hour to 24 hours
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: true, // Skip when battery is low
      requiresCharging: false,
      requiresDeviceIdle: false,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 30),
  );
}

// Call this when user manually triggers refresh or adds new recurring payment
Future<void> checkRecurringNow() async {
  await Workmanager().registerOneOffTask(
    "recurring_immediate_check",
    recurringTask,
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}