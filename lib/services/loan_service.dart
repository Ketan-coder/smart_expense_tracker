import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../data/model/loan.dart';
import '../services/notification_service.dart';
import 'loan_helpers.dart';

/// Production-ready loan management service
class LoanService {
  static final LoanService _instance = LoanService._internal();
  factory LoanService() => _instance;
  LoanService._internal();

  // Cache for statistics
  static Map<String, dynamic>? _statsCache;
  static DateTime? _statsCacheTime;
  static const int _statsCacheMinutes = 5;

  // Notification rate limiting
  static DateTime? _lastReminderCheck;
  static const int _reminderCheckHours = 12;

  // ===== CRUD Operations =====

  /// Add a new loan using atomic operation
  Future<Loan?> addLoan({
    required String creditorName,
    required String description,
    required double principalAmount,
    required LoanType type,
    required String method,
    required List<int> categoryKeys,
    DateTime? dueDate,
    String? phoneNumber,
    bool reminderEnabled = true,
    int reminderDaysBefore = 3,
    // Enhanced fields
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
    try {
      debugPrint("💰 [LoanService] Adding loan atomically...");

      final success = await LoanHelpers.addLoanAtomic(
        creditorName: creditorName,
        description: description,
        principalAmount: principalAmount,
        type: type,
        method: method,
        categoryKeys: categoryKeys,
        dueDate: dueDate,
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

      if (!success) {
        debugPrint("❌ [LoanService] Failed to add loan");
        return null;
      }

      _clearCache();

      // Find the newly created loan
      final loanBox = Hive.box<Loan>(AppConstants.loans);
      final newLoan = loanBox.values.lastWhere(
            (loan) => loan.creditorName == creditorName.trim() &&
            loan.principalAmount == principalAmount,
        orElse: () => throw Exception("Loan not found after creation"),
      );

      debugPrint("✅ [LoanService] Loan added: ${newLoan.typeText} ${newLoan.principalAmount} ${newLoan.directionText}");

      // Schedule reminders
      if (reminderEnabled && (dueDate != null || firstPaymentDate != null)) {
        await _scheduleRemindersForLoan(newLoan);
      }

      return newLoan;

    } catch (e, st) {
      debugPrint("❌ [LoanService] Error adding loan: $e\n$st");
      return null;
    }
  }

  /// Update an existing loan
  Future<Loan?> updateLoan(String loanId, Loan updatedLoan) async {
    final loanBox = Hive.box<Loan>(AppConstants.loans);

    try {
      final loanKey = loanBox.keys.cast<int>().firstWhere(
            (key) => loanBox.get(key)?.id == loanId,
        orElse: () => throw Exception("Loan not found"),
      );

      // Update status before saving
      final statusUpdatedLoan = updatedLoan.updateStatus();

      await loanBox.put(loanKey, statusUpdatedLoan);
      _clearCache();

      debugPrint("💰 Loan updated: ${statusUpdatedLoan.creditorName}");

      // Reschedule reminders
      if (statusUpdatedLoan.reminderEnabled) {
        await _scheduleRemindersForLoan(statusUpdatedLoan);
      }

      return statusUpdatedLoan;

    } catch (e, st) {
      debugPrint("❌ [LoanService] Error updating loan: $e\n$st");
      return null;
    }
  }

  /// Delete a loan
  Future<bool> deleteLoan(String loanId) async {
    try {
      debugPrint("🗑️ [LoanService] Deleting loan: $loanId");

      final loanBox = Hive.box<Loan>(AppConstants.loans);
      final loanKey = loanBox.keys.cast<int>().firstWhere(
            (key) => loanBox.get(key)?.id == loanId,
        orElse: () => throw Exception("Loan not found"),
      );

      final loan = loanBox.get(loanKey);
      if (loan == null) {
        debugPrint("❌ [LoanService] Loan not found");
        return false;
      }

      // Cancel notifications
      await NotificationService.cancelNotification(loanId.hashCode);

      // Delete loan
      await loanBox.delete(loanKey);
      _clearCache();

      debugPrint("✅ [LoanService] Loan deleted: $loanId");
      return true;

    } catch (e, st) {
      debugPrint("❌ [LoanService] Error deleting loan: $e\n$st");
      return false;
    }
  }

  /// Add payment to a loan using atomic operation
  Future<Loan?> addPayment({
    required String loanId,
    required double amount,
    required String method,
    String? note,
  }) async {
    try {
      debugPrint("💵 [LoanService] Adding payment atomically...");

      final success = await LoanHelpers.addPaymentAtomic(
        loanId: loanId,
        amount: amount,
        method: method,
        note: note,
      );

      if (!success) {
        debugPrint("❌ [LoanService] Failed to add payment");
        return null;
      }

      _clearCache();

      // Get updated loan
      final loanBox = Hive.box<Loan>(AppConstants.loans);
      final updatedLoan = loanBox.values.firstWhere(
            (loan) => loan.id == loanId,
        orElse: () => throw Exception("Loan not found"),
      );

      debugPrint("✅ [LoanService] Payment added: $amount to ${updatedLoan.creditorName}");

      // Cancel reminders if fully paid
      if (updatedLoan.isPaid) {
        await NotificationService.cancelNotification(loanId.hashCode);
        debugPrint("✅ Loan fully paid: ${updatedLoan.creditorName}");
      } else {
        // Reschedule next payment reminder
        await _scheduleRemindersForLoan(updatedLoan);
      }

      return updatedLoan;

    } catch (e, st) {
      debugPrint("❌ [LoanService] Error adding payment: $e\n$st");
      return null;
    }
  }

  // ===== Query Methods =====

  /// Get all loans
  List<Loan> getAllLoans() {
    final loanBox = Hive.box<Loan>(AppConstants.loans);
    return loanBox.values.toList();
  }

  /// Get loans by type
  List<Loan> getLoansByType(LoanType type) {
    return getAllLoans().where((l) => l.type == type).toList();
  }

  /// Get loans by creditor type
  List<Loan> getLoansByCreditorType(LoanCreditorType creditorType) {
    return getAllLoans().where((l) => l.creditorType == creditorType).toList();
  }

  /// Get active (unpaid) loans
  List<Loan> getActiveLoans() {
    return getAllLoans().where((l) => !l.isPaid).toList();
  }

  /// Get overdue loans
  List<Loan> getOverdueLoans() {
    return getAllLoans().where((l) => l.isOverdue).toList();
  }

  /// Get loans due soon
  List<Loan> getLoansDueSoon() {
    return getAllLoans().where((l) => l.isDueSoon && !l.isPaid).toList();
  }

  /// Get loans with upcoming payments
  List<Loan> getLoansWithUpcomingPayments() {
    final now = DateTime.now();
    return getActiveLoans().where((loan) {
      if (loan.nextPaymentDate == null) return false;
      final daysUntil = loan.nextPaymentDate!.difference(now).inDays;
      return daysUntil >= 0 && daysUntil <= 7;
    }).toList();
  }

  /// Get loan by ID
  Loan? getLoanById(String id) {
    final loanBox = Hive.box<Loan>(AppConstants.loans);
    return loanBox.values.firstWhere(
          (loan) => loan.id == id,
      orElse: () => throw Exception("Loan not found"),
    );
  }

  // ===== Statistics (Cached) =====

  /// Get comprehensive loan statistics - CACHED for 5 minutes
  Map<String, dynamic> getStatistics() {
    // Check cache
    if (_statsCache != null && _statsCacheTime != null) {
      final cacheAge = DateTime.now().difference(_statsCacheTime!).inMinutes;
      if (cacheAge < _statsCacheMinutes) {
        debugPrint("📊 Using cached loan statistics");
        return _statsCache!;
      }
    }

    debugPrint("📊 Calculating loan statistics...");

    final loans = getAllLoans();
    final lentLoans = loans.where((l) => l.type == LoanType.lent).toList();
    final borrowedLoans = loans.where((l) => l.type == LoanType.borrowed).toList();

    // Initialize totals
    double totalLent = 0;
    double totalBorrowed = 0;
    double totalLentReceived = 0;
    double totalBorrowedPaid = 0;
    double totalInterestLent = 0;
    double totalInterestBorrowed = 0;
    double pendingInterestToReceive = 0;
    double pendingInterestToPay = 0;
    int overdueCount = 0;
    int dueSoonCount = 0;
    double totalPenalty = 0;

    // Calculate lent statistics
    for (var loan in lentLoans) {
      totalLent += loan.principalAmount;
      totalLentReceived += loan.paidAmount;
      totalInterestLent += loan.totalInterest;

      if (!loan.isPaid) {
        final remainingRatio = loan.remainingAmount / loan.totalAmount;
        pendingInterestToReceive += loan.totalInterest * remainingRatio;
      }

      if (loan.isOverdue) {
        overdueCount++;
        totalPenalty += loan.penaltyAmount;
      }
      if (loan.isDueSoon) dueSoonCount++;
    }

    // Calculate borrowed statistics
    for (var loan in borrowedLoans) {
      totalBorrowed += loan.principalAmount;
      totalBorrowedPaid += loan.paidAmount;
      totalInterestBorrowed += loan.totalInterest;

      if (!loan.isPaid) {
        final remainingRatio = loan.remainingAmount / loan.totalAmount;
        pendingInterestToPay += loan.totalInterest * remainingRatio;
      }

      if (loan.isOverdue) {
        overdueCount++;
        totalPenalty += loan.penaltyAmount;
      }
      if (loan.isDueSoon) dueSoonCount++;
    }

    // Calculate averages
    final activeLent = lentLoans.where((l) => !l.isPaid).length;
    final activeBorrowed = borrowedLoans.where((l) => !l.isPaid).length;
    final avgInterestRate = _calculateAverageInterestRate(loans);

    _statsCache = {
      // Basic counts
      'totalLoans': loans.length,
      'activeLoans': loans.where((l) => !l.isPaid).length,
      'paidLoans': loans.where((l) => l.isPaid).length,

      // Lent statistics
      'totalLent': totalLent,
      'totalLentReceived': totalLentReceived,
      'pendingToReceive': totalLent + totalInterestLent - totalLentReceived,
      'lentCount': lentLoans.length,
      'activeLentCount': activeLent,

      // Borrowed statistics
      'totalBorrowed': totalBorrowed,
      'totalBorrowedPaid': totalBorrowedPaid,
      'pendingToPay': totalBorrowed + totalInterestBorrowed - totalBorrowedPaid,
      'borrowedCount': borrowedLoans.length,
      'activeBorrowedCount': activeBorrowed,

      // Interest statistics
      'totalInterest': totalInterestLent + totalInterestBorrowed,
      'totalInterestLent': totalInterestLent,
      'totalInterestBorrowed': totalInterestBorrowed,
      'pendingInterestToReceive': pendingInterestToReceive,
      'pendingInterestToPay': pendingInterestToPay,
      'averageInterestRate': avgInterestRate,

      // Net balance
      'netBalance': (totalLent + totalInterestLent - totalLentReceived) -
          (totalBorrowed + totalInterestBorrowed - totalBorrowedPaid),

      // Alerts
      'overdueCount': overdueCount,
      'dueSoonCount': dueSoonCount,
      'totalPenalty': totalPenalty,

      // By creditor type
      'bankLoans': loans.where((l) => l.creditorType == LoanCreditorType.bank).length,
      'personalLoans': loans.where((l) => l.creditorType == LoanCreditorType.person).length,
    };

    _statsCacheTime = DateTime.now();
    return _statsCache!;
  }

  /// Calculate average interest rate
  double _calculateAverageInterestRate(List<Loan> loans) {
    final loansWithInterest = loans.where((l) => l.interestRate > 0).toList();
    if (loansWithInterest.isEmpty) return 0;

    final totalRate = loansWithInterest.fold<double>(
      0,
          (sum, loan) => sum + loan.interestRate,
    );

    return totalRate / loansWithInterest.length;
  }

  // ===== Notification Helpers =====

  /// Schedule all reminders for a loan
  Future<void> _scheduleRemindersForLoan(Loan loan) async {
    if (!loan.reminderEnabled || loan.isPaid) return;

    // Cancel existing reminders
    await NotificationService.cancelNotification(loan.id.hashCode);

    // Schedule next payment reminder
    if (loan.nextPaymentDate != null) {
      final reminderDate = loan.nextPaymentDate!.subtract(
        Duration(days: loan.reminderDaysBefore),
      );

      if (reminderDate.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: loan.id.hashCode,
          title: loan.type == LoanType.lent
              ? '💰 Payment Due from ${loan.creditorName}'
              : '💵 Payment Due to ${loan.creditorName}',
          body: 'Amount: ${loan.nextPaymentAmount.toStringAsFixed(0)} - Due in ${loan.reminderDaysBefore} days',
          scheduledDate: reminderDate,
        );
        debugPrint("🔔 Reminder scheduled for: ${loan.creditorName}");
      }
    }
  }

  /// Check and send reminders - RATE LIMITED
  Future<void> checkAndSendReminders() async {
    // Rate limiting
    if (_lastReminderCheck != null) {
      final hoursSince = DateTime.now().difference(_lastReminderCheck!).inHours;
      if (hoursSince < _reminderCheckHours) {
        debugPrint("⏭️ Skipping reminder check (last: $hoursSince hours ago)");
        return;
      }
    }

    debugPrint("🔔 Checking loan reminders...");
    _lastReminderCheck = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    final notifiedLoans = prefs.getStringList('notified_loans_today') ?? [];

    // Reset daily
    final lastResetDate = prefs.getString('last_notification_reset');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastResetDate != today) {
      notifiedLoans.clear();
      await prefs.setString('last_notification_reset', today);
    }

    // Get loans needing reminders
    final loansToNotify = getAllLoans().where((loan) {
      return loan.shouldRemind() && !notifiedLoans.contains(loan.id);
    }).take(5).toList();

    for (var loan in loansToNotify) {
      await _sendLoanReminder(loan);
      notifiedLoans.add(loan.id);
    }

    await prefs.setStringList('notified_loans_today', notifiedLoans);
    debugPrint("✅ Sent ${loansToNotify.length} reminders");
  }

