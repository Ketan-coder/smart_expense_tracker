// import 'package:flutter/cupertino.dart';
// import 'package:hive_ce/hive.dart';
// import '../../core/app_constants.dart';
// import '../model/category.dart';
// import '../model/expense.dart';
// import '../model/income.dart';
// import '../model/wallet.dart';
//
// class UniversalHiveFunctions {
//   /// Add an expense and update wallet balance
//   Future<bool> addExpense(double amount, String desc, String type, List<int> categoryKeys) async {
//     try {
//       final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//       final walletBox = Hive.box<Wallet>(AppConstants.wallets);
//
//       final expense = Expense(
//         amount: amount,
//         date: DateTime.now(),
//         description: type.isNotEmpty ? 'Payment via $type' : desc,
//         categoryKeys: categoryKeys,
//         method: type,
//       );
//
//       await expenseBox.add(expense);
//
//       Wallet wallet;
//       try {
//         wallet = walletBox.values.firstWhere(
//               (w) => w.type.toLowerCase() == type.toLowerCase(),
//         );
//
//         // Update existing wallet
//         wallet.balance -= amount;
//         wallet.updatedAt = DateTime.now();
//         await wallet.save();
//
//       } catch (e) {
//         // Wallet doesn't exist, create new one
//         wallet = Wallet(
//           name: type,
//           balance: -amount, // Starting with negative balance for expense
//           updatedAt: DateTime.now(),
//           type: type,
//           createdAt: DateTime.now(),
//         );
//
//         // Add the new wallet to the box
//         await walletBox.add(wallet);
//       }
//
//       debugPrint("✅ Expense added successfully");
//       return true;
//     } catch (e, st) {
//       debugPrint("❌ Error adding expense: $e\n$st");
//       return false;
//     }
//   }
//
//   Future<bool> updateExpense(int key, Expense newExpense) async {
//     try {
//       final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//       final walletBox = Hive.box<Wallet>(AppConstants.wallets);
//
//       final oldExpense = expenseBox.get(key);
//       if (oldExpense == null) return false;
//
//       // Revert wallet balance from old expense
//       final oldWallet = walletBox.values.firstWhere(
//             (w) => w.type.toLowerCase() == oldExpense.method?.toLowerCase(),
//         orElse: () => Wallet(name: oldExpense.method.toString(), balance: 0, updatedAt: DateTime.now(), type: oldExpense.method.toString(), createdAt: DateTime.now()),
//       );
//       oldWallet.balance += oldExpense.amount;
//       await oldWallet.save();
//
//       // Deduct from new wallet
//       final newWallet = walletBox.values.firstWhere(
//             (w) => w.name.toLowerCase() == newExpense.method?.toLowerCase(),
//         orElse: () => Wallet(name: newExpense.method.toString(), balance: 0, updatedAt: DateTime.now(), type: newExpense.method.toString(), createdAt: DateTime.now()),
//       );
//       newWallet.balance -= newExpense.amount;
//       await newWallet.save();
//
//       await expenseBox.put(key, newExpense);
//
//       debugPrint("✅ Expense updated successfully.");
//       return true;
//     } catch (e, st) {
//       debugPrint("❌ Error updating expense: $e\n$st");
//       return false;
//     }
//   }
//
//
//   /// Delete a single expense + revert wallet balance
//   Future<bool> deleteExpense(int key) async {
//     try {
//       final expenseBox = Hive.box<Expense>(AppConstants.expenses);
//       final walletBox = Hive.box<Wallet>(AppConstants.wallets);
//
//       final expense = expenseBox.get(key);
//       if (expense == null) {
//         debugPrint("❌ Expense not found for key $key");
//         return false;
//       }
//
//       debugPrint("🧾 expense: $expense");
//
//       // Try to find wallet that matches the expense method
//       final wallet = walletBox.values.firstWhere(
//             (w) => w.type.toLowerCase() == expense.method?.toLowerCase(),
//         orElse: () {
//           debugPrint("⚠️ No wallet found for method: ${expense.method}");
//           return Wallet(name: "Unknown", balance: 0, updatedAt: DateTime.now(), type: expense.method.toString(), createdAt: DateTime.now());
//         },
//       );
//
//       // Only update if wallet actually exists in box
//       if (walletBox.values.any((w) => w.name == expense.method)) {
//         wallet.balance += expense.amount;
//         wallet.updatedAt = DateTime.now();
//         await wallet.save();
//       }
//
//       await expenseBox.delete(key);
//       debugPrint("✅ Expense deleted and wallet updated successfully.");
//       return true;
//     } catch (e, st) {
//       debugPrint("❌ Error deleting expense: $e\n$st");
//       return false;
//     }
//   }
//
//
//
//   /// Add new income to Hive and update wallet balance
//   Future<bool> addIncome(
//       double amount,
//       String desc,
//       String type, // wallet type (Bank/UPI/Cash etc.)
//       List<int> categoryKeys,
//       ) async {
//     debugPrint("💰 [addIncome] Adding income...");
//     try {
//       final incomeBox = Hive.box<Income>(AppConstants.incomes);
//       final walletBox = Hive.box<Wallet>(AppConstants.wallets);
//
//       final income = Income(
//         amount: amount,
//         date: DateTime.now(),
//         description: desc,
//         categoryKeys: categoryKeys,
//       );
//       await incomeBox.add(income);
//       debugPrint("✅ [addIncome] Income added: $income");
//
//       // Find wallet
//       Wallet? wallet;
//       try {
//         wallet = walletBox.values.firstWhere(
//               (w) => w.type.toLowerCase() == type.toLowerCase(),
//         );
//         debugPrint("💼 [addIncome] Found wallet: ${wallet.name}");
//       } catch (_) {
//         debugPrint("⚠️ [addIncome] Wallet not found for type '$type'");
//       }
//
//       // Update wallet balance
//       if (wallet != null) {
//         final before = wallet.balance;
//         wallet.balance += amount;
//         wallet.updatedAt = DateTime.now();
//         await wallet.save();
//         debugPrint("💵 [addIncome] Wallet '${wallet.name}' balance: $before → ${wallet.balance}");
//       }
//
//       return true;
//     } catch (e) {
//       debugPrint("❌ [addIncome] Error: $e");
//       return false;
//     }
//   }
//
//   /// Update a single income and adjust wallet balances
//   Future<bool> updateIncome(int key, Income newIncome, String type) async {
//     debugPrint("🔄 [updateIncome] Updating income key=$key...");
//     try {
//       final incomeBox = Hive.box<Income>(AppConstants.incomes);
//       final walletBox = Hive.box<Wallet>(AppConstants.wallets);
//
//       final oldIncome = incomeBox.get(key);
//       if (oldIncome == null) {
//         debugPrint("⚠️ [updateIncome] Old income not found for key=$key");
//         return false;
//       }
//
//       await incomeBox.put(key, newIncome);
//       debugPrint("✅ [updateIncome] Income updated: $newIncome");
//
//       Wallet? wallet;
//       try {
//         wallet = walletBox.values.firstWhere(
//               (w) => w.type.toLowerCase() == type.toLowerCase(),
//         );
//         debugPrint("💼 [updateIncome] Found wallet: ${wallet.name}");
//       } catch (_) {
//         debugPrint("⚠️ [updateIncome] Wallet not found for '$type'");
//         wallet = null;
//       }
//
//       if (wallet != null) {
//         final before = wallet.balance;
//         wallet.balance -= oldIncome.amount;
//         wallet.balance += newIncome.amount;
//         wallet.updatedAt = DateTime.now();
//         await wallet.save();
//         debugPrint("💵 [updateIncome] Wallet '${wallet.name}' balance: $before → ${wallet.balance}");
//       }
//
//       return true;
//     } catch (e) {
//       debugPrint("❌ [updateIncome] Error: $e");
//       return false;
//     }
//   }
//
//   /// Delete a single income and roll back wallet balance
//   Future<void> deleteIncome(int key, String type) async {
//     debugPrint("🗑️ [deleteIncome] Deleting income key=$key...");
//     final incomeBox = Hive.box<Income>(AppConstants.incomes);
//     final walletBox = Hive.box<Wallet>(AppConstants.wallets);
//
//     final income = incomeBox.get(key);
//     if (income != null) {
//       debugPrint("💰 [deleteIncome] Income found: $income");
//
//       Wallet? wallet;
//       try {
//         wallet = walletBox.values.firstWhere(
//               (w) => w.type.toLowerCase() == type.toLowerCase(),
//         );
//         debugPrint("💼 [deleteIncome] Found wallet: ${wallet.name}");
//       } catch (_) {
//         debugPrint("⚠️ [deleteIncome] Wallet not found for type '$type'");
//       }
//
//       if (wallet != null) {
//         final before = wallet.balance;
//         wallet.balance -= income.amount;
//         wallet.updatedAt = DateTime.now();
//         await wallet.save();
//         debugPrint("💵 [deleteIncome] Wallet '${wallet.name}' balance: $before → ${wallet.balance}");
//       }
//
//       await incomeBox.delete(key);
//       debugPrint("✅ [deleteIncome] Income deleted successfully");
//     } else {
//       debugPrint("⚠️ [deleteIncome] No income found for key=$key");
//     }
//   }
//
//   Future<bool> addCategory(String name, String type, Color color) async {
//     try {
//       final categoryBox = Hive.box<Category>(AppConstants.categories);
//       final category = Category(
//         name: name,
//         type: type,
//         color: '#${color.value.toRadixString(16).substring(2, 8)}',
//       );
//       await categoryBox.add(category);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   Future<bool> updateCategory(int key, Category newCategory) async {
//     try {
//       final categoryBox = Hive.box<Category>(AppConstants.categories);
//       await categoryBox.put(key, newCategory);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   Future<bool> deleteCategory(int key) async {
//     try {
//       final categoryBox = Hive.box<Category>(AppConstants.categories);
//       await categoryBox.delete(key);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   Future<List<Category>> getCategories() async {
//     try {
//       final categoryBox = Hive.box<Category>(AppConstants.categories);
//       return categoryBox.values.toList();
//       } catch (e) {
//       return [];
//     }
//   }
//
// //   Initialize category on first run
//   Future<bool> initCategories() async {
//     try {
//       final categoryBox = Hive.box<Category>(AppConstants.categories);
//       if (categoryBox.isEmpty) {
//         await addCategory('Groceries', 'Expense', Color(0xFFF44336));
//         await addCategory('Salary', 'Income', Color(0xFF4CAF50));
//         await addCategory('Rent', 'Expense', Color(0xFF2196F3));
//         await addCategory('Savings', 'Income', Color(0xFFE91E63));
//         await addCategory('Utilities', 'Expense', Color(0xFF673AB7));
//         await addCategory('Other', 'Expense', Color(0xFF3F51B5));
//       }
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:hive_ce/hive.dart';
import '../../core/app_constants.dart';
import '../../services/goal_service.dart';
import '../../services/notification_helper.dart';
import '../model/category.dart';
import '../model/expense.dart';
import '../model/goal.dart';
import '../model/habit.dart';
import '../model/income.dart';
import '../model/wallet.dart';

