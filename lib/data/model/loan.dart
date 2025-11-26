import 'package:hive_ce/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 9)
class Loan {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String personName;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double amount;

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
  final String? phoneNumber; // For contact

  @HiveField(13)
  final bool reminderEnabled; // For notifications

  @HiveField(14)
  final int reminderDaysBefore; // Remind X days before due

  Loan({
    required this.id,
    required this.personName,
    required this.description,
    required this.amount,
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
  }) : payments = payments ?? [];

  // ===== Computed Properties =====

  double get remainingAmount => amount - paidAmount;

  double get progress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0;

  bool get isOverdue => dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != LoanStatus.paid;

  bool get isPaid => status == LoanStatus.paid || remainingAmount <= 0;

  bool get isDueSoon {
    if (dueDate == null || isPaid) return false;
    final daysUntilDue = dueDate!.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= reminderDaysBefore;
  }

  int get daysUntilDue {
    if (dueDate == null) return -1;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  int get daysOverdue {
    if (dueDate == null || !isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  String get statusText {
    if (isPaid) return 'Paid';
    if (isOverdue) return 'Overdue by $daysOverdue days';
    if (isDueSoon) return 'Due in $daysUntilDue days';
    if (paidAmount > 0) return 'Partially Paid';
    return 'Pending';
  }

  String get typeText => type == LoanType.lent ? 'Lent' : 'Borrowed';

  String get directionText => type == LoanType.lent
      ? 'to $personName'
      : 'from $personName';

  // ===== Methods =====

  /// Add a payment and return updated loan
  Loan addPayment(LoanPayment payment) {
    final newPayments = List<LoanPayment>.from(payments)..add(payment);
    final newPaidAmount = paidAmount + payment.amount;

    LoanStatus newStatus;
    if (newPaidAmount >= amount) {
      newStatus = LoanStatus.paid;
    } else if (newPaidAmount > 0) {
      newStatus = LoanStatus.partiallyPaid;
    } else {
      newStatus = status;
    }

    return copyWith(
      payments: newPayments,
      paidAmount: newPaidAmount.clamp(0, amount),
      status: newStatus,
    );
  }

  /// Check if reminder should be sent
  bool shouldRemind() {
    if (!reminderEnabled || isPaid || dueDate == null) return false;
    final daysLeft = daysUntilDue;
    return daysLeft >= 0 && daysLeft <= reminderDaysBefore;
  }

  /// Get appropriate emoji for status
  String get statusEmoji {
    if (isPaid) return '✅';
    if (isOverdue) return '🚨';
    if (isDueSoon) return '⚠️';
    if (paidAmount > 0) return '🔄';
    return '⏳';
  }

  Loan copyWith({
    String? personName,
    String? description,
    double? amount,
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
  }) {
    return Loan(
      id: id,
      personName: personName ?? this.personName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
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
    );
  }

  @override
  String toString() {
    return 'Loan($typeText $amount to $personName, status: $statusText)';
  }
}

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

  LoanPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.method,
  });

  LoanPayment copyWith({
    double? amount,
    DateTime? date,
    String? note,
    String? method,
  }) {
    return LoanPayment(
      id: id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      method: method ?? this.method,
    );
  }
}

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