  /// Send immediate reminder
  Future<void> _sendLoanReminder(Loan loan) async {
    final isLent = loan.type == LoanType.lent;

    await NotificationService.showNotification(
      id: loan.id.hashCode,
      title: isLent ? '💰 Collect Payment' : '💵 Payment Due',
      body: isLent
          ? '${loan.creditorName} owes ${loan.remainingAmount.toStringAsFixed(0)} ${loan.statusText.toLowerCase()}'
          : 'You owe ${loan.creditorName} ${loan.remainingAmount.toStringAsFixed(0)} ${loan.statusText.toLowerCase()}',
      channelId: 'loan_reminders',
      channelName: 'Loan Reminders',
    );
  }

  /// Send overdue notification
  Future<void> sendOverdueNotification(Loan loan) async {
    if (!loan.isOverdue) return;

    await NotificationService.showNotification(
      id: (loan.id.hashCode + 1000),
      title: '🚨 Overdue Loan!',
      body: loan.type == LoanType.lent
          ? '${loan.creditorName} is ${loan.daysOverdue} days overdue on ${loan.remainingAmount.toStringAsFixed(0)}'
          : 'Your payment to ${loan.creditorName} is ${loan.daysOverdue} days overdue!',
      channelId: 'loan_reminders',
      channelName: 'Loan Reminders',
    );
  }

