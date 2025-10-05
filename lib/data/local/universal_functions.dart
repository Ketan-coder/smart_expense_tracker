import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import '../../core/app_constants.dart';
import '../model/category.dart';
import '../model/expense.dart';
import '../model/income.dart';
import '../model/wallet.dart';

class UniversalHiveFunctions {
  /// Add an expense and update wallet balance
  Future<bool> addExpense(double amount, String desc, String type, List<int> categoryKeys) async {
    try {
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      final expense = Expense(
        amount: amount,
        date: DateTime.now(),
        description: type.isNotEmpty ? 'Payment via $type' : desc,
        categoryKeys: categoryKeys,
        method: type,
      );

      await expenseBox.add(expense);

      final wallet = walletBox.values.firstWhere(
            (w) => w.type.toLowerCase() == type.toLowerCase(),
        orElse: () => Wallet(name: type, balance: 0, updatedAt: DateTime.now(), type: 'UPI', createdAt: DateTime.now()),
      );

      wallet.balance -= amount;
      wallet.updatedAt = DateTime.now();
      await wallet.save();

      debugPrint("✅ Expense added successfully");
      return true;
    } catch (e, st) {
      debugPrint("❌ Error adding expense: $e\n$st");
      return false;
    }
  }

  Future<bool> updateExpense(int key, Expense newExpense) async {
    try {
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      final oldExpense = expenseBox.get(key);
      if (oldExpense == null) return false;

      // Revert wallet balance from old expense
      final oldWallet = walletBox.values.firstWhere(
            (w) => w.type.toLowerCase() == oldExpense.method?.toLowerCase(),
        orElse: () => Wallet(name: oldExpense.method.toString(), balance: 0, updatedAt: DateTime.now(), type: oldExpense.method.toString(), createdAt: DateTime.now()),
      );
      oldWallet.balance += oldExpense.amount;
      await oldWallet.save();

      // Deduct from new wallet
      final newWallet = walletBox.values.firstWhere(
            (w) => w.name.toLowerCase() == newExpense.method?.toLowerCase(),
        orElse: () => Wallet(name: newExpense.method.toString(), balance: 0, updatedAt: DateTime.now(), type: newExpense.method.toString(), createdAt: DateTime.now()),
      );
      newWallet.balance -= newExpense.amount;
      await newWallet.save();

      await expenseBox.put(key, newExpense);

      debugPrint("✅ Expense updated successfully.");
      return true;
    } catch (e, st) {
      debugPrint("❌ Error updating expense: $e\n$st");
      return false;
    }
  }


  /// Delete a single expense + revert wallet balance
  Future<bool> deleteExpense(int key) async {
    try {
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      final expense = expenseBox.get(key);
      if (expense == null) {
        debugPrint("❌ Expense not found for key $key");
        return false;
      }

      debugPrint("🧾 expense: $expense");

      // Try to find wallet that matches the expense method
      final wallet = walletBox.values.firstWhere(
            (w) => w.type.toLowerCase() == expense.method?.toLowerCase(),
        orElse: () {
          debugPrint("⚠️ No wallet found for method: ${expense.method}");
          return Wallet(name: "Unknown", balance: 0, updatedAt: DateTime.now(), type: expense.method.toString(), createdAt: DateTime.now());
        },
      );

      // Only update if wallet actually exists in box
      if (walletBox.values.any((w) => w.name == expense.method)) {
        wallet.balance += expense.amount;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
      }

      await expenseBox.delete(key);
      debugPrint("✅ Expense deleted and wallet updated successfully.");
      return true;
    } catch (e, st) {
      debugPrint("❌ Error deleting expense: $e\n$st");
      return false;
    }
  }



  /// Add new income to Hive and update wallet balance
  Future<bool> addIncome(
      double amount,
      String desc,
      String type, // wallet type (Bank/UPI/Cash etc.)
      List<int> categoryKeys,
      ) async {
    debugPrint("💰 [addIncome] Adding income...");
    try {
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      final income = Income(
        amount: amount,
        date: DateTime.now(),
        description: desc,
        categoryKeys: categoryKeys,
      );
      await incomeBox.add(income);
      debugPrint("✅ [addIncome] Income added: $income");

      // Find wallet
      Wallet? wallet;
      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == type.toLowerCase(),
        );
        debugPrint("💼 [addIncome] Found wallet: ${wallet.name}");
      } catch (_) {
        debugPrint("⚠️ [addIncome] Wallet not found for type '$type'");
      }

      // Update wallet balance
      if (wallet != null) {
        final before = wallet.balance;
        wallet.balance += amount;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("💵 [addIncome] Wallet '${wallet.name}' balance: $before → ${wallet.balance}");
      }

      return true;
    } catch (e) {
      debugPrint("❌ [addIncome] Error: $e");
      return false;
    }
  }

  /// Update a single income and adjust wallet balances
  Future<bool> updateIncome(int key, Income newIncome, String type) async {
    debugPrint("🔄 [updateIncome] Updating income key=$key...");
    try {
      final incomeBox = Hive.box<Income>(AppConstants.incomes);
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);

      final oldIncome = incomeBox.get(key);
      if (oldIncome == null) {
        debugPrint("⚠️ [updateIncome] Old income not found for key=$key");
        return false;
      }

      await incomeBox.put(key, newIncome);
      debugPrint("✅ [updateIncome] Income updated: $newIncome");

      Wallet? wallet;
      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == type.toLowerCase(),
        );
        debugPrint("💼 [updateIncome] Found wallet: ${wallet.name}");
      } catch (_) {
        debugPrint("⚠️ [updateIncome] Wallet not found for '$type'");
        wallet = null;
      }

      if (wallet != null) {
        final before = wallet.balance;
        wallet.balance -= oldIncome.amount;
        wallet.balance += newIncome.amount;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("💵 [updateIncome] Wallet '${wallet.name}' balance: $before → ${wallet.balance}");
      }

      return true;
    } catch (e) {
      debugPrint("❌ [updateIncome] Error: $e");
      return false;
    }
  }

  /// Delete a single income and roll back wallet balance
  Future<void> deleteIncome(int key, String type) async {
    debugPrint("🗑️ [deleteIncome] Deleting income key=$key...");
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    final income = incomeBox.get(key);
    if (income != null) {
      debugPrint("💰 [deleteIncome] Income found: $income");

      Wallet? wallet;
      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == type.toLowerCase(),
        );
        debugPrint("💼 [deleteIncome] Found wallet: ${wallet.name}");
      } catch (_) {
        debugPrint("⚠️ [deleteIncome] Wallet not found for type '$type'");
      }

      if (wallet != null) {
        final before = wallet.balance;
        wallet.balance -= income.amount;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("💵 [deleteIncome] Wallet '${wallet.name}' balance: $before → ${wallet.balance}");
      }

      await incomeBox.delete(key);
      debugPrint("✅ [deleteIncome] Income deleted successfully");
    } else {
      debugPrint("⚠️ [deleteIncome] No income found for key=$key");
    }
  }

  Future<bool> addCategory(String name, String type, Color color) async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final category = Category(
        name: name,
        type: type,
        color: '#${color.value.toRadixString(16).substring(2, 8)}',
      );
      await categoryBox.add(category);
      return true;
    } catch (e) {
      return false;
    }
  }
}
