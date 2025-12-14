import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import '../data/model/expense.dart';
import '../data/model/income.dart';
import '../data/model/loan.dart';
import '../data/model/wallet.dart';
import '../services/loan_service.dart';
import '../../core/app_constants.dart';

/// Production-ready loan management helpers with proper transaction linking
class LoanHelpers {

  // ===== ATOMIC OPERATIONS WITH TRANSACTION LINKING =====

  /// Atomic operation: Add loan with linked transaction
  /// This ensures wallet, expense/income, and loan are all created/updated together
  static Future<bool> addLoanAtomic({
    required String creditorName,
    required String description,
    required double principalAmount,
    required LoanType type,
    required String method,
    required List<int> categoryKeys,
    DateTime? dueDate,
    DateTime? date,
    String? phoneNumber,
    bool reminderEnabled = true,
    int reminderDaysBefore = 3,
    // New fields
    LoanCreditorType creditorType = LoanCreditorType.person,
    double interestRate = 0,
    InterestType interestType = InterestType.none,
    int? tenureMonths,
    double? emiAmount,
    PaymentFrequency paymentFrequency = PaymentFrequency.monthly,
    String? accountNumber,
    String? referenceNumber,
    LoanPurpose? purpose,
    String? collateral,
    double? penaltyRate,
    DateTime? firstPaymentDate,
    bool autoDebitEnabled = false,
    String? notes,
  }) async {
    debugPrint("💰 [addLoanAtomic] Starting atomic loan operation...");

    // Validation
    if (principalAmount <= 0) {
      debugPrint("❌ Invalid amount: $principalAmount");
      return false;
    }
    if (creditorName.trim().isEmpty) {
      debugPrint("❌ Creditor name cannot be empty");
      return false;
    }

    final loanBox = Hive.box<Loan>(AppConstants.loans);
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    String? loanKey;
    int? transactionKey;
    Wallet? affectedWallet;
    double originalWalletBalance = 0;

    try {
      // Step 1: Find or create wallet
      affectedWallet = await _findOrCreateWallet(walletBox, method);
      originalWalletBalance = affectedWallet.balance;
      debugPrint("💼 Using wallet: ${affectedWallet.name} (Balance: ${affectedWallet.balance})");

      // Step 2: Create loan object
      final loanId = DateTime.now().millisecondsSinceEpoch.toString();
      final loan = Loan(
        id: loanId,
        creditorName: creditorName.trim(),
        description: description.trim(),
        principalAmount: principalAmount,
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
        creditorType: creditorType,
        interestRate: interestRate,
        interestType: interestType,
        tenureMonths: tenureMonths,
        emiAmount: emiAmount,
        paymentFrequency: paymentFrequency,
        accountNumber: accountNumber,
        referenceNumber: referenceNumber,
        purpose: purpose,
        collateral: collateral,
        penaltyRate: penaltyRate,
        firstPaymentDate: firstPaymentDate,
        autoDebitEnabled: autoDebitEnabled,
        notes: notes,
      );

      // Step 3: Create and link transaction BEFORE updating wallet
      String transactionId;
      final transactionDesc = _buildTransactionDescription(loan, type, creditorName, description);

      if (type == LoanType.lent) {
        // Money going out - create expense
        final expense = Expense(
          amount: principalAmount,
          date: date ?? DateTime.now(),
          description: transactionDesc,
          categoryKeys: categoryKeys,
          method: method.trim(),
        );
        transactionKey = await expenseBox.add(expense);
        transactionId = transactionKey.toString();
        debugPrint("💸 Expense created (key: $transactionKey)");

        // Update wallet - decrease balance
        affectedWallet.balance -= principalAmount;
      } else {
        // Money coming in - create income
        final income = Income(
          amount: principalAmount,
          date: date ?? DateTime.now(),
          description: transactionDesc,
          categoryKeys: categoryKeys,
        );
        transactionKey = await incomeBox.add(income);
        transactionId = transactionKey.toString();
        debugPrint("💵 Income created (key: $transactionKey)");

        // Update wallet - increase balance
        affectedWallet.balance += principalAmount;
      }

      // Step 4: Link transaction to loan
      final linkedLoan = loan.linkTransaction(transactionId);

      // Step 5: Save wallet
      affectedWallet.updatedAt = DateTime.now();
      await affectedWallet.save();
      debugPrint("💼 Wallet updated: Balance $originalWalletBalance → ${affectedWallet.balance}");

      // Step 6: Save loan
      loanKey = await loanBox.add(linkedLoan) as String?;
      debugPrint("✅ Loan created (key: $loanKey) with linked transaction ($transactionId)");

      return true;

    } catch (e, st) {
      debugPrint("❌ [addLoanAtomic] Failed: $e\n$st");

      // Rollback
      await _rollbackLoanAdd(
        loanBox,
        expenseBox,
        incomeBox,
        loanKey,
        transactionKey,
        type,
        affectedWallet,
        originalWalletBalance,
      );

      return false;
    }
  }