  // ===== Utility Methods =====

  /// Update all loan statuses (run daily)
  Future<void> updateAllLoanStatuses() async {
    final loanBox = Hive.box<Loan>(AppConstants.loans);

    for (var key in loanBox.keys) {
      final loan = loanBox.get(key);
      if (loan == null) continue;

      final updatedLoan = loan.updateStatus();
      if (updatedLoan.status != loan.status) {
        await loanBox.put(key, updatedLoan);
        debugPrint("📊 Updated status for ${loan.creditorName}: ${updatedLoan.statusText}");
      }
    }

    _clearCache();
  }

  /// Get priority loans
  List<Loan> getPriorityLoans({int limit = 5}) {
    return LoanHelpers.getPriorityLoans(limit: limit);
  }

  /// Get loans grouped by person
  Map<String, List<Loan>> getLoansByPerson() {
    return LoanHelpers.getLoansByPerson();
  }

  /// Get balance by person
  Map<String, double> getBalanceByPerson() {
    return LoanHelpers.getBalanceByPerson();
  }

  /// Get quick stats
  Map<String, dynamic> getQuickStats(String currency) {
    return LoanHelpers.getQuickStats(currency);
  }

  // ===== Cache Management =====

  static void _clearCache() {
    _statsCache = null;
    _statsCacheTime = null;
    debugPrint("🗑️ Loan statistics cache cleared");
  }

  void refreshCache() {
    _clearCache();
    getStatistics();
  }

  // ===== Validation =====

  static String? validateLoanInput({
    required String creditorName,
    required String amount,
    double? interestRate,
    int? tenureMonths,
  }) {
    return LoanHelpers.validateLoanInput(
      creditorName: creditorName,
      amount: amount,
      interestRate: interestRate,
      tenureMonths: tenureMonths,
    );
  }

  static String? validatePaymentInput({
    required String amount,
    required double maxAmount,
  }) {
    return LoanHelpers.validatePaymentInput(
      amount: amount,
      maxAmount: maxAmount,
    );
  }
}