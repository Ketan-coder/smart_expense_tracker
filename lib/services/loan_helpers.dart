import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import '../data/model/loan.dart';
import '../data/model/wallet.dart';
import '../services/loan_service.dart';
import '../../core/app_constants.dart';

/// Helper functions for loan management
class LoanHelpers {

  // ===== Formatting Helpers =====

  /// Format amount with currency
  static String formatAmount(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Format amount short (no decimals for large numbers)
  static String formatAmountShort(double amount, String currency) {
    if (amount >= 1000000) {
      return '$currency ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$currency ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$currency ${amount.toStringAsFixed(0)}';
  }

  /// Format date
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format relative date
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';
    if (diff < 365) return '${(diff / 30).floor()} months ago';
    return '${(diff / 365).floor()} years ago';
  }

  /// Format due date relative
  static String formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;

    if (diff < 0) return 'Overdue by ${-diff} days';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff < 7) return 'Due in $diff days';
    if (diff < 30) return 'Due in ${(diff / 7).floor()} weeks';
    return 'Due on ${formatDate(dueDate)}';
  }

  // ===== UI Helpers =====

  /// Get status color
  static Color getStatusColor(Loan loan) {
    if (loan.isPaid) return Colors.green;
    if (loan.isOverdue) return Colors.red;
    if (loan.isDueSoon) return Colors.orange;
    if (loan.paidAmount > 0) return Colors.blue;
    return Colors.grey;
  }

  /// Get type color
  static Color getTypeColor(LoanType type) {
    return type == LoanType.lent ? Colors.green : Colors.red;
  }

  /// Get status icon
  static IconData getStatusIcon(Loan loan) {
    if (loan.isPaid) return Icons.check_circle;
    if (loan.isOverdue) return Icons.error;
    if (loan.isDueSoon) return Icons.warning;
    if (loan.paidAmount > 0) return Icons.sync;
    return Icons.schedule;
  }

  /// Get type icon
  static IconData getTypeIcon(LoanType type) {
    return type == LoanType.lent
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  }

  /// Get progress color
  static Color getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.orange;
    if (progress >= 0.25) return Colors.deepOrange;
    return Colors.red;
  }

  // ===== Summary Helpers =====

  /// Get loan summary text
  static String getSummaryText(Map<String, dynamic> stats, String currency) {
    final pendingToReceive = stats['pendingToReceive'] as double;
    final pendingToPay = stats['pendingToPay'] as double;

    if (pendingToReceive > pendingToPay) {
      return 'You\'ll receive ${formatAmountShort(pendingToReceive - pendingToPay, currency)} net';
    } else if (pendingToPay > pendingToReceive) {
      return 'You\'ll pay ${formatAmountShort(pendingToPay - pendingToReceive, currency)} net';
    }
    return 'All settled!';
  }

  /// Get priority loans (most urgent)
  static List<Loan> getPriorityLoans({int limit = 5}) {
    final service = LoanService();
    final loans = service.getActiveLoans();

    // Sort by priority: overdue first, then due soon, then by remaining amount
    loans.sort((a, b) {
      // Overdue loans first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      // Then due soon
      if (a.isDueSoon && !b.isDueSoon) return -1;
      if (!a.isDueSoon && b.isDueSoon) return 1;

      // Then by days until due
      final aDays = a.daysUntilDue;
      final bDays = b.daysUntilDue;
      if (aDays >= 0 && bDays >= 0) {
        return aDays.compareTo(bDays);
      }

      // Finally by remaining amount (larger first)
      return b.remainingAmount.compareTo(a.remainingAmount);
    });

    return loans.take(limit).toList();
  }

  /// Get loans grouped by person
  static Map<String, List<Loan>> getLoansByPerson() {
    final loans = LoanService().getAllLoans();
    final grouped = <String, List<Loan>>{};

    for (var loan in loans) {
      grouped.putIfAbsent(loan.personName, () => []);
      grouped[loan.personName]!.add(loan);
    }

    return grouped;
  }

  /// Calculate total with person
  static Map<String, double> getBalanceByPerson() {
    final grouped = getLoansByPerson();
    final balances = <String, double>{};

    for (var entry in grouped.entries) {
      double balance = 0;
      for (var loan in entry.value) {
        if (loan.type == LoanType.lent) {
          balance += loan.remainingAmount;
        } else {
          balance -= loan.remainingAmount;
        }
      }
      if (balance != 0) {
        balances[entry.key] = balance;
      }
    }

    return balances;
  }

  // ===== Validation Helpers =====

  /// Validate loan input
  static String? validateLoanInput({
    required String personName,
    required String amount,
  }) {
    if (personName.trim().isEmpty) {
      return 'Please enter person name';
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      return 'Please enter a valid amount';
    }

    return null; // Valid
  }

  /// Validate payment input
  static String? validatePaymentInput({
    required String amount,
    required double maxAmount,
  }) {
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      return 'Please enter a valid amount';
    }

    if (amountValue > maxAmount) {
      return 'Amount cannot exceed ${maxAmount.toStringAsFixed(2)}';
    }

    return null; // Valid
  }

  // ===== Notification Helpers =====

  /// Get notification title for loan
  static String getNotificationTitle(Loan loan) {
    if (loan.isOverdue) {
      return loan.type == LoanType.lent
          ? '🚨 Overdue: Collect from ${loan.personName}'
          : '🚨 Overdue: Pay ${loan.personName}';
    }
    if (loan.isDueSoon) {
      return loan.type == LoanType.lent
          ? '⏰ Reminder: ${loan.personName} owes you'
          : '⏰ Reminder: Pay ${loan.personName}';
    }
    return loan.type == LoanType.lent
        ? '💰 Loan to ${loan.personName}'
        : '💵 Loan from ${loan.personName}';
  }

  /// Get notification body for loan
  static String getNotificationBody(Loan loan, String currency) {
    final amount = formatAmount(loan.remainingAmount, currency);

    if (loan.isOverdue) {
      return '$amount is ${loan.daysOverdue} days overdue!';
    }
    if (loan.isDueSoon) {
      return '$amount due in ${loan.daysUntilDue} days';
    }
    return '$amount remaining';
  }

  // ===== Quick Stats =====

  /// Get quick stats for dashboard
  static Map<String, dynamic> getQuickStats(String currency) {
    final stats = LoanService().getStatistics();

    return {
      'toReceive': formatAmountShort(stats['pendingToReceive'], currency),
      'toPay': formatAmountShort(stats['pendingToPay'], currency),
      'overdueCount': stats['overdueCount'],
      'dueSoonCount': stats['dueSoonCount'],
      'activeCount': stats['activeLoans'],
    };
  }

  // ===== ATOMIC LOAN OPERATIONS =====

  /// Atomic operation: Add loan with automatic transaction creation and rollback
  static Future<bool> addLoanAtomic({
    required String personName,
    required String description,
    required double amount,
    required LoanType type,
    required String method,
    required List<int> categoryKeys,
    DateTime? dueDate,
    DateTime? date,
    String? phoneNumber,
    bool reminderEnabled = true,
    int reminderDaysBefore = 3,
  }) async {
    debugPrint("💰 [addLoanAtomic] Starting atomic loan operation...");

    // Validate inputs
    if (amount <= 0) {
      debugPrint("❌ [addLoanAtomic] Invalid amount: $amount");
      return false;
    }
    if (personName.trim().isEmpty) {
      debugPrint("❌ [addLoanAtomic] Person name cannot be empty");
      return false;
    }
    if (method.trim().isEmpty) {
      debugPrint("❌ [addLoanAtomic] Method cannot be empty");
      return false;
    }

    final loanBox = Hive.box<Loan>(AppConstants.loans);
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Loan? savedLoan;
    Expense? createdExpense;
    Income? createdIncome;
    Wallet? affectedWallet;
    double originalBalance = 0;
    int? walletKey;

    try {
      // Step 1: Create loan object
      final loan = Loan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        personName: personName.trim(),
        description: description.trim(),
        amount: amount,
        date: date ?? DateTime.now(),
        dueDate: dueDate,
        type: type,
        status: LoanStatus.pending,
        paidAmount: 0,
        method: method.trim(),
        categoryKeys: categoryKeys,
        phoneNumber: phoneNumber,
        reminderEnabled: reminderEnabled,
        reminderDaysBefore: reminderDaysBefore,
      );

      // Step 2: Find or create wallet
      final normalizedMethod = method.trim().toLowerCase();
      try {
        affectedWallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == normalizedMethod,
        );
        originalBalance = affectedWallet.balance;
        walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(affectedWallet));
        debugPrint("💼 [addLoanAtomic] Found existing wallet: ${affectedWallet.name} (key: $walletKey)");
      } catch (_) {
        // Create new wallet
        affectedWallet = Wallet(
          name: method.trim(),
          balance: 0,
          updatedAt: DateTime.now(),
          type: method.trim(),
          createdAt: DateTime.now(),
        );
        debugPrint("🆕 [addLoanAtomic] Creating new wallet: ${affectedWallet.name}");
      }

      // Step 3: Update wallet balance based on loan type
      if (type == LoanType.lent) {
        // Money going out - decrease wallet balance
        affectedWallet.balance -= amount;
        debugPrint("💸 [addLoanAtomic] Lent money - decreasing wallet balance");
      } else {
        // Money coming in - increase wallet balance
        affectedWallet.balance += amount;
        debugPrint("💵 [addLoanAtomic] Borrowed money - increasing wallet balance");
      }
      affectedWallet.updatedAt = DateTime.now();

      // Step 4: Save wallet appropriately
      if (walletKey != null) {
        await affectedWallet.save();
        debugPrint("💵 [addLoanAtomic] Wallet updated: ${affectedWallet.name} → Balance: ${affectedWallet.balance}");
      } else {
        walletKey = await walletBox.add(affectedWallet);
        debugPrint("💵 [addLoanAtomic] New wallet created: ${affectedWallet.name} → Balance: ${affectedWallet.balance} (key: $walletKey)");
      }

      // Step 5: Create corresponding transaction (expense for lent, income for borrowed)
      final transactionDescription = type == LoanType.lent
          ? 'Lent to $personName: $description'
          : 'Borrowed from $personName: $description';

      if (type == LoanType.lent) {
        // Create expense for lent money
        final expense = Expense(
          amount: amount,
          date: date ?? DateTime.now(),
          description: transactionDescription,
          categoryKeys: categoryKeys,
          method: method.trim(),
        );
        final expenseKey = await expenseBox.add(expense);
        createdExpense = expense;
        debugPrint("🧾 [addLoanAtomic] Expense created for lent money (key: $expenseKey)");
      } else {
        // Create income for borrowed money
        final income = Income(
          amount: amount,
          date: date ?? DateTime.now(),
          description: transactionDescription,
          categoryKeys: categoryKeys,
        );
        final incomeKey = await incomeBox.add(income);
        createdIncome = income;
        debugPrint("🧾 [addLoanAtomic] Income created for borrowed money (key: $incomeKey)");
      }

      // Step 6: Save loan
      final loanKey = await loanBox.add(loan);
      savedLoan = loan;
      debugPrint("✅ [addLoanAtomic] Loan added successfully: $loan (key: $loanKey)");

      return true;

    } catch (e, st) {
      debugPrint("❌ [addLoanAtomic] Atomic operation failed: $e\n$st");

      // Rollback logic
      await _rollbackLoanAdd(
          loanBox, expenseBox, incomeBox, walletBox,
          savedLoan, createdExpense, createdIncome, affectedWallet, originalBalance
      );

      return false;
    }
  }

  /// Rollback for failed loan addition
  static Future<void> _rollbackLoanAdd(
      Box<Loan> loanBox,
      Box<Expense> expenseBox,
      Box<Income> incomeBox,
      Box<Wallet> walletBox,
      Loan? savedLoan,
      Expense? createdExpense,
      Income? createdIncome,
      Wallet? affectedWallet,
      double originalBalance,
      ) async {
    try {
      // Remove saved loan if any
      if (savedLoan != null) {
        final loanKey = loanBox.keyAt(loanBox.values.toList().indexOf(savedLoan));
        await loanBox.delete(loanKey);
        debugPrint("↩️ [rollback] Removed loan");
      }

      // Remove created expense if any
      if (createdExpense != null) {
        final expenseKey = expenseBox.keyAt(expenseBox.values.toList().indexOf(createdExpense));
        await expenseBox.delete(expenseKey);
        debugPrint("↩️ [rollback] Removed expense");
      }

      // Remove created income if any
      if (createdIncome != null) {
        final incomeKey = incomeBox.keyAt(incomeBox.values.toList().indexOf(createdIncome));
        await incomeBox.delete(incomeKey);
        debugPrint("↩️ [rollback] Removed income");
      }

      // Restore original wallet balance
      if (affectedWallet != null) {
        affectedWallet.balance = originalBalance;
        affectedWallet.updatedAt = DateTime.now();
        await affectedWallet.save();
        debugPrint("↩️ [rollback] Restored wallet balance: $originalBalance");
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during loan rollback: $e");
    }
  }

  /// Atomic operation: Add payment to loan with transaction creation and rollback
  static Future<bool> addPaymentAtomic({
    required String loanId,
    required double amount,
    required String method,
    String? note,
    DateTime? date,
  }) async {
    debugPrint("💰 [addPaymentAtomic] Starting atomic payment operation...");

    if (amount <= 0) {
      debugPrint("❌ [addPaymentAtomic] Invalid amount: $amount");
      return false;
    }
    if (method.trim().isEmpty) {
      debugPrint("❌ [addPaymentAtomic] Method cannot be empty");
      return false;
    }

    final loanBox = Hive.box<Loan>(AppConstants.loans);
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    Loan? originalLoan;
    Expense? createdExpense;
    Income? createdIncome;
    Wallet? affectedWallet;
    double originalBalance = 0;
    int? walletKey;

    try {
      // Step 1: Find loan
      final loan = loanBox.values.firstWhere(
            (l) => l.id == loanId,
        orElse: () => throw Exception("Loan not found"),
      );
      originalLoan = _copyLoan(loan);

      if (loan.isPaid) {
        debugPrint("⚠️ [addPaymentAtomic] Loan is already fully paid");
        return false;
      }

      if (amount > loan.remainingAmount) {
        debugPrint("❌ [addPaymentAtomic] Payment amount ($amount) exceeds remaining amount (${loan.remainingAmount})");
        return false;
      }

      // Step 2: Find or create wallet
      final normalizedMethod = method.trim().toLowerCase();
      try {
        affectedWallet = walletBox.values.firstWhere(
              (w) => w.type.toLowerCase() == normalizedMethod,
        );
        originalBalance = affectedWallet.balance;
        walletKey = walletBox.keyAt(walletBox.values.toList().indexOf(affectedWallet));
        debugPrint("💼 [addPaymentAtomic] Found existing wallet: ${affectedWallet.name}");
      } catch (_) {
        affectedWallet = Wallet(
          name: method.trim(),
          balance: 0,
          updatedAt: DateTime.now(),
          type: method.trim(),
          createdAt: DateTime.now(),
        );
        debugPrint("🆕 [addPaymentAtomic] Creating new wallet: ${affectedWallet.name}");
      }

      // Step 3: Update wallet balance based on loan type
      if (loan.type == LoanType.lent) {
        // Receiving payment back - increase wallet balance
        affectedWallet.balance += amount;
        debugPrint("💵 [addPaymentAtomic] Receiving payment for lent money - increasing wallet balance");
      } else {
        // Paying back borrowed money - decrease wallet balance
        affectedWallet.balance -= amount;
        debugPrint("💸 [addPaymentAtomic] Paying back borrowed money - decreasing wallet balance");
      }
      affectedWallet.updatedAt = DateTime.now();

      // Step 4: Save wallet
      if (walletKey != null) {
        await affectedWallet.save();
      } else {
        await walletBox.add(affectedWallet);
      }
      debugPrint("💵 [addPaymentAtomic] Wallet updated: ${affectedWallet.name} → Balance: ${affectedWallet.balance}");

      // Step 5: Create corresponding transaction
      final paymentNote = note?.isNotEmpty == true ? " - $note" : "";
      final transactionDescription = loan.type == LoanType.lent
          ? 'Payment received from ${loan.personName}$paymentNote'
          : 'Payment made to ${loan.personName}$paymentNote';

      if (loan.type == LoanType.lent) {
        // Create income for received payment
        final income = Income(
          amount: amount,
          date: date ?? DateTime.now(),
          description: transactionDescription,
          categoryKeys: loan.categoryKeys,
        );
        final incomeKey = await incomeBox.add(income);
        createdIncome = income;
        debugPrint("🧾 [addPaymentAtomic] Income created for received payment (key: $incomeKey)");
      } else {
        // Create expense for made payment
        final expense = Expense(
          amount: amount,
          date: date ?? DateTime.now(),
          description: transactionDescription,
          categoryKeys: loan.categoryKeys,
          method: method.trim(),
        );
        final expenseKey = await expenseBox.add(expense);
        createdExpense = expense;
        debugPrint("🧾 [addPaymentAtomic] Expense created for made payment (key: $expenseKey)");
      }

      // Step 6: Create payment object
      final payment = LoanPayment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: date ?? DateTime.now(),
        note: note,
        method: method.trim(),
      );

      // Step 7: Update loan with payment
      final updatedLoan = loan.addPayment(payment);
      final loanKey = loanBox.keyAt(loanBox.values.toList().indexOf(loan));
      await loanBox.put(loanKey, updatedLoan);

      debugPrint("✅ [addPaymentAtomic] Loan updated: Paid: ${updatedLoan.paidAmount}, Remaining: ${updatedLoan.remainingAmount}");

      return true;

    } catch (e, st) {
      debugPrint("❌ [addPaymentAtomic] Atomic operation failed: $e\n$st");

      // Rollback logic
      await _rollbackPaymentAdd(
          loanBox, expenseBox, incomeBox, walletBox,
          originalLoan, createdExpense, createdIncome, affectedWallet, originalBalance
      );

      return false;
    }
  }

  /// Rollback for failed payment addition
  static Future<void> _rollbackPaymentAdd(
      Box<Loan> loanBox,
      Box<Expense> expenseBox,
      Box<Income> incomeBox,
      Box<Wallet> walletBox,
      Loan? originalLoan,
      Expense? createdExpense,
      Income? createdIncome,
      Wallet? affectedWallet,
      double originalBalance,
      ) async {
    try {
      // Restore original loan state
      if (originalLoan != null) {
        final loanKey = loanBox.keyAt(loanBox.values.toList().indexOf(originalLoan));
        await loanBox.put(loanKey, originalLoan);
        debugPrint("↩️ [rollback] Restored original loan state");
      }

      // Remove created expense if any
      if (createdExpense != null) {
        final expenseKey = expenseBox.keyAt(expenseBox.values.toList().indexOf(createdExpense));
        await expenseBox.delete(expenseKey);
        debugPrint("↩️ [rollback] Removed expense");
      }

      // Remove created income if any
      if (createdIncome != null) {
        final incomeKey = incomeBox.keyAt(incomeBox.values.toList().indexOf(createdIncome));
        await incomeBox.delete(incomeKey);
        debugPrint("↩️ [rollback] Removed income");
      }

      // Restore original wallet balance
      if (affectedWallet != null) {
        affectedWallet.balance = originalBalance;
        affectedWallet.updatedAt = DateTime.now();
        await affectedWallet.save();
        debugPrint("↩️ [rollback] Restored wallet balance: $originalBalance");
      }
    } catch (e) {
      debugPrint("⚠️ [rollback] Error during payment rollback: $e");
    }
  }

  /// Helper method to copy loan
  static Loan _copyLoan(Loan loan) {
    return Loan(
      id: loan.id,
      personName: loan.personName,
      description: loan.description,
      amount: loan.amount,
      date: loan.date,
      dueDate: loan.dueDate,
      type: loan.type,
      status: loan.status,
      paidAmount: loan.paidAmount,
      method: loan.method,
      categoryKeys: List.from(loan.categoryKeys),
      payments: List.from(loan.payments),
      phoneNumber: loan.phoneNumber,
      reminderEnabled: loan.reminderEnabled,
      reminderDaysBefore: loan.reminderDaysBefore,
    );
  }
}

/// Extension for Loan model
extension LoanExtension on Loan {
  /// Get color based on status
  Color get statusColor => LoanHelpers.getStatusColor(this);

  /// Get icon based on status
  IconData get statusIcon => LoanHelpers.getStatusIcon(this);

  /// Get formatted remaining amount
  String remainingFormatted(String currency) =>
      LoanHelpers.formatAmount(remainingAmount, currency);

  /// Get progress as percentage string
  String get progressPercentage => '${(progress * 100).toInt()}%';

  /// Get status text with emoji
  String get statusTextWithEmoji => '$statusEmoji $statusText';

  /// Get type text with icon indicator
  String get typeTextWithIndicator => type == LoanType.lent ? '⬆️ Lent' : '⬇️ Borrowed';
}