  /// Atomic operation: Add payment with linked transaction
  static Future<bool> addPaymentAtomic({
    required String loanId,
    required double amount,
    required String method,
    String? note,
    DateTime? date,
  }) async {
    debugPrint("💳 [addPaymentAtomic] Starting atomic payment...");

    if (amount <= 0) {
      debugPrint("❌ Invalid amount: $amount");
      return false;
    }

    final loanBox = Hive.box<Loan>(AppConstants.loans);
    final expenseBox = Hive.box<Expense>(AppConstants.expenses);
    final incomeBox = Hive.box<Income>(AppConstants.incomes);
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);

    int? loanKey;
    Loan? originalLoan;
    int? transactionKey;
    Wallet? affectedWallet;
    double originalWalletBalance = 0;

    try {
      // Step 1: Find loan
      loanKey = loanBox.keys.cast<int>().firstWhere(
            (key) => loanBox.get(key)?.id == loanId,
        orElse: () => throw Exception("Loan not found"),
      );
      originalLoan = loanBox.get(loanKey);

      if (originalLoan == null) {
        throw Exception("Loan not found");
      }

      if (originalLoan.isPaid) {
        debugPrint("⚠️ Loan already paid");
        return false;
      }

      if (amount > originalLoan.remainingAmount + 0.01) {
        debugPrint("❌ Amount exceeds remaining: $amount > ${originalLoan.remainingAmount}");
        return false;
      }

      // Step 2: Find or create wallet
      affectedWallet = await _findOrCreateWallet(walletBox, method);
      originalWalletBalance = affectedWallet.balance;

      // Step 3: Calculate interest split
      final interestSplit = _calculatePaymentSplit(originalLoan, amount);
      final principalPaid = interestSplit['principal']!;
      final interestPaid = interestSplit['interest']!;

      debugPrint("💰 Payment split - Principal: $principalPaid, Interest: $interestPaid");

      // Step 4: Create payment object
      String transactionId;
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();

      final transactionDesc = _buildPaymentDescription(
        originalLoan,
        amount,
        note,
      );

      // Step 5: Create transaction
      if (originalLoan.type == LoanType.lent) {
        // Receiving money back - create income
        final income = Income(
          amount: amount,
          date: date ?? DateTime.now(),
          description: transactionDesc,
          categoryKeys: [8],
          // categoryKeys: originalLoan.categoryKeys,
        );
        transactionKey = await incomeBox.add(income);
        transactionId = transactionKey.toString();
        debugPrint("💵 Income created (key: $transactionKey)");

        // Update wallet - increase balance
        affectedWallet.balance += amount;
      } else {
        // Paying money - create expense
        final expense = Expense(
          amount: amount,
          date: date ?? DateTime.now(),
          description: transactionDesc,
          categoryKeys: [52],
          // categoryKeys: originalLoan.categoryKeys,
          method: method.trim(),
        );
        transactionKey = await expenseBox.add(expense);
        transactionId = transactionKey.toString();
        debugPrint("💸 Expense created (key: $transactionKey)");

        // Update wallet - decrease balance
        affectedWallet.balance -= amount;
      }

      // Step 6: Create payment record
      final payment = LoanPayment(
        id: paymentId,
        amount: amount,
        date: date ?? DateTime.now(),
        note: note,
        method: method.trim(),
        principalPaid: principalPaid,
        interestPaid: interestPaid,
        transactionId: transactionId,
      );

      // Step 7: Update loan
      var updatedLoan = originalLoan.addPayment(payment);
      updatedLoan = updatedLoan.linkTransaction(transactionId);
      updatedLoan = updatedLoan.updateStatus();

      // Step 8: Save wallet
      affectedWallet.updatedAt = DateTime.now();
      await affectedWallet.save();
      debugPrint("💼 Wallet updated: Balance ${originalWalletBalance} → ${affectedWallet.balance}");

      // Step 9: Save loan
      await loanBox.put(loanKey, updatedLoan);
      debugPrint("✅ Payment recorded: ${updatedLoan.paidAmount}/${updatedLoan.totalAmount}");

      return true;

    } catch (e, st) {
      debugPrint("❌ [addPaymentAtomic] Failed: $e\n$st");

      // Rollback
      await _rollbackPaymentAdd(
        loanBox,
        expenseBox,
        incomeBox,
        loanKey,
        originalLoan,
        transactionKey,
        originalLoan?.type,
        affectedWallet,
        originalWalletBalance,
      );

      return false;
    }
  }

  // ===== HELPER METHODS =====

  /// Find existing wallet or create new one
  static Future<Wallet> _findOrCreateWallet(
      Box<Wallet> walletBox,
      String method,
      ) async {
    final normalized = method.trim().toLowerCase();

    try {
      // Try to find existing wallet
      return walletBox.values.firstWhere(
            (w) => w.type.toLowerCase() == normalized,
      );
    } catch (_) {
      // Create new wallet
      final wallet = Wallet(
        name: method.trim(),
        balance: 0,
        updatedAt: DateTime.now(),
        type: method.trim(),
        createdAt: DateTime.now(),
      );
      await walletBox.add(wallet);
      debugPrint("🆕 Created wallet: ${wallet.name}");
      return wallet;
    }
  }

  /// Build transaction description
  static String _buildTransactionDescription(
      Loan loan,
      LoanType type,
      String creditorName,
      String description,
      ) {
    final prefix = type == LoanType.lent ? 'Lent to' : 'Borrowed from';
    final creditorInfo = loan.creditorType == LoanCreditorType.person
        ? creditorName
        : '${creditorName} (${loan.creditorTypeText})';

    String desc = '$prefix $creditorInfo';

    if (description.isNotEmpty) {
      desc += ' - $description';
    }

    if (loan.interestRate > 0) {
      desc += ' [${loan.interestRate}% ${loan.interestTypeText}]';
    }

    if (loan.accountNumber != null) {
      desc += ' (A/C: ${loan.accountNumber})';
    }

    return desc;
  }

  /// Build payment description
  static String _buildPaymentDescription(
      Loan loan,
      double amount,
      String? note,
      ) {
    final prefix = loan.type == LoanType.lent
        ? 'Payment received from'
        : 'Payment made to';

    String desc = '$prefix ${loan.creditorName}';

    if (loan.emiAmount != null) {
      final paymentNum = loan.payments.length + 1;
      desc += ' (EMI #$paymentNum)';
    }

    if (note?.isNotEmpty == true) {
      desc += ' - $note';
    }

    return desc;
  }

  /// Calculate how payment is split between principal and interest (PUBLIC)
  static Map<String, double> calculatePaymentSplit(Loan loan, double amount) {
    return _calculatePaymentSplit(loan, amount);
  }

  /// Calculate how payment is split between principal and interest (PRIVATE)
  static Map<String, double> _calculatePaymentSplit(Loan loan, double amount) {
    if (loan.interestRate == 0 || loan.interestType == InterestType.none) {
      return {'principal': amount, 'interest': 0};
    }

    // For reducing balance (EMI), interest is calculated on remaining principal
    if (loan.interestType == InterestType.reducing) {
      final monthlyRate = loan.interestRate / 100 / 12;
      final interestComponent = loan.remainingPrincipal * monthlyRate;
      final principalComponent = amount - interestComponent;

      return {
        'principal': principalComponent.clamp(0, amount),
        'interest': interestComponent.clamp(0, amount),
      };
    }

    // For simple/compound, distribute proportionally
    final totalInterest = loan.totalInterest;
    final totalAmount = loan.totalAmount;
    final interestRatio = totalInterest / totalAmount;

    return {
      'principal': amount * (1 - interestRatio),
      'interest': amount * interestRatio,
    };
  }

  // ===== ROLLBACK METHODS =====

  static Future<void> _rollbackLoanAdd(
      Box<Loan> loanBox,
      Box<Expense> expenseBox,
      Box<Income> incomeBox,
      String? loanKey,
      int? transactionKey,
      LoanType? type,
      Wallet? wallet,
      double originalBalance,
      ) async {
    try {
      debugPrint("↩️ Rolling back loan creation...");

      // Remove loan
      if (loanKey != null) {
        await loanBox.delete(loanKey);
        debugPrint("↩️ Removed loan");
      }

      // Remove transaction
      if (transactionKey != null) {
        if (type == LoanType.lent) {
          await expenseBox.delete(transactionKey);
          debugPrint("↩️ Removed expense");
        } else {
          await incomeBox.delete(transactionKey);
          debugPrint("↩️ Removed income");
        }
      }

      // Restore wallet
      if (wallet != null) {
        wallet.balance = originalBalance;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("↩️ Restored wallet balance: $originalBalance");
      }

      debugPrint("✅ Rollback complete");
    } catch (e) {
      debugPrint("⚠️ Error during rollback: $e");
    }
  }

  static Future<void> _rollbackPaymentAdd(
      Box<Loan> loanBox,
      Box<Expense> expenseBox,
      Box<Income> incomeBox,
      int? loanKey,
      Loan? originalLoan,
      int? transactionKey,
      LoanType? type,
      Wallet? wallet,
      double originalBalance,
      ) async {
    try {
      debugPrint("↩️ Rolling back payment...");

      // Restore loan
      if (loanKey != null && originalLoan != null) {
        await loanBox.put(loanKey, originalLoan);
        debugPrint("↩️ Restored loan");
      }

      // Remove transaction
      if (transactionKey != null) {
        if (type == LoanType.lent) {
          await incomeBox.delete(transactionKey);
          debugPrint("↩️ Removed income");
        } else {
          await expenseBox.delete(transactionKey);
          debugPrint("↩️ Removed expense");
        }
      }

      // Restore wallet
      if (wallet != null) {
        wallet.balance = originalBalance;
        wallet.updatedAt = DateTime.now();
        await wallet.save();
        debugPrint("↩️ Restored wallet balance: $originalBalance");
      }

      debugPrint("✅ Rollback complete");
    } catch (e) {
      debugPrint("⚠️ Error during rollback: $e");
    }
  }

  // ===== VALIDATION =====

  static String? validateLoanInput({
    required String creditorName,
    required String amount,
    double? interestRate,
    int? tenureMonths,
  }) {
    if (creditorName.trim().isEmpty) {
      return 'Please enter creditor name';
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      return 'Please enter a valid amount';
    }

    if (interestRate != null && (interestRate < 0 || interestRate > 100)) {
      return 'Interest rate must be between 0 and 100';
    }

    if (tenureMonths != null && tenureMonths <= 0) {
      return 'Tenure must be greater than 0';
    }

    return null;
  }

  static String? validatePaymentInput({
    required String amount,
    required double maxAmount,
  }) {
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      return 'Please enter a valid amount';
    }

    if (amountValue > maxAmount + 0.01) {
      return 'Amount cannot exceed ${maxAmount.toStringAsFixed(2)}';
    }

    return null;
  }

  // ===== FORMATTING =====

  static String formatAmount(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  static String formatAmountShort(double amount, String currency) {
    if (amount >= 10000000) {
      return '$currency ${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '$currency ${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '$currency ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$currency ${amount.toStringAsFixed(0)}';
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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

  // ===== UI HELPERS =====

  static Color getStatusColor(Loan loan) {
    if (loan.isPaid) return Colors.green;
    if (loan.isOverdue) return Colors.red;
    if (loan.isDueSoon) return Colors.orange;
    if (loan.paidAmount > 0) return Colors.blue;
    return Colors.grey;
  }

  static Color getTypeColor(LoanType type) {
    return type == LoanType.lent ? Colors.green : Colors.red;
  }

  static IconData getStatusIcon(Loan loan) {
    if (loan.isPaid) return Icons.check_circle;
    if (loan.isOverdue) return Icons.error;
    if (loan.isDueSoon) return Icons.warning;
    if (loan.paidAmount > 0) return Icons.sync;
    return Icons.schedule;
  }

  static Color getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.orange;
    if (progress >= 0.25) return Colors.deepOrange;
    return Colors.red;
  }

  static IconData getCreditorIcon(LoanCreditorType type) {
    switch (type) {
      case LoanCreditorType.person:
        return Icons.person;
      case LoanCreditorType.bank:
        return Icons.account_balance;
      case LoanCreditorType.nbfc:
        return Icons.business;
      case LoanCreditorType.cooperative:
        return Icons.groups;
      case LoanCreditorType.other:
        return Icons.help_outline;
    }
  }

  // ===== ANALYTICS =====

  static List<Loan> getPriorityLoans({int limit = 5}) {
    final service = LoanService();
    final loans = service.getActiveLoans();

    loans.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.isDueSoon && !b.isDueSoon) return -1;
      if (!a.isDueSoon && b.isDueSoon) return 1;

      final aDays = a.nextPaymentDate?.difference(DateTime.now()).inDays ?? 999;
      final bDays = b.nextPaymentDate?.difference(DateTime.now()).inDays ?? 999;
      if (aDays != bDays) return aDays.compareTo(bDays);

      return b.remainingAmount.compareTo(a.remainingAmount);
    });

    return loans.take(limit).toList();
  }

  static Map<String, List<Loan>> getLoansByPerson() {
    final loans = LoanService().getAllLoans();
    final grouped = <String, List<Loan>>{};

    for (var loan in loans) {
      grouped.putIfAbsent(loan.creditorName, () => []);
      grouped[loan.creditorName]!.add(loan);
    }

    return grouped;
  }

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
      if (balance.abs() > 0.01) {
        balances[entry.key] = balance;
      }
    }

    return balances;
  }

  static Map<String, dynamic> getQuickStats(String currency) {
    final stats = LoanService().getStatistics();

    return {
      'toReceive': formatAmountShort(stats['pendingToReceive'], currency),
      'toPay': formatAmountShort(stats['pendingToPay'], currency),
      'overdueCount': stats['overdueCount'],
      'dueSoonCount': stats['dueSoonCount'],
      'activeCount': stats['activeLoans'],
      'totalInterest': formatAmountShort(stats['totalInterest'] ?? 0, currency),
    };
  }
}