import 'dart:io';

import 'package:expense_tracker/core/app_constants.dart';
import 'package:expense_tracker/data/local/universal_functions.dart';
import 'package:expense_tracker/data/model/daily_progress.dart';
import 'package:expense_tracker/data/model/expense.dart';
import 'package:expense_tracker/data/model/goal.dart';
import 'package:expense_tracker/data/model/habit.dart';
import 'package:expense_tracker/data/model/income.dart';
import 'package:expense_tracker/data/model/wallet.dart';
import 'package:expense_tracker/hive_registrar.g.dart';
import 'package:expense_tracker/screens/widgets/transaction_widget.dart';
import 'package:expense_tracker/screens/widgets/wallet_account_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'wallet_required_test',
    );
    Hive.init(hiveDirectory.path);
    Hive.registerAdapters();
    await Hive.openBox<Wallet>('wallets');
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Income>('incomes');
    await Hive.openBox<DailyProgress>(AppConstants.dailyProgress);
    await Hive.openBox<Goal>(AppConstants.goals);
    await Hive.openBox<Habit>(AppConstants.habits);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('income and expense require a wallet for manual entry', () async {
    expect(walletSelectionProblem(), WalletSelectionProblem.walletRequired);

    final expenses = Hive.box<Expense>('expenses');
    final incomes = Hive.box<Income>('incomes');
    final functions = UniversalHiveFunctions();

    expect(
      await functions.addExpense(
        amount: 25,
        description: 'Coffee',
        method: 'UPI',
        categoryKeys: const [],
      ),
      isFalse,
    );
    expect(
      await functions.addIncome(
        amount: 100,
        description: 'Refund',
        method: 'UPI',
        categoryKeys: const [],
      ),
      isFalse,
    );
    expect(expenses.length, 0);
    expect(incomes.length, 0);
  });

  test(
    'wallet validation distinguishes unselected and valid accounts',
    () async {
      final wallets = Hive.box<Wallet>('wallets');
      final walletKey = await wallets.add(
        Wallet(
          name: 'Cash',
          balance: 0,
          type: 'cash',
          createdAt: DateTime.now(),
        ),
      );

      expect(walletSelectionProblem(), isNull);

      await wallets.add(
        Wallet(
          name: 'Bank',
          balance: 0,
          type: 'bank',
          createdAt: DateTime.now(),
        ),
      );
      expect(
        walletSelectionProblem(),
        WalletSelectionProblem.walletSelectionRequired,
      );
      expect(walletSelectionProblem(walletKey: walletKey), isNull);
    },
  );

  test(
    'test data creates a wallet before saving editable transactions',
    () async {
      final wallets = Hive.box<Wallet>('wallets');
      final expenses = Hive.box<Expense>('expenses');
      final incomes = Hive.box<Income>('incomes');

      await wallets.clear();
      final walletKey = await ensureTestDataWallet();
      expect(wallets.get(walletKey), isNotNull);

      final functions = UniversalHiveFunctions();
      final date = DateTime.now().subtract(const Duration(days: 1));
      final expenseSaved = await functions.addExpense(
        amount: 25,
        description: 'Sample coffee',
        method: 'UPI',
        categoryKeys: const [],
        walletKey: walletKey,
        date: date,
      );
      final incomeSaved = await functions.addIncome(
        amount: 100,
        description: 'Sample income',
        method: 'UPI',
        categoryKeys: const [],
        walletKey: walletKey,
        date: date,
      );

      expect(expenseSaved, isTrue);
      expect(incomeSaved, isTrue);
      expect(expenses.values.single.walletKey, walletKey);
      expect(incomes.values.single.walletKey, walletKey);

      expect(
        await functions.updateExpense(
          expenses.keys.whereType<int>().single,
          Expense(
            amount: 30,
            date: date,
            description: 'Edited coffee',
            categoryKeys: const [],
            walletKey: walletKey,
          ),
        ),
        isTrue,
      );
      expect(
        await functions.updateIncome(
          incomes.keys.whereType<int>().single,
          Income(
            amount: 110,
            date: date,
            description: 'Edited income',
            categoryKeys: const [],
            walletKey: walletKey,
          ),
          'UPI',
        ),
        isTrue,
      );
    },
  );
}
