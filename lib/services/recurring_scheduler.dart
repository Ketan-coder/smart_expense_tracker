import 'package:workmanager/workmanager.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../core/app_constants.dart';
import '../data/local/db_helper.dart';
import '../data/model/expense.dart';
import '../data/model/recurring.dart';
import '../data/model/wallet.dart';

const recurringTask = "checkRecurringPayments";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == recurringTask) {
      await Hive.initFlutter();
      // Register adapters
      Hive.registerAdapter(ExpenseAdapter());
      Hive.registerAdapter(RecurringAdapter());
      Hive.registerAdapter(WalletAdapter());

      // Open boxes
      await Hive.openBox<Expense>(AppConstants.expenses);
      await Hive.openBox<Recurring>(AppConstants.recurrings);
      await Hive.openBox<Wallet>(AppConstants.wallets);

      final recurringBox = Hive.box<Recurring>(AppConstants.recurrings);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var r in recurringBox.values) {
        // Skip expired recurrences
        if (r.endDate != null && today.isAfter(r.endDate!)) continue;

        final lastDeduct = r.deductionDate != null
            ? DateTime(r.deductionDate!.year, r.deductionDate!.month, r.deductionDate!.day)
            : null;

        // Calculate next due date based on interval
        final nextDue = _nextDueDate(r.startDate, r.interval, lastDeduct);

        // Deduct if due today and not already deducted
        if (nextDue == today && (lastDeduct == null || lastDeduct.isBefore(today))) {
          await _deductRecurring(r, walletBox, expenseBox);
          r.deductionDate = now;
          await r.save();
        }
      }
    }
    return Future.value(true);
  });
}

DateTime _nextDueDate(DateTime start, String interval, DateTime? lastDeduct) {
  final base = lastDeduct ?? start;

  switch (interval.toLowerCase()) {
    case 'daily':
      return DateTime(base.year, base.month, base.day + 1);
    case 'weekly':
      return DateTime(base.year, base.month, base.day + 7);
    case 'monthly':
      return DateTime(base.year, base.month + 1, base.day);
    case 'yearly':
      return DateTime(base.year + 1, base.month, base.day);
    default:
      return base; // fallback
  }
}

Future<void> _deductRecurring(
    Recurring r,
    Box<Wallet> walletBox,
    Box<Expense> expenseBox,
    ) async {
  // Deduct from default wallet (assuming index 0)
  final wallet = walletBox.isNotEmpty ? walletBox.values.first : null;
  if (wallet == null) return;

  wallet.balance -= r.amount;
  await wallet.save();

  // Add to expenses history
  final expense = Expense(
    amount: r.amount,
    date: DateTime.now(),
    description: r.description,
    categoryKeys: r.categoryKeys,
  );
  await expenseBox.add(expense);
}

Future<void> registerRecurringTask() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    "1",
    recurringTask,
    frequency: const Duration(hours: 1), // runs hourly
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
