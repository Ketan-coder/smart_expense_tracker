import 'dart:math';

import 'package:hive_ce/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 9)
class Loan {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String creditorName; // Person or institution name

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double principalAmount; // Original loan amount

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final DateTime? dueDate;

  @HiveField(6)
  final LoanType type;

  @HiveField(7)
  final LoanStatus status;

  @HiveField(8)
  final double paidAmount;

  @HiveField(9)
  final List<LoanPayment> payments;

  @HiveField(10)
  final String? method;

  @HiveField(11)
  final List<int> categoryKeys;

  @HiveField(12)
  final String? phoneNumber;

  @HiveField(13)
  final bool reminderEnabled;

  @HiveField(14)
  final int reminderDaysBefore;

  @HiveField(15)
  final LoanCreditorType creditorType; // NEW: Person vs Institution

  @HiveField(16)
  final double interestRate; // NEW: Annual interest rate (%)

  @HiveField(17)
  final InterestType interestType; // NEW: Simple, compound, or none

  @HiveField(18)
  final int? tenureMonths; // NEW: Loan duration in months

  @HiveField(19)
  final double? emiAmount; // NEW: Fixed EMI if applicable

  @HiveField(20)
  final PaymentFrequency paymentFrequency; // NEW: Monthly, quarterly, etc.

  @HiveField(21)
  final String? accountNumber; // NEW: Loan account number

  @HiveField(22)
  final String? referenceNumber; // NEW: Reference/agreement number

  @HiveField(23)
  final List<String> linkedTransactionIds; // NEW: Links to expenses/incomes

  @HiveField(24)
  final LoanPurpose? purpose; // NEW: Why the loan was taken

  @HiveField(25)
  final String? collateral; // NEW: Asset pledged (if any)

  @HiveField(26)
  final double? penaltyRate; // NEW: Late payment penalty rate

  @HiveField(27)
  final List<LoanDocument>? documents; // NEW: Attached documents

  @HiveField(28)
  final DateTime? firstPaymentDate; // NEW: When payments start

  @HiveField(29)
  final bool autoDebitEnabled; // NEW: Auto payment enabled

  @HiveField(30)
  final String? notes; // NEW: Additional notes

  Loan({
    required this.id,
    required this.creditorName,
    required this.description,
    required this.principalAmount,
    required this.date,
    this.dueDate,
    required this.type,
    this.status = LoanStatus.pending,
    this.paidAmount = 0,
    this.method,
    required this.categoryKeys,
    List<LoanPayment>? payments,
    this.phoneNumber,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
    this.creditorType = LoanCreditorType.person,
    this.interestRate = 0,
    this.interestType = InterestType.none,
    this.tenureMonths,
    this.emiAmount,
    this.paymentFrequency = PaymentFrequency.monthly,
    this.accountNumber,
    this.referenceNumber,
    List<String>? linkedTransactionIds,
    this.purpose,
    this.collateral,
    this.penaltyRate,
    this.documents,
    this.firstPaymentDate,
    this.autoDebitEnabled = false,
    this.notes,
  })  : payments = payments ?? [],
        linkedTransactionIds = linkedTransactionIds ?? [];

  // ===== Computed Properties =====

  /// Total amount to pay including interest
  double get totalAmount {
    if (interestRate == 0 || interestType == InterestType.none) {
      return principalAmount;
    }

    final principal = principalAmount;
    final rate = interestRate / 100;
    final time = tenureMonths ?? 12;

    switch (interestType) {
      case InterestType.simple:
        return principal + (principal * rate * time / 12);
      case InterestType.compound:
        final n = paymentFrequency == PaymentFrequency.monthly ? 12 : 4;
        return principal * pow(1 + rate / n, n * time / 12);
      case InterestType.reducing:
      // EMI-based reducing balance
        if (emiAmount != null) {
          final totalPayments = _getTotalPayments();
          return emiAmount! * totalPayments;
        }
        return principal * (1 + rate * time / 12);
      case InterestType.none:
        return principal;
    }
  }

