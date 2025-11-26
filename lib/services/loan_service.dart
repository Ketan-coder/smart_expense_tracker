import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../data/model/loan.dart';
import '../services/notification_service.dart';
import 'loan_helpers.dart';

/// BATTERY OPTIMIZED: Loan management service with caching and rate limiting
class LoanService {
  static final LoanService _instance = LoanService._internal();
  factory LoanService() => _instance;
  LoanService._internal();

  // Cache for statistics (prevents recalculation)
  static Map<String, dynamic>? _statsCache;
  static DateTime? _statsCacheTime;
  static const int _statsCacheMinutes = 5; // Cache stats for 5 minutes

  // Notification rate limiting
  static DateTime? _lastReminderCheck;
  static const int _reminderCheckHours = 12; // Check reminders every 12 hours

  // ===== CRUD Operations =====

  /// Add a new loan using atomic operation
  Future<Loan?> addLoan({
    required String personName,
    required String description,
    required double amount,
    required LoanType type,
    required String method,
    required List<int> categoryKeys,
    DateTime? dueDate,
    String? phoneNumber,
    bool reminderEnabled = true,
    int reminderDaysBefore = 3,
  }) async {
    try {
      debugPrint("💰 [LoanService] Adding loan using atomic operation...");

      // Use atomic operation from LoanHelpers
      final success = await LoanHelpers.addLoanAtomic(
        personName: personName,
        description: description,
        amount: amount,
        type: type,
        method: method,
        categoryKeys: categoryKeys,
        dueDate: dueDate,
        phoneNumber: phoneNumber,
        reminderEnabled: reminderEnabled,
        reminderDaysBefore: reminderDaysBefore,
      );

      if (!success) {
        debugPrint("❌ [LoanService] Failed to add loan atomically");
        return null;
      }

      _clearCache(); // Invalidate cache

      // Find the newly created loan to return it
      final loanBox = Hive.box<Loan>(AppConstants.loans);
      final newLoan = loanBox.values.lastWhere(
            (loan) => loan.personName == personName.trim() && loan.amount == amount,
        orElse: () => throw Exception("Loan not found after atomic creation"),
      );

      debugPrint("✅ [LoanService] Loan added atomically: ${newLoan.typeText} ${newLoan.amount} ${newLoan.directionText}");

      // Schedule reminder if due date set
      if (dueDate != null && reminderEnabled) {
        await _scheduleReminderForLoan(newLoan);
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

    if (!loanBox.containsKey(loanId)) {
      debugPrint("❌ Loan not found: $loanId");
      return null;
    }

    await loanBox.put(loanId, updatedLoan);
    _clearCache();

    debugPrint("💰 Loan updated: ${updatedLoan.personName}");

    // Reschedule reminder if due date changed
    if (updatedLoan.dueDate != null && updatedLoan.reminderEnabled) {
      await _scheduleReminderForLoan(updatedLoan);
    }

    return updatedLoan;
  }

  /// Delete a loan
  Future<bool> deleteLoan(String loanId) async {
    try {
      debugPrint("🗑️ [LoanService] Deleting loan: $loanId");

      // Cancel any scheduled notifications first
      await NotificationService.cancelNotification(loanId.hashCode);

      // Find the loan to get its details for proper cleanup
      final loanBox = Hive.box<Loan>(AppConstants.loans);
      final loan = loanBox.get(loanId);

      if (loan == null) {
        debugPrint("❌ [LoanService] Loan not found: $loanId");
        return false;
      }

      // For atomic deletion, we would need to implement LoanHelpers.deleteLoanAtomic()
      // For now, use standard deletion
      await loanBox.delete(loanId);
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
      debugPrint("💵 [LoanService] Adding payment using atomic operation...");

      // Use atomic operation from LoanHelpers
      final success = await LoanHelpers.addPaymentAtomic(
        loanId: loanId,
        amount: amount,
        method: method,
        note: note,
      );

      if (!success) {
        debugPrint("❌ [LoanService] Failed to add payment atomically");
        return null;
      }

      _clearCache();

      // Find the updated loan to return it
      final loanBox = Hive.box<Loan>(AppConstants.loans);
      final updatedLoan = loanBox.get(loanId);

      if (updatedLoan == null) {
        debugPrint("❌ [LoanService] Loan not found after payment: $loanId");
        return null;
      }

      debugPrint("✅ [LoanService] Payment added atomically: $amount to loan ${updatedLoan.personName}");

      // Check if loan is now paid and cancel reminders
      if (updatedLoan.isPaid) {
        await NotificationService.cancelNotification(loanId.hashCode);
        debugPrint("✅ Loan fully paid: ${updatedLoan.personName}");
      }

      return updatedLoan;

    } catch (e, st) {
      debugPrint("❌ [LoanService] Error adding payment: $e\n$st");
      return null;
    }
  }

  // ===== Query Methods (Cached) =====

  /// Get all loans
  List<Loan> getAllLoans() {
    final loanBox = Hive.box<Loan>(AppConstants.loans);
    return loanBox.values.toList();
  }

  /// Get loans by type
  List<Loan> getLoansByType(LoanType type) {
    return getAllLoans().where((l) => l.type == type).toList();
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

  /// Get loan by ID
  Loan? getLoanById(String id) {
    final loanBox = Hive.box<Loan>(AppConstants.loans);
    return loanBox.get(id);
  }

  // ===== Statistics (Cached for Performance) =====

  /// Get loan statistics - CACHED for 5 minutes
  Map<String, dynamic> getStatistics() {
    // Check cache first
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

    // Calculate totals efficiently
    double totalLent = 0;
    double totalBorrowed = 0;
    double totalLentReceived = 0;
    double totalBorrowedPaid = 0;
    int overdueCount = 0;
    int dueSoonCount = 0;

    for (var loan in lentLoans) {
      totalLent += loan.amount;
      totalLentReceived += loan.paidAmount;
      if (loan.isOverdue) overdueCount++;
      if (loan.isDueSoon) dueSoonCount++;
    }

    for (var loan in borrowedLoans) {
      totalBorrowed += loan.amount;
      totalBorrowedPaid += loan.paidAmount;
      if (loan.isOverdue) overdueCount++;
      if (loan.isDueSoon) dueSoonCount++;
    }

    _statsCache = {
      'totalLoans': loans.length,
      'activeLoans': loans.where((l) => !l.isPaid).length,
      'paidLoans': loans.where((l) => l.isPaid).length,
      'totalLent': totalLent,
      'totalBorrowed': totalBorrowed,
      'totalLentReceived': totalLentReceived,
      'totalBorrowedPaid': totalBorrowedPaid,
      'pendingToReceive': totalLent - totalLentReceived,
      'pendingToPay': totalBorrowed - totalBorrowedPaid,
      'netBalance': (totalLent - totalLentReceived) - (totalBorrowed - totalBorrowedPaid),
      'overdueCount': overdueCount,
      'dueSoonCount': dueSoonCount,
      'lentCount': lentLoans.length,
      'borrowedCount': borrowedLoans.length,
    };

    _statsCacheTime = DateTime.now();
    return _statsCache!;
  }

  // ===== Notification Helpers =====

  /// Schedule reminder for a specific loan
  Future<void> _scheduleReminderForLoan(Loan loan) async {
    if (loan.dueDate == null || !loan.reminderEnabled || loan.isPaid) return;

    final reminderDate = loan.dueDate!.subtract(
      Duration(days: loan.reminderDaysBefore),
    );

    // Only schedule if reminder date is in the future
    if (reminderDate.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
        id: loan.id.hashCode,
        title: loan.type == LoanType.lent
            ? '💰 Loan Reminder'
            : '💵 Payment Reminder',
        body: loan.type == LoanType.lent
            ? '${loan.personName} owes you ${loan.remainingAmount.toStringAsFixed(0)} - due in ${loan.reminderDaysBefore} days'
            : 'You owe ${loan.personName} ${loan.remainingAmount.toStringAsFixed(0)} - due in ${loan.reminderDaysBefore} days',
        scheduledDate: reminderDate,
      );
      debugPrint("🔔 Reminder scheduled for loan: ${loan.personName}");
    }
  }

  /// Check and send reminders for all loans - RATE LIMITED
  Future<void> checkAndSendReminders() async {
    // Rate limiting - only check every 12 hours
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

    // Reset daily notifications at midnight
    final lastResetDate = prefs.getString('last_notification_reset');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastResetDate != today) {
      notifiedLoans.clear();
      await prefs.setString('last_notification_reset', today);
    }

    final loansToNotify = getAllLoans().where((loan) {
      return loan.shouldRemind() && !notifiedLoans.contains(loan.id);
    }).take(5).toList(); // LIMIT: Max 5 notifications per check

    for (var loan in loansToNotify) {
      await _sendLoanReminder(loan);
      notifiedLoans.add(loan.id);
    }

    await prefs.setStringList('notified_loans_today', notifiedLoans);
    debugPrint("✅ Sent ${loansToNotify.length} loan reminders");
  }

  /// Send immediate reminder for a loan
  Future<void> _sendLoanReminder(Loan loan) async {
    final isLent = loan.type == LoanType.lent;

    await NotificationService.showNotification(
      id: loan.id.hashCode,
      title: isLent ? '💰 Collect Payment' : '💵 Payment Due',
      body: isLent
          ? '${loan.personName} owes you ${loan.remainingAmount.toStringAsFixed(0)} ${loan.statusText.toLowerCase()}'
          : 'You owe ${loan.personName} ${loan.remainingAmount.toStringAsFixed(0)} ${loan.statusText.toLowerCase()}',
      channelId: 'loan_reminders',
      channelName: 'Loan Reminders',
    );
  }

  /// Send overdue notification
  Future<void> sendOverdueNotification(Loan loan) async {
    if (!loan.isOverdue) return;

    await NotificationService.showNotification(
      id: (loan.id.hashCode + 1000), // Different ID for overdue
      title: '🚨 Overdue Loan!',
      body: loan.type == LoanType.lent
          ? '${loan.personName} is ${loan.daysOverdue} days overdue on ${loan.remainingAmount.toStringAsFixed(0)}'
          : 'Your payment to ${loan.personName} is ${loan.daysOverdue} days overdue!',
      channelId: 'loan_reminders',
      channelName: 'Loan Reminders',
    );
  }

  // ===== Validation Helpers =====

  /// Validate loan input using LoanHelpers
  static String? validateLoanInput({
    required String personName,
    required String amount,
  }) {
    return LoanHelpers.validateLoanInput(
      personName: personName,
      amount: amount,
    );
  }

  /// Validate payment input using LoanHelpers
  static String? validatePaymentInput({
    required String amount,
    required double maxAmount,
  }) {
    return LoanHelpers.validatePaymentInput(
      amount: amount,
      maxAmount: maxAmount,
    );
  }

  // ===== Cache Management =====

  /// Clear statistics cache
  static void _clearCache() {
    _statsCache = null;
    _statsCacheTime = null;
    debugPrint("🗑️ Loan statistics cache cleared");
  }

  /// Force refresh cache
  void refreshCache() {
    _clearCache();
    getStatistics(); // Rebuild cache
  }

  // ===== Utility Methods =====

  /// Get priority loans using LoanHelpers
  List<Loan> getPriorityLoans({int limit = 5}) {
    return LoanHelpers.getPriorityLoans(limit: limit);
  }

  /// Get loans grouped by person using LoanHelpers
  Map<String, List<Loan>> getLoansByPerson() {
    return LoanHelpers.getLoansByPerson();
  }

  /// Get balance by person using LoanHelpers
  Map<String, double> getBalanceByPerson() {
    return LoanHelpers.getBalanceByPerson();
  }

  /// Get quick stats using LoanHelpers
  Map<String, dynamic> getQuickStats(String currency) {
    return LoanHelpers.getQuickStats(currency);
  }

  /// Format amount using LoanHelpers
  static String formatAmount(double amount, String currency) {
    return LoanHelpers.formatAmount(amount, currency);
  }

  /// Format amount short using LoanHelpers
  static String formatAmountShort(double amount, String currency) {
    return LoanHelpers.formatAmountShort(amount, currency);
  }

  /// Format due date using LoanHelpers
  static String formatDueDate(DateTime? dueDate) {
    return LoanHelpers.formatDueDate(dueDate);
  }
}