class UniversalHiveFunctions {
  static final UniversalHiveFunctions _instance = UniversalHiveFunctions._internal();
  factory UniversalHiveFunctions() => _instance;
  UniversalHiveFunctions._internal();

  /// Atomic operation: Add expense and update/create wallet with rollback support
  Future<bool> addExpense({
    required double amount,
    required String description,
    required String method,
    required List<int> categoryKeys,
    DateTime? date,
  }) async {
    debugPrint("💰 [addExpense] Starting atomic operation...");

    // Validate inputs
    if (amount <= 0) {
      debugPrint("❌ [addExpense] Invalid amount: $amount");
      return false;
    }
    if (method.trim().isEmpty) {
      debugPrint("❌ [addExpense] Method cannot be empty");
      return false;
    }

    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Expense? savedExpense;
    Wallet? originalWallet;
    double originalBalance = 0;
    int? walletKey;

    try {
      // Step 1: Create expense object
      final expense = Expense(
        amount: amount,
        date: date ?? DateTime.now(),
        description: description,
        categoryKeys: categoryKeys,
        method: method.trim(),
      );

      // Step 2: Find or create wallet
      Wallet wallet;
      final normalizedMethod = method.trim().toLowerCase();

      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == normalizedMethod,
        );
        originalWallet = wallet;
        originalBalance = wallet.balance;
        walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(wallet));
        debugPrint("💼 [addExpense] Found existing wallet: ${wallet.name} (key: $walletKey)");
      } catch (_) {
        // Create new wallet
        wallet = Wallet(
          name: method.trim(),
          balance: 0,
          updatedAt: DateTime.now(),
          type: method.trim(),
          createdAt: DateTime.now(),
        );
        debugPrint("🆕 [addExpense] Creating new wallet: ${wallet.name}");
      }

      // Step 3: Update wallet balance
      wallet.balance -= amount;
      wallet.updatedAt = DateTime.now();

      // Step 4: Save wallet appropriately
      if (walletKey != null) {
        // Existing wallet - use save()
        await wallet.save();
        debugPrint("💵 [addExpense] Existing wallet updated: ${wallet.name} → Balance: ${wallet.balance}");
      } else {
        // New wallet - use add()
        walletKey = await walletBox.add(wallet);
        debugPrint("💵 [addExpense] New wallet created: ${wallet.name} → Balance: ${wallet.balance} (key: $walletKey)");
      }

      // Step 5: Save expense
      final expenseKey = await expenseBox.add(expense);
      savedExpense = expense;
      debugPrint("✅ [addExpense] Expense added successfully: $expense (key: $expenseKey)");

      await NotificationHelper.checkWalletBalance(wallet, 'expense');
      await NotificationHelper.notifyLargeTransaction(amount, 'expense', description);

      // Check total balance for savings milestone
      final totalBalance = await getTotalBalance();
      await NotificationHelper.notifySavingsMilestone(totalBalance);

      return true;

    } catch (e, st) {
      debugPrint("❌ [addExpense] Atomic operation failed: $e\n$st");

      // Rollback logic
      await _rollbackExpenseAdd(expenseBox, walletBox, savedExpense, originalWallet, originalBalance);

      return false;
    }
  }

  /// Rollback for failed expense addition
  Future<void> _rollbackExpenseAdd(
      Box<Expense> expenseBox,
      Box<Wallet> walletBox,
      Expense? savedExpense,
      Wallet? originalWallet,
      double originalBalance,
      ) async {
    try {
      // Remove saved expense if any
      if (savedExpense != null) {
        final expenseKey = expenseBox.keyAt(expenseBox.values.toList().indexOf(savedExpense));
        await expenseBox.delete(expenseKey);
        debugPrint("↩️ [rollback] Removed expense");
      }

      // Restore original wallet balance
      if (originalWallet != null) {
        originalWallet.balance = originalBalance;
        originalWallet.updatedAt = DateTime.now();
        await originalWallet.save();
        debugPrint("↩️ [rollback] Restored wallet balance: $originalBalance");
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during rollback: $e");
    }
  }

  /// Atomic operation: Update expense with rollback support
  Future<bool> updateExpense(int key, Expense newExpense) async {
    debugPrint("🔄 [updateExpense] Starting atomic update...");

    if (newExpense.amount <= 0 || newExpense.method!.trim().isEmpty ?? true) {
      debugPrint("❌ [updateExpense] Invalid expense data");
      return false;
    }

    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Expense? oldExpense;
    Wallet? oldWallet;
    Wallet? newWallet;
    double oldWalletOriginalBalance = 0;
    double newWalletOriginalBalance = 0;
    int? oldWalletKey;
    int? newWalletKey;

    try {
      // Step 1: Get old expense
      oldExpense = expenseBox.get(key);
      if (oldExpense == null) {
        debugPrint("❌ [updateExpense] Expense not found for key: $key");
        return false;
      }

      // Step 2: Find old wallet
      if (oldExpense.method != null) {
        try {
          oldWallet = walletBox.values.firstWhere(
                (w) => w.type.toLowerCase() == oldExpense?.method!.toLowerCase(),
          );
          oldWalletOriginalBalance = oldWallet.balance;
          oldWalletKey = walletBox.keyAt(walletBox.values.toList().indexOf(oldWallet));
        } catch (_) {
          debugPrint("⚠️ [updateExpense] Old wallet not found: ${oldExpense.method}");
        }
      }

      // Step 3: Find or create new wallet
      final newMethod = newExpense.method!.trim().toLowerCase();
      try {
        newWallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == newMethod,
        );
        newWalletOriginalBalance = newWallet.balance;
        newWalletKey = walletBox.keyAt(walletBox.values.toList().indexOf(newWallet));
      } catch (_) {
        newWallet = Wallet(
          name: newExpense.method!,
          balance: 0,
          updatedAt: DateTime.now(),
          type: newExpense.method!,
          createdAt: DateTime.now(),
        );
        debugPrint("🆕 [updateExpense] Creating new wallet: ${newWallet.name}");
      }

      // Step 4: Update wallet balances
      if (oldWallet != null) {
        oldWallet.balance += oldExpense.amount; // Revert old expense
        oldWallet.updatedAt = DateTime.now();
        await oldWallet.save();
        debugPrint("💵 [updateExpense] Old wallet reverted: ${oldWallet.name} → Balance: ${oldWallet.balance}");
      }

      newWallet.balance -= newExpense.amount; // Apply new expense
      newWallet.updatedAt = DateTime.now();

      if (newWalletKey != null) {
        await newWallet.save();
        debugPrint("💵 [updateExpense] Existing wallet updated: ${newWallet.name} → Balance: ${newWallet.balance}");
      } else {
        newWalletKey = await walletBox.add(newWallet);
        debugPrint("💵 [updateExpense] New wallet created: ${newWallet.name} → Balance: ${newWallet.balance}");
      }

      // Step 5: Update expense
      await expenseBox.put(key, newExpense);
      debugPrint("✅ [updateExpense] Expense updated successfully");

      return true;

    } catch (e, st) {
      debugPrint("❌ [updateExpense] Atomic update failed: $e\n$st");

      // Rollback
      await _rollbackExpenseUpdate(
          expenseBox, walletBox, key, oldExpense,
          oldWallet, oldWalletOriginalBalance,
          newWallet, newWalletOriginalBalance
      );

      return false;
    }
  }

  /// Rollback for failed expense update
  Future<void> _rollbackExpenseUpdate(
      Box<Expense> expenseBox,
      Box<Wallet> walletBox,
      int expenseKey,
      Expense? oldExpense,
      Wallet? oldWallet,
      double oldWalletOriginalBalance,
      Wallet? newWallet,
      double newWalletOriginalBalance,
      ) async {
    try {
      // Restore old expense
      if (oldExpense != null) {
        await expenseBox.put(expenseKey, oldExpense);
        debugPrint("↩️ [rollback] Restored original expense");
      }

      // Restore old wallet balance
      if (oldWallet != null) {
        oldWallet.balance = oldWalletOriginalBalance;
        oldWallet.updatedAt = DateTime.now();
        await oldWallet.save();
        debugPrint("↩️ [rollback] Restored old wallet balance");
      }

      // Restore new wallet balance or remove if newly created
      if (newWallet != null) {
        if (newWalletOriginalBalance == 0) {
          // This was a newly created wallet, remove it
          final newWalletKey = walletBox.keyAt(walletBox.values.toList().indexOf(newWallet));
          await walletBox.delete(newWalletKey);
          debugPrint("↩️ [rollback] Removed newly created wallet");
        } else {
          newWallet.balance = newWalletOriginalBalance;
          newWallet.updatedAt = DateTime.now();
          await newWallet.save();
          debugPrint("↩️ [rollback] Restored new wallet balance");
        }
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during update rollback: $e");
    }
  }

  /// Atomic operation: Delete expense with rollback support
  Future<bool> deleteExpense(int key) async {
    debugPrint("🗑️ [deleteExpense] Starting atomic deletion...");

    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Expense? expense;
    Wallet? wallet;
    double originalBalance = 0;
    int? walletKey;

    try {
      // Step 1: Get expense
      expense = expenseBox.get(key);
      if (expense == null) {
        debugPrint("❌ [deleteExpense] Expense not found for key: $key");
        return false;
      }

      // Step 2: Find wallet
      if (expense.method != null) {
        try {
          wallet = walletBox.values.firstWhere(
                (w) => w.type.toLowerCase() == expense!.method!.toLowerCase(),
          );
          originalBalance = wallet.balance;
          walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(wallet));
        } catch (_) {
          debugPrint("⚠️ [deleteExpense] Wallet not found for method: ${expense.method}");
        }
      }

      // Step 3: Update wallet balance
      if (wallet != null) {
        wallet.balance += expense.amount;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("💵 [deleteExpense] Wallet updated: ${wallet.name} → Balance: ${wallet.balance}");
      }

      // Step 4: Delete expense
      await expenseBox.delete(key);
      debugPrint("✅ [deleteExpense] Expense deleted successfully");

      return true;

    } catch (e, st) {
      debugPrint("❌ [deleteExpense] Atomic deletion failed: $e\n$st");

      // Rollback
      await _rollbackExpenseDelete(expenseBox, walletBox, key, expense, wallet, originalBalance);

      return false;
    }
  }

  /// Rollback for failed expense deletion
  Future<void> _rollbackExpenseDelete(
      Box<Expense> expenseBox,
      Box<Wallet> walletBox,
      int expenseKey,
      Expense? expense,
      Wallet? wallet,
      double originalBalance,
      ) async {
    try {
      // Restore expense
      if (expense != null) {
        await expenseBox.put(expenseKey, expense);
        debugPrint("↩️ [rollback] Restored deleted expense");
      }

      // Restore wallet balance
      if (wallet != null) {
        wallet.balance = originalBalance;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("↩️ [rollback] Restored wallet balance: $originalBalance");
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during delete rollback: $e");
    }
  }

  /// Atomic operation: Add income and update/create wallet with rollback support
  Future<bool> addIncome({
    required double amount,
    required String description,
    required String method,
    required List<int> categoryKeys,
    DateTime? date,
  }) async {
    debugPrint("💰 [addIncome] Starting atomic operation...");

    // Validate inputs
    if (amount <= 0) {
      debugPrint("❌ [addIncome] Invalid amount: $amount");
      return false;
    }
    if (method.trim().isEmpty) {
      debugPrint("❌ [addIncome] Method cannot be empty");
      return false;
    }

    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Income? savedIncome;
    Wallet? originalWallet;
    double originalBalance = 0;
    int? walletKey;

    try {
      // Step 1: Create income object
      final income = Income(
        amount: amount,
        date: date ?? DateTime.now(),
        description: description,
        categoryKeys: categoryKeys,
      );

      // Step 2: Find or create wallet
      Wallet wallet;
      final normalizedMethod = method.trim().toLowerCase();

      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == normalizedMethod,
        );
        originalWallet = wallet;
        originalBalance = wallet.balance;
        walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(wallet));
        debugPrint("💼 [addIncome] Found existing wallet: ${wallet.name} (key: $walletKey)");
      } catch (_) {
        // Create new wallet
        wallet = Wallet(
          name: method.trim(),
          balance: 0,
          updatedAt: DateTime.now(),
          type: method.trim(),
          createdAt: DateTime.now(),
        );
        debugPrint("🆕 [addIncome] Creating new wallet: ${wallet.name}");
      }

      // Step 3: Update wallet balance
      wallet.balance += amount;
      wallet.updatedAt = DateTime.now();

      // Step 4: Save wallet appropriately
      if (walletKey != null) {
        // Existing wallet - use save()
        await wallet.save();
        debugPrint("💵 [addIncome] Existing wallet updated: ${wallet.name} → Balance: ${wallet.balance}");
      } else {
        // New wallet - use add()
        walletKey = await walletBox.add(wallet);
        debugPrint("💵 [addIncome] New wallet created: ${wallet.name} → Balance: ${wallet.balance} (key: $walletKey)");
      }

      // Step 5: Save income
      final incomeKey = await incomeBox.add(income);
      savedIncome = income;
      debugPrint("✅ [addIncome] Income added successfully: $income (key: $incomeKey)");

      await NotificationHelper.checkWalletBalance(wallet, 'income');
      await NotificationHelper.notifyLargeTransaction(amount, 'income', description);

      // Check total balance for savings milestone
      final totalBalance = await getTotalBalance();
      await NotificationHelper.notifySavingsMilestone(totalBalance);

      return true;

    } catch (e, st) {
      debugPrint("❌ [addIncome] Atomic operation failed: $e\n$st");

      // Rollback logic
      await _rollbackIncomeAdd(incomeBox, walletBox, savedIncome, originalWallet, originalBalance);

      return false;
    }
  }

  /// Rollback for failed income addition
  Future<void> _rollbackIncomeAdd(
      Box<Income> incomeBox,
      Box<Wallet> walletBox,
      Income? savedIncome,
      Wallet? originalWallet,
      double originalBalance,
      ) async {
    try {
      // Remove saved income if any
      if (savedIncome != null) {
        final incomeKey = incomeBox.keyAt(incomeBox.values.toList().indexOf(savedIncome));
        await incomeBox.delete(incomeKey);
        debugPrint("↩️ [rollback] Removed income");
      }

      // Restore original wallet balance
      if (originalWallet != null) {
        originalWallet.balance = originalBalance;
        originalWallet.updatedAt = DateTime.now();
        await originalWallet.save();
        debugPrint("↩️ [rollback] Restored wallet balance: $originalBalance");
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during income rollback: $e");
    }
  }

  /// Atomic operation: Update income with rollback support
  Future<bool> updateIncome(int key, Income newIncome, String method) async {
    debugPrint("🔄 [updateIncome] Starting atomic update...");

    if (newIncome.amount <= 0 || method.trim().isEmpty) {
      debugPrint("❌ [updateIncome] Invalid income data");
      return false;
    }

    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Income? oldIncome;
    Wallet? wallet;
    double originalBalance = 0;
    int? walletKey;

    try {
      // Step 1: Get old income
      oldIncome = incomeBox.get(key);
      if (oldIncome == null) {
        debugPrint("❌ [updateIncome] Income not found for key: $key");
        return false;
      }

      // Step 2: Find or create wallet
      final normalizedMethod = method.trim().toLowerCase();
      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == normalizedMethod,
        );
        originalBalance = wallet.balance;
        walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(wallet));
      } catch (_) {
        wallet = Wallet(
          name: method.trim(),
          balance: 0,
          updatedAt: DateTime.now(),
          type: method.trim(),
          createdAt: DateTime.now(),
        );
        debugPrint("🆕 [updateIncome] Creating new wallet: ${wallet.name}");
      }

      // Step 3: Update wallet balance (revert old, apply new)
      wallet.balance -= oldIncome.amount; // Revert old income
      wallet.balance += newIncome.amount; // Apply new income
      wallet.updatedAt = DateTime.now();

      if (walletKey != null) {
        await wallet.save();
        debugPrint("💵 [updateIncome] Existing wallet updated: ${wallet.name} → Balance: ${wallet.balance}");
      } else {
        walletKey = await walletBox.add(wallet);
        debugPrint("💵 [updateIncome] New wallet created: ${wallet.name} → Balance: ${wallet.balance}");
      }

      // Step 4: Update income
      await incomeBox.put(key, newIncome);
      debugPrint("✅ [updateIncome] Income updated successfully");

      return true;

    } catch (e, st) {
      debugPrint("❌ [updateIncome] Atomic update failed: $e\n$st");

      // Rollback
      await _rollbackIncomeUpdate(incomeBox, walletBox, key, oldIncome, wallet, originalBalance);

      return false;
    }
  }

  /// Rollback for failed income update
  Future<void> _rollbackIncomeUpdate(
      Box<Income> incomeBox,
      Box<Wallet> walletBox,
      int incomeKey,
      Income? oldIncome,
      Wallet? wallet,
      double originalBalance,
      ) async {
    try {
      // Restore old income
      if (oldIncome != null) {
        await incomeBox.put(incomeKey, oldIncome);
        debugPrint("↩️ [rollback] Restored original income");
      }

      // Restore wallet balance or remove if newly created
      if (wallet != null) {
        if (originalBalance == 0) {
          // This was a newly created wallet, remove it
          final walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(wallet));
          await walletBox.delete(walletKey);
          debugPrint("↩️ [rollback] Removed newly created wallet");
        } else {
          wallet.balance = originalBalance;
          wallet.updatedAt = DateTime.now();
          await wallet.save();
          debugPrint("↩️ [rollback] Restored wallet balance: $originalBalance");
        }
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during income update rollback: $e");
    }
  }

  /// Atomic operation: Delete income with rollback support
  Future<bool> deleteIncome(int key, String method) async {
    debugPrint("🗑️ [deleteIncome] Starting atomic deletion...");

    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Income? income;
    Wallet? wallet;
    double originalBalance = 0;
    int? walletKey;

    try {
      // Step 1: Get income
      income = incomeBox.get(key);
      if (income == null) {
        debugPrint("❌ [deleteIncome] Income not found for key: $key");
        return false;
      }

      // Step 2: Find wallet
      final normalizedMethod = method.trim().toLowerCase();
      try {
        wallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == normalizedMethod,
        );
        originalBalance = wallet.balance;
        walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(wallet));
      } catch (_) {
        debugPrint("⚠️ [deleteIncome] Wallet not found for method: $method");
      }

      // Step 3: Update wallet balance
      if (wallet != null) {
        wallet.balance -= income.amount;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("💵 [deleteIncome] Wallet updated: ${wallet.name} → Balance: ${wallet.balance}");
      }

      // Step 4: Delete income
      await incomeBox.delete(key);
      debugPrint("✅ [deleteIncome] Income deleted successfully");

      return true;

    } catch (e, st) {
      debugPrint("❌ [deleteIncome] Atomic deletion failed: $e\n$st");

      // Rollback
      await _rollbackIncomeDelete(incomeBox, walletBox, key, income, wallet, originalBalance);

      return false;
    }
  }

  /// Rollback for failed income deletion
  Future<void> _rollbackIncomeDelete(
      Box<Income> incomeBox,
      Box<Wallet> walletBox,
      int incomeKey,
      Income? income,
      Wallet? wallet,
      double originalBalance,
      ) async {
    try {
      // Restore income
      if (income != null) {
        await incomeBox.put(incomeKey, income);
        debugPrint("↩️ [rollback] Restored deleted income");
      }

      // Restore wallet balance
      if (wallet != null) {
        wallet.balance = originalBalance;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("↩️ [rollback] Restored wallet balance: $originalBalance");
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during income delete rollback: $e");
    }
  }

  /// Add income with automatic goal allocation
  Future<bool> addIncomeWithGoalAllocation({
    required double amount,
    required String description,
    required String method,
    required List<int> categoryKeys,
    List<int>? goalKeys, // Specific goals to allocate to
    DateTime? date,
  }) async {
    return await GoalService().addIncomeAndAllocateToGoals(
      amount: amount,
      description: description,
      method: method,
      categoryKeys: categoryKeys,
      date: date,
      goalKeys: goalKeys,
    );
  }

  /// Get goals for allocation suggestions
  Future<List<Goal>> getGoalsForAllocation() async {
    try {
      final goalService = GoalService();
      return await goalService.getActiveGoals();
    } catch (e) {
      debugPrint("❌ [UniversalHiveFunctions] Error getting goals for allocation: $e");
      return [];
    }
  }

  // Category operations (simpler, no wallet dependencies)
  Future<bool> addCategory(String name, String type, Color color, String icon) async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);

      // Check for duplicates
      final exists = categoryBox.values.any(
              (cat) => cat.name.toLowerCase() == name.toLowerCase() && cat.type == type
      );

      if (exists) {
        debugPrint("⚠️ [addCategory] Category '$name' of type '$type' already exists");
        return false;
      }

      final category = Category(
        name: name,
        type: type,
        color: '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        icon: icon,
      );

      await categoryBox.add(category);
      debugPrint("✅ [addCategory] Category added: $name ($type) with icon: $icon");
      return true;
    } catch (e, st) {
      debugPrint("❌ [addCategory] Error: $e\n$st");
      return false;
    }
  }

  Future<bool> updateCategory(int key, Category newCategory) async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      await categoryBox.put(key, newCategory);
      debugPrint("✅ [updateCategory] Category updated: ${newCategory.name}");
      return true;
    } catch (e, st) {
      debugPrint("❌ [updateCategory] Error: $e\n$st");
      return false;
    }
  }

  Future<bool> deleteCategory(int key) async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      final category = categoryBox.get(key);

      if (category != null) {
        await categoryBox.delete(key);
        debugPrint("✅ [deleteCategory] Category deleted: ${category.name}");
        return true;
      }

      debugPrint("⚠️ [deleteCategory] Category not found for key: $key");
      return false;
    } catch (e, st) {
      debugPrint("❌ [deleteCategory] Error: $e\n$st");
      return false;
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      return categoryBox.values.toList();
    } catch (e, st) {
      debugPrint("❌ [getCategories] Error: $e\n$st");
      return [];
    }
  }

  /// Initialize default categories on first run
  Future<bool> initCategories() async {
    try {
      final categoryBox = Hive.box<Category>(AppConstants.categories);
      if (categoryBox.isEmpty) {
        debugPrint("📁 [initCategories] Initializing default categories...");

        final defaultCategories = [
          // ========== INCOME CATEGORIES ==========
          {'name': 'Salary', 'type': 'Income', 'color': Color(0xFF4CAF50), 'icon': 'work'},
          {'name': 'Freelance', 'type': 'Income', 'color': Color(0xFF8BC34A), 'icon': 'computer'},
          {'name': 'Business', 'type': 'Income', 'color': Color(0xFFCDDC39), 'icon': 'business_center'},
          {'name': 'Investments', 'type': 'Income', 'color': Color(0xFF689F38), 'icon': 'trending_up'},
          {'name': 'Dividends', 'type': 'Income', 'color': Color(0xFF33691E), 'icon': 'account_balance'},
          {'name': 'Rental Income', 'type': 'Income', 'color': Color(0xFF558B2F), 'icon': 'house'},
          {'name': 'Bonus', 'type': 'Income', 'color': Color(0xFF9CCC65), 'icon': 'celebration'},
          {'name': 'Gifts', 'type': 'Income', 'color': Color(0xFF7CB342), 'icon': 'card_giftcard'},
          {'name': 'Refunds', 'type': 'Income', 'color': Color(0xFFAED581), 'icon': 'assignment_return'},
          {'name': 'Side Hustle', 'type': 'Income', 'color': Color(0xFFC5E1A5), 'icon': 'directions_run'},

          // ========== EXPENSE CATEGORIES ==========

          // Food & Dining
          {'name': 'Groceries', 'type': 'Expense', 'color': Color(0xFFF44336), 'icon': 'shopping_cart'},
          {'name': 'Dining Out', 'type': 'Expense', 'color': Color(0xFFE53935), 'icon': 'restaurant'},
          {'name': 'Food Delivery', 'type': 'Expense', 'color': Color(0xFFD32F2F), 'icon': 'delivery_dining'},
          {'name': 'Coffee/Tea', 'type': 'Expense', 'color': Color(0xFFC62828), 'icon': 'local_cafe'},
          {'name': 'Snacks', 'type': 'Expense', 'color': Color(0xFFB71C1C), 'icon': 'bakery_dining'},

          // Housing
          {'name': 'Rent', 'type': 'Expense', 'color': Color(0xFF2196F3), 'icon': 'home'},
          {'name': 'Mortgage', 'type': 'Expense', 'color': Color(0xFF1976D2), 'icon': 'real_estate_agent'},
          {'name': 'Electricity', 'type': 'Expense', 'color': Color(0xFF1565C0), 'icon': 'flash_on'},
          {'name': 'Water Bill', 'type': 'Expense', 'color': Color(0xFF0D47A1), 'icon': 'water_drop'},
          {'name': 'Internet', 'type': 'Expense', 'color': Color(0xFF1E88E5), 'icon': 'wifi'},
          {'name': 'Mobile Bill', 'type': 'Expense', 'color': Color(0xFF42A5F5), 'icon': 'smartphone'},
          {'name': 'Maintenance', 'type': 'Expense', 'color': Color(0xFF64B5F6), 'icon': 'handyman'},

          // Transportation
          {'name': 'Fuel', 'type': 'Expense', 'color': Color(0xFFFF9800), 'icon': 'local_gas_station'},
          {'name': 'Public Transport', 'type': 'Expense', 'color': Color(0xFFF57C00), 'icon': 'directions_bus'},
          {'name': 'Taxi/Ride Share', 'type': 'Expense', 'color': Color(0xFFEF6C00), 'icon': 'local_taxi'},
          {'name': 'Car Insurance', 'type': 'Expense', 'color': Color(0xFFE65100), 'icon': 'car_rental'},
          {'name': 'Car Maintenance', 'type': 'Expense', 'color': Color(0xFFFFB74D), 'icon': 'build'},
          {'name': 'Parking', 'type': 'Expense', 'color': Color(0xFFFFA726), 'icon': 'local_parking'},

          // Shopping
          {'name': 'Clothing', 'type': 'Expense', 'color': Color(0xFF9C27B0), 'icon': 'checkroom'},
          {'name': 'Electronics', 'type': 'Expense', 'color': Color(0xFF8E24AA), 'icon': 'devices'},
          {'name': 'Personal Care', 'type': 'Expense', 'color': Color(0xFF7B1FA2), 'icon': 'spa'},
          {'name': 'Home Supplies', 'type': 'Expense', 'color': Color(0xFF6A1B9A), 'icon': 'chair'},
          {'name': 'Gifts', 'type': 'Expense', 'color': Color(0xFF4A148C), 'icon': 'card_giftcard'},

          // Entertainment & Leisure
          {'name': 'Movies', 'type': 'Expense', 'color': Color(0xFFE91E63), 'icon': 'movie'},
          {'name': 'Streaming Services', 'type': 'Expense', 'color': Color(0xFFD81B60), 'icon': 'live_tv'},
          {'name': 'Hobbies', 'type': 'Expense', 'color': Color(0xFFC2185B), 'icon': 'palette'},
          {'name': 'Sports', 'type': 'Expense', 'color': Color(0xFFAD1457), 'icon': 'sports_soccer'},
          {'name': 'Games', 'type': 'Expense', 'color': Color(0xFF880E4F), 'icon': 'sports_esports'},
          {'name': 'Books', 'type': 'Expense', 'color': Color(0xFFEC407A), 'icon': 'menu_book'},

          // Health & Fitness
          {'name': 'Healthcare', 'type': 'Expense', 'color': Color(0xFF00BCD4), 'icon': 'local_hospital'},
          {'name': 'Medicines', 'type': 'Expense', 'color': Color(0xFF00ACC1), 'icon': 'medication'},
          {'name': 'Gym/Fitness', 'type': 'Expense', 'color': Color(0xFF0097A7), 'icon': 'fitness_center'},
          {'name': 'Insurance', 'type': 'Expense', 'color': Color(0xFF00838F), 'icon': 'health_and_safety'},
          {'name': 'Doctor Visits', 'type': 'Expense', 'color': Color(0xFF006064), 'icon': 'medical_services'},

          // Education
          {'name': 'Tuition Fees', 'type': 'Expense', 'color': Color(0xFF673AB7), 'icon': 'school'},
          {'name': 'Books & Supplies', 'type': 'Expense', 'color': Color(0xFF5E35B1), 'icon': 'book'},
          {'name': 'Courses', 'type': 'Expense', 'color': Color(0xFF512DA8), 'icon': 'cast_for_education'},
          {'name': 'Online Learning', 'type': 'Expense', 'color': Color(0xFF4527A0), 'icon': 'computer'},

          // Travel
          {'name': 'Flights', 'type': 'Expense', 'color': Color(0xFF795548), 'icon': 'flight'},
          {'name': 'Hotels', 'type': 'Expense', 'color': Color(0xFF6D4C41), 'icon': 'hotel'},
          {'name': 'Vacation', 'type': 'Expense', 'color': Color(0xFF5D4037), 'icon': 'beach_access'},
          {'name': 'Travel Insurance', 'type': 'Expense', 'color': Color(0xFF4E342E), 'icon': 'travel_explore'},

          // Financial
          {'name': 'Loan Payment', 'type': 'Expense', 'color': Color(0xFF607D8B), 'icon': 'account_balance'},
          {'name': 'Credit Card', 'type': 'Expense', 'color': Color(0xFF546E7A), 'icon': 'credit_card'},
          {'name': 'Taxes', 'type': 'Expense', 'color': Color(0xFF455A64), 'icon': 'receipt_long'},
          {'name': 'Bank Fees', 'type': 'Expense', 'color': Color(0xFF37474F), 'icon': 'payments'},

          // Personal & Miscellaneous
          {'name': 'Donations', 'type': 'Expense', 'color': Color(0xFF009688), 'icon': 'volunteer_activism'},
          {'name': 'Pet Care', 'type': 'Expense', 'color': Color(0xFF00897B), 'icon': 'pets'},
          {'name': 'Childcare', 'type': 'Expense', 'color': Color(0xFF00796B), 'icon': 'child_friendly'},
          {'name': 'Subscriptions', 'type': 'Expense', 'color': Color(0xFF00695C), 'icon': 'subscriptions'},
          {'name': 'Repairs', 'type': 'Expense', 'color': Color(0xFF004D40), 'icon': 'construction'},

          // General
          {'name': 'Other', 'type': 'Expense', 'color': Color(0xFF9E9E9E), 'icon': 'category'},
          {'name': 'Miscellaneous', 'type': 'Expense', 'color': Color(0xFF757575), 'icon': 'more_horiz'},
          {'name': 'Emergency', 'type': 'Expense', 'color': Color(0xFF616161), 'icon': 'warning'},
        ];

        // Add categories in batches to avoid overwhelming the system
        for (int i = 0; i < defaultCategories.length; i++) {
          final category = defaultCategories[i];
          await addCategory(
            category['name'] as String,
            category['type'] as String,
            category['color'] as Color,
            category['icon'] as String,
          );

          // Small delay to prevent overwhelming the database
          if (i % 10 == 0) {
            await Future.delayed(Duration(milliseconds: 10));
          }
        }

        debugPrint("✅ [initCategories] ${defaultCategories.length} default categories initialized");
      } else {
        debugPrint("ℹ️ [initCategories] Categories already exist, skipping initialization");
      }
      return true;
    } catch (e, st) {
      debugPrint("❌ [initCategories] Error: $e\n$st");
      return false;
    }
  }

  /// Get total balance across all wallets
  Future<double> getTotalBalance() async {
    try {
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);
      final total = walletBox.values.fold(0.0, (sum, wallet) => sum + wallet.balance);
      debugPrint("💰 [getTotalBalance] Total balance: $total");
      return total;
    } catch (e, st) {
      debugPrint("❌ [getTotalBalance] Error: $e\n$st");
      return 0.0;
    }
  }

  /// Get wallet by type/method
  Future<Wallet?> getWalletByType(String type) async {
    try {
      final walletBox = Hive.box<Wallet>(AppConstants.wallets);
      final normalizedType = type.trim().toLowerCase();

      final wallet = walletBox.values.firstWhere(
            (w) => w.type.toLowerCase() == normalizedType,
      );

      return wallet;
    } catch (_) {
      debugPrint("⚠️ [getWalletByType] Wallet not found for type: $type");
      return null;
    }
  }

  /// Create wallet if it doesn't exist
  Future<bool> ensureWalletExists(String type, {double initialBalance = 0}) async {
    try {
      final wallet = await getWalletByType(type);
      if (wallet != null) return true;

      final walletBox = Hive.box<Wallet>(AppConstants.wallets);
      final newWallet = Wallet(
        name: type,
        balance: initialBalance,
        updatedAt: DateTime.now(),
        type: type,
        createdAt: DateTime.now(),
      );

      await walletBox.add(newWallet);
      debugPrint("✅ [ensureWalletExists] Created wallet: $type");
      return true;
    } catch (e, st) {
      debugPrint("❌ [ensureWalletExists] Error: $e\n$st");
      return false;
    }
  }

  /// Atomic operation: Mark habit as completed, with optional auto-transaction creation
  /// Checks for recent matching expense/income within 5 minutes; adds if missing
  Future<bool> markHabitComplete(dynamic habitKey, Habit habit) async {
    debugPrint("✅ [markHabitComplete] Starting atomic completion for habit: ${habit.name}");
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final categoryBox = Hive.box<Category>(AppConstants.categories);

    Habit? originalHabit;
    bool transactionAdded = false;
    try {
      // Step 1: Save original habit state
      originalHabit = habitBox.get(habitKey);
      if (originalHabit == null) {
        debugPrint("❌ [markHabitComplete] Habit not found for key: $habitKey");
        return false;
      }

      // Step 2: Mark habit as completed
      final wasCompleted = habit.isCompletedToday();
      habit.markCompleted();
      await habitBox.put(habitKey, habit);
      debugPrint("📅 [markHabitComplete] Habit marked completed: ${habit.name} (streak: ${habit.streakCount})");

      if (wasCompleted) {
        debugPrint("ℹ️ [markHabitComplete] Habit already completed today, skipping transaction check");
        return true;
      }

      // Step 3: Determine if expense or income based on type or categories
      bool isExpense = habit.type.toLowerCase() == 'expense';
      bool isIncome = habit.type.toLowerCase() == 'income';
      if (!isExpense && !isIncome) {
        // Check categories
        final habitCategories = habit.categoryKeys
            .map((k) => categoryBox.get(k))
            .whereType<Category>()
            .toList();
        isExpense = habitCategories.any((cat) => cat.type.toLowerCase() == 'expense');
        isIncome = habitCategories.any((cat) => cat.type.toLowerCase() == 'income');
      }

      if (!isExpense && !isIncome) {
        debugPrint("ℹ️ [markHabitComplete] Habit has no expense/income categories, no transaction added");
        return true;
      }

      // Step 4: Check for recent matching transaction (within 5 minutes)
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final matchingDescription = '${habit.name} (Habit)';
      bool hasRecentTransaction = false;

      if (isExpense) {
        hasRecentTransaction = expenseBox.values.any((e) =>
        e.date.isAfter(fiveMinAgo) &&
            e.categoryKeys.any((k) => habit.categoryKeys.contains(k)) &&
            e.description.contains(habit.name));
      } else if (isIncome) {
        hasRecentTransaction = incomeBox.values.any((i) =>
        i.date.isAfter(fiveMinAgo) &&
            i.categoryKeys.any((k) => habit.categoryKeys.contains(k)) &&
            i.description.contains(habit.name));
      }

      // Step 5: Add transaction if missing
      if (!hasRecentTransaction && habit.targetAmount != null && habit.targetAmount! > 0) {
        final amount = habit.targetAmount!;
        final method = 'UPI';  // Default method for auto-habits
        final desc = matchingDescription;

        if (isExpense) {
          transactionAdded = await addExpense(
            amount: amount,
            description: desc,
            method: method,
            categoryKeys: habit.categoryKeys,
            date: DateTime.now(),
          );
        } else if (isIncome) {
          transactionAdded = await addIncome(
            amount: amount,
            description: desc,
            method: method,
            categoryKeys: habit.categoryKeys,
            date: DateTime.now(),
          );
        }

        if (transactionAdded) {
          debugPrint("💳 [markHabitComplete] Auto-added ${isExpense ? 'expense' : 'income'}: $amount for ${habit.name}");
        } else {
          debugPrint("⚠️ [markHabitComplete] Failed to auto-add transaction for ${habit.name}");
        }
      } else if (hasRecentTransaction) {
        debugPrint("ℹ️ [markHabitComplete] Recent transaction found, skipping auto-add for ${habit.name}");
      }

      // Notify about habit streak
      await NotificationHelper.notifyHabitStreak(habit.name, habit.streakCount);

      return true;
    } catch (e, st) {
      debugPrint("❌ [markHabitComplete] Atomic operation failed: $e\n$st");
      // Rollback: Restore original completion state
      await _rollbackHabitComplete(habitBox, habitKey, originalHabit);
      return false;
    }
  }

  /// Rollback for failed habit completion
  Future<void> _rollbackHabitComplete(Box<Habit> habitBox, dynamic habitKey, Habit? originalHabit) async {
    try {
      if (originalHabit != null) {
        // Restore original completionHistory (remove today's entry if added)
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        originalHabit.completionHistory.removeWhere((date) => date.isAtSameMomentAs(today));
        originalHabit.lastCompletedAt = originalHabit.completionHistory.isNotEmpty
            ? originalHabit.completionHistory.last
            : null;
        originalHabit.streakCount = 0;  // Reset streak on rollback
        await habitBox.put(habitKey, originalHabit);
        debugPrint("↩️ [rollback] Restored original habit state");
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during habit completion rollback: $e");
    }
  }

  /// Atomic operation: Unmark habit as completed today, with optional auto-transaction removal
  Future<bool> unmarkHabitComplete(dynamic habitKey, Habit habit) async {
    debugPrint("↩️ [unmarkHabitComplete] Starting atomic unmark for habit: ${habit.name}");
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final categoryBox = Hive.box<Category>(AppConstants.categories);

    Habit? originalHabit;
    int? removedTransactionKey;
    bool wasExpense = false;
    bool wasIncome = false;
    try {
      // Step 1: Save original habit state
      originalHabit = habitBox.get(habitKey);
      if (originalHabit == null) {
        debugPrint("❌ [unmarkHabitComplete] Habit not found for key: $habitKey");
        return false;
      }

      if (!habit.isCompletedToday()) {
        debugPrint("ℹ️ [unmarkHabitComplete] Habit not completed today, nothing to unmark");
        return true;
      }

      // Step 2: Unmark habit (remove today's completion)
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      habit.completionHistory.removeWhere((date) => date.isAtSameMomentAs(today));
      habit.lastCompletedAt = habit.completionHistory.isNotEmpty ? habit.completionHistory.last : null;
      // Recalculate streak (simplified; call _updateStreak if available)
      habit.streakCount = 0;  // Reset on unmark
      await habitBox.put(habitKey, habit);
      debugPrint("📅 [unmarkHabitComplete] Habit unmarked: ${habit.name}");

      // Step 3: Determine type and find recent matching transaction (within 5 minutes)
      bool isExpense = habit.type.toLowerCase() == 'expense';
      bool isIncome = habit.type.toLowerCase() == 'income';
      if (!isExpense && !isIncome) {
        final habitCategories = habit.categoryKeys
            .map((k) => categoryBox.get(k))
            .whereType<Category>()
            .toList();
        isExpense = habitCategories.any((cat) => cat.type.toLowerCase() == 'expense');
        isIncome = habitCategories.any((cat) => cat.type.toLowerCase() == 'income');
      }

      if (isExpense || isIncome) {
        final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
        final matchingDescription = '${habit.name} (Habit)';
        dynamic matchingTransaction;

        if (isExpense) {
          try {
            matchingTransaction = expenseBox.values.firstWhere(
                  (e) => e.date.isAfter(fiveMinAgo) &&
                  e.categoryKeys.any((k) => habit.categoryKeys.contains(k)) &&
                  e.description == matchingDescription,
            );
          } catch (_) {
            matchingTransaction = null;
          }
          wasExpense = true;
        } else if (isIncome) {
          try {
            matchingTransaction = incomeBox.values.firstWhere(
                  (i) => i.date.isAfter(fiveMinAgo) &&
                  i.categoryKeys.any((k) => habit.categoryKeys.contains(k)) &&
                  i.description == matchingDescription,
            );
          } catch (_) {
            matchingTransaction = null;
          }
          wasIncome = true;
        }

        // Step 4: Remove matching transaction if found (assume auto-added)
        if (matchingTransaction != null) {
          if (wasExpense) {
            removedTransactionKey = expenseBox.keyAt(expenseBox.values.toList().indexOf(matchingTransaction as Expense));
            await deleteExpense(removedTransactionKey!);
          } else if (wasIncome) {
            removedTransactionKey = incomeBox.keyAt(incomeBox.values.toList().indexOf(matchingTransaction as Income));
            await deleteIncome(removedTransactionKey!, 'Habit');
          }
          debugPrint("🗑️ [unmarkHabitComplete] Removed auto-transaction for ${habit.name}");
        } else {
          debugPrint("ℹ️ [unmarkHabitComplete] No matching transaction found to remove for ${habit.name}");
        }
      }

      return true;
    } catch (e, st) {
      debugPrint("❌ [unmarkHabitComplete] Atomic operation failed: $e\n$st");
      // Rollback: Remark as completed
      await _rollbackUnmarkHabitComplete(habitBox, habitKey, originalHabit, removedTransactionKey, wasExpense, wasIncome);
      return false;
    }
  }

  /// Rollback for failed habit unmark
  Future<void> _rollbackUnmarkHabitComplete(
      Box<Habit> habitBox,
      dynamic habitKey,
      Habit? originalHabit,
      int? removedTransactionKey,
      bool wasExpense,
      bool wasIncome,
      ) async {
    try {
      // Restore original completion
      if (originalHabit != null) {
        await habitBox.put(habitKey, originalHabit);
        debugPrint("↩️ [rollback] Restored original habit completion state");
      }
      // Restore removed transaction if applicable
      if (removedTransactionKey != null) {
        if (wasExpense) {
          // Re-add expense (simplified; in real, you'd need full data)
          debugPrint("⚠️ [rollback] Transaction restore for expense not fully implemented; manual intervention may be needed");
        } else if (wasIncome) {
          // Similar for income
          debugPrint("⚠️ [rollback] Transaction restore for income not fully implemented; manual intervention may be needed");
        }
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during unmark rollback: $e");
    }
  }

  /// Atomic operation: Delete habit
  Future<bool> deleteHabit(dynamic habitKey) async {
    debugPrint("🗑️ [deleteHabit] Starting atomic deletion for habit key: $habitKey");
    final habitBox = Hive.box<Habit>(AppConstants.habits);
    try {
      final habit = habitBox.get(habitKey);
      if (habit == null) {
        debugPrint("❌ [deleteHabit] Habit not found for key: $habitKey");
        return false;
      }

      // Optional: Clean up recent auto-transactions (within 1 day, matching description)
      // This is cautious; adjust timeframe as needed
      final dayAgo = DateTime.now().subtract(const Duration(days: 1));
      final matchingDescription = '${habit.name} (Habit)';
      final expenseBox = Hive.box<Expense>(AppConstants.expenses);
      final incomeBox = Hive.box<Income>(AppConstants.incomes);

      // Find and delete matching expenses
      final matchingExpenses = expenseBox.values.where((e) =>
      e.date.isAfter(dayAgo) &&
          e.description == matchingDescription &&
          e.categoryKeys.any((k) => habit.categoryKeys.contains(k)));
      for (final expense in matchingExpenses) {
        final expenseKey = expenseBox.keyAt(expenseBox.values.toList().indexOf(expense));
        await deleteExpense(expenseKey);
        debugPrint("🗑️ [deleteHabit] Cleaned up auto-expense for ${habit.name}");
      }

      // Find and delete matching incomes
      final matchingIncomes = incomeBox.values.where((i) =>
      i.date.isAfter(dayAgo) &&
          i.description == matchingDescription &&
          i.categoryKeys.any((k) => habit.categoryKeys.contains(k)));
      for (final income in matchingIncomes) {
        final incomeKey = incomeBox.keyAt(incomeBox.values.toList().indexOf(income));
        await deleteIncome(incomeKey, 'Habit');
        debugPrint("🗑️ [deleteHabit] Cleaned up auto-income for ${habit.name}");
      }

      // Delete habit
      await habitBox.delete(habitKey);
      debugPrint("✅ [deleteHabit] Habit deleted: ${habit.name}");
      return true;
    } catch (e, st) {
      debugPrint("❌ [deleteHabit] Atomic deletion failed: $e\n$st");
      return false;
    }
  }

  // Helper function to convert icon string to code
  int getIconCode(String iconName) {
    final iconMap = {
      'shopping_cart': 0xe8cc,
      'restaurant': 0xe56c,
      'local_cafe': 0xe541,
      'home': 0xe88a,
      'local_gas_station': 0xe565,
      'directions_bus': 0xe530,
      'checkroom': 0xe11b,
      'devices': 0xe337,
      'movie': 0xe02c,
      'local_hospital': 0xe548,
      'school': 0xe80c,
      'flight': 0xe539,
      'credit_card': 0xe8a1,
      'pets': 0xe91d,
      'category': 0xe574,
      'work': 0xe8f9,
      'computer': 0xe30a,
      'business_center': 0xeb3f,
      'trending_up': 0xe8e5,
      'account_balance': 0xe84f,
      'house': 0xea44,
      'celebration': 0xea65,
      'card_giftcard': 0xe8f6,
      'assignment_return': 0xe8b7,
      'directions_run': 0xe566,
      'flash_on': 0xe3e7,
      'water_drop': 0xe798,
      'wifi': 0xe63e,
      'smartphone': 0xe323,
      'handyman': 0xe10b,
      'build': 0xe869,
      'local_parking': 0xe54f,
      'spa': 0xeb4c,
      'chair': 0xefdc,
      'live_tv': 0xe639,
      'palette': 0xe40a,
      'sports_soccer': 0xea2d,
      'sports_esports': 0xea38,
      'menu_book': 0xe614,
      'medication': 0xf109,
      'fitness_center': 0xeb43,
      'health_and_safety': 0xe1d5,
      'medical_services': 0xf0fa,
      'book': 0xe865,
      'cast_for_education': 0xe8ec,
      'hotel': 0xe53a,
      'beach_access': 0xeb3e,
      'travel_explore': 0xe2db,
      'receipt_long': 0xef6e,
      'payments': 0xe8a2,
      'volunteer_activism': 0xea70,
      'child_friendly': 0xeb41,
      'subscriptions': 0xf1fc,
      'construction': 0xe85d,
      'more_horiz': 0xe5d3,
      'warning': 0xe002,
    };

    return iconMap[iconName] ?? 0xe574; // Default to 'category' icon if not found
  }


}