  /// Total interest amount
  double get totalInterest => totalAmount - principalAmount;

  /// Remaining amount to pay
  double get remainingAmount => totalAmount - paidAmount;

  /// Principal remaining
  double get remainingPrincipal {
    if (interestRate == 0) return remainingAmount;
    // Calculate how much of remaining is principal vs interest
    final totalPaid = paidAmount;
    final totalInterestAccrued = totalInterest;
    final principalPaid = totalPaid - (totalInterestAccrued * (totalPaid / totalAmount));
    return principalAmount - principalPaid;
  }

  /// Interest paid so far
  double get interestPaid => paidAmount - (principalAmount - remainingPrincipal);

  /// Payment progress (0 to 1)
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0;

  /// Check if overdue
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && status != LoanStatus.paid;

  /// Check if fully paid
  bool get isPaid => status == LoanStatus.paid || remainingAmount <= 0.01;

  /// Check if due soon
  bool get isDueSoon {
    if (dueDate == null || isPaid) return false;
    final daysUntilDue = dueDate!.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= reminderDaysBefore;
  }

  /// Days until due date
  int get daysUntilDue {
    if (dueDate == null) return -1;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  /// Days overdue
  int get daysOverdue {
    if (dueDate == null || !isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  /// Calculate penalty amount
  double get penaltyAmount {
    if (penaltyRate == null || !isOverdue || daysOverdue == 0) return 0;
    return remainingAmount * (penaltyRate! / 100) * (daysOverdue / 30);
  }

  /// Get next payment date
  DateTime? get nextPaymentDate {
    if (isPaid || firstPaymentDate == null) return null;

    final frequency = paymentFrequency;
    final lastPaymentDate = payments.isEmpty ? firstPaymentDate! : payments.last.date;

    switch (frequency) {
      case PaymentFrequency.weekly:
        return lastPaymentDate.add(const Duration(days: 7));
      case PaymentFrequency.biweekly:
        return lastPaymentDate.add(const Duration(days: 14));
      case PaymentFrequency.monthly:
        return DateTime(lastPaymentDate.year, lastPaymentDate.month + 1, lastPaymentDate.day);
      case PaymentFrequency.quarterly:
        return DateTime(lastPaymentDate.year, lastPaymentDate.month + 3, lastPaymentDate.day);
      case PaymentFrequency.yearly:
        return DateTime(lastPaymentDate.year + 1, lastPaymentDate.month, lastPaymentDate.day);
      case PaymentFrequency.custom:
        return dueDate;
    }
  }

  /// Get expected payment amount for next payment
  double get nextPaymentAmount {
    if (emiAmount != null) return emiAmount!;
    if (remainingAmount <= 0) return 0;

    final totalPayments = _getTotalPayments();
    final remainingPayments = totalPayments - payments.length;

    if (remainingPayments <= 0) return remainingAmount;
    return remainingAmount / remainingPayments;
  }

  /// Calculate total number of payments expected
  int _getTotalPayments() {
    if (tenureMonths == null) return 1;

    switch (paymentFrequency) {
      case PaymentFrequency.weekly:
        return (tenureMonths! * 4.33).round();
      case PaymentFrequency.biweekly:
        return (tenureMonths! * 2.17).round();
      case PaymentFrequency.monthly:
        return tenureMonths!;
      case PaymentFrequency.quarterly:
        return (tenureMonths! / 3).round();
      case PaymentFrequency.yearly:
        return (tenureMonths! / 12).round();
      case PaymentFrequency.custom:
        return 1;
    }
  }

  /// Status text with context
  String get statusText {
    if (isPaid) return 'Paid';
    if (isOverdue) return 'Overdue by $daysOverdue days';
    if (isDueSoon) return 'Due in $daysUntilDue days';
    if (paidAmount > 0) return 'Partially Paid (${(progress * 100).toStringAsFixed(0)}%)';
    return 'Active';
  }

  /// Type text
  String get typeText => type == LoanType.lent ? 'Lent' : 'Borrowed';

  /// Direction text (to/from)
  String get directionText =>
      type == LoanType.lent ? 'to $creditorName' : 'from $creditorName';

  /// Get appropriate emoji for status
  String get statusEmoji {
    if (isPaid) return '✅';
    if (isOverdue) return '🚨';
    if (isDueSoon) return '⚠️';
    if (paidAmount > 0) return '🔄';
    return '⏳';
  }

  /// Get creditor type text
  String get creditorTypeText {
    switch (creditorType) {
      case LoanCreditorType.person:
        return 'Person';
      case LoanCreditorType.bank:
        return 'Bank';
      case LoanCreditorType.nbfc:
        return 'NBFC';
      case LoanCreditorType.cooperative:
        return 'Cooperative';
      case LoanCreditorType.other:
        return 'Other';
    }
  }

  /// Get interest type text
  String get interestTypeText {
    switch (interestType) {
      case InterestType.none:
        return 'No Interest';
      case InterestType.simple:
        return 'Simple Interest';
      case InterestType.compound:
        return 'Compound Interest';
      case InterestType.reducing:
        return 'Reducing Balance';
    }
  }

  // ===== Methods =====

  /// Add a payment and return updated loan
  Loan addPayment(LoanPayment payment) {
    final newPayments = List<LoanPayment>.from(payments)..add(payment);
    final newPaidAmount = paidAmount + payment.amount;

    LoanStatus newStatus;
    if (newPaidAmount >= totalAmount - 0.01) {
      newStatus = LoanStatus.paid;
    } else if (newPaidAmount > 0) {
      newStatus = LoanStatus.partiallyPaid;
    } else {
      newStatus = status;
    }

    return copyWith(
      payments: newPayments,
      paidAmount: newPaidAmount.clamp(0, totalAmount),
      status: newStatus,
    );
  }

  /// Link a transaction ID
  Loan linkTransaction(String transactionId) {
    if (linkedTransactionIds.contains(transactionId)) return this;
    return copyWith(
      linkedTransactionIds: [...linkedTransactionIds, transactionId],
    );
  }

  /// Check if reminder should be sent
  bool shouldRemind() {
    if (!reminderEnabled || isPaid || nextPaymentDate == null) return false;
    final daysLeft = nextPaymentDate!.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= reminderDaysBefore;
  }

  /// Update status based on current state
  Loan updateStatus() {
    LoanStatus newStatus;

    if (isPaid) {
      newStatus = LoanStatus.paid;
    } else if (isOverdue) {
      newStatus = LoanStatus.overdue;
    } else if (paidAmount > 0) {
      newStatus = LoanStatus.partiallyPaid;
    } else {
      newStatus = LoanStatus.pending;
    }

    if (newStatus != status) {
      return copyWith(status: newStatus);
    }
    return this;
  }

  Loan copyWith({
    String? creditorName,
    String? description,
    double? principalAmount,
    DateTime? date,
    DateTime? dueDate,
    LoanType? type,
    LoanStatus? status,
    double? paidAmount,
    String? method,
    List<int>? categoryKeys,
    List<LoanPayment>? payments,
    String? phoneNumber,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    LoanCreditorType? creditorType,
    double? interestRate,
    InterestType? interestType,
    int? tenureMonths,
    double? emiAmount,
    PaymentFrequency? paymentFrequency,
    String? accountNumber,
    String? referenceNumber,
    List<String>? linkedTransactionIds,
    LoanPurpose? purpose,
    String? collateral,
    double? penaltyRate,
    List<LoanDocument>? documents,
    DateTime? firstPaymentDate,
    bool? autoDebitEnabled,
    String? notes,
  }) {
    return Loan(
      id: id,
      creditorName: creditorName ?? this.creditorName,
      description: description ?? this.description,
      principalAmount: principalAmount ?? this.principalAmount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      method: method ?? this.method,
      categoryKeys: categoryKeys ?? this.categoryKeys,
      payments: payments ?? this.payments,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      creditorType: creditorType ?? this.creditorType,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      emiAmount: emiAmount ?? this.emiAmount,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      accountNumber: accountNumber ?? this.accountNumber,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      linkedTransactionIds: linkedTransactionIds ?? this.linkedTransactionIds,
      purpose: purpose ?? this.purpose,
      collateral: collateral ?? this.collateral,
      penaltyRate: penaltyRate ?? this.penaltyRate,
      documents: documents ?? this.documents,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
      autoDebitEnabled: autoDebitEnabled ?? this.autoDebitEnabled,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Loan($typeText ${principalAmount} to $creditorName, status: $statusText)';
  }
}

// ===== Supporting Classes =====

@HiveType(typeId: 10)
class LoanPayment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String? note;

  @HiveField(4)
  final String? method;

  @HiveField(5)
  final double principalPaid; // How much went to principal

  @HiveField(6)
  final double interestPaid; // How much went to interest

  @HiveField(7)
  final String? transactionId; // Linked expense/income ID

  LoanPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.method,
    this.principalPaid = 0,
    this.interestPaid = 0,
    this.transactionId,
  });

  LoanPayment copyWith({
    double? amount,
    DateTime? date,
    String? note,
    String? method,
    double? principalPaid,
    double? interestPaid,
    String? transactionId,
  }) {
    return LoanPayment(
      id: id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      method: method ?? this.method,
      principalPaid: principalPaid ?? this.principalPaid,
      interestPaid: interestPaid ?? this.interestPaid,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

@HiveType(typeId: 13)
class LoanDocument {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String filePath;

  @HiveField(3)
  final DocumentType type;

  @HiveField(4)
  final DateTime uploadedAt;

  LoanDocument({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    required this.uploadedAt,
  });
}

// ===== Enums =====

@HiveType(typeId: 11)
enum LoanType {
  @HiveField(0)
  lent,

  @HiveField(1)
  borrowed,
}

@HiveType(typeId: 12)
enum LoanStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  partiallyPaid,

  @HiveField(2)
  paid,

  @HiveField(3)
  overdue,
}

@HiveType(typeId: 14)
enum LoanCreditorType {
  @HiveField(0)
  person,

  @HiveField(1)
  bank,

  @HiveField(2)
  nbfc, // Non-Banking Financial Company

  @HiveField(3)
  cooperative,

  @HiveField(4)
  other,
}

@HiveType(typeId: 15)
enum InterestType {
  @HiveField(0)
  none,

  @HiveField(1)
  simple,

  @HiveField(2)
  compound,

  @HiveField(3)
  reducing, // EMI-style reducing balance
}

@HiveType(typeId: 16)
enum PaymentFrequency {
  @HiveField(0)
  weekly,

  @HiveField(1)
  biweekly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  quarterly,

  @HiveField(4)
  yearly,

  @HiveField(5)
  custom,
}

@HiveType(typeId: 17)
enum LoanPurpose {
  @HiveField(0)
  personal,

  @HiveField(1)
  business,

  @HiveField(2)
  education,

  @HiveField(3)
  medical,

  @HiveField(4)
  home,

  @HiveField(5)
  vehicle,

  @HiveField(6)
  emergency,

  @HiveField(7)
  investment,

  @HiveField(8)
  other,
}

@HiveType(typeId: 18)
enum DocumentType {
  @HiveField(0)
  agreement,

  @HiveField(1)
  invoice,

  @HiveField(2)
  receipt,

  @HiveField(3)
  promissoryNote,

  @HiveField(4)
  other,
}