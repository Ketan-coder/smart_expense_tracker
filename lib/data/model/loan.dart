// models/loan.dart
import 'package:hive_ce/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 9) // Use typeId 8 since you have types 0-7
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
  final String? method; // Payment method (Cash, UPI, Bank, etc.)

  @HiveField(11)
  final List<int> categoryKeys; // Connect with your categories

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
  }) : payments = payments ?? [];

  double get remainingAmount => amount - paidAmount;
  double get progress => amount > 0 ? paidAmount / amount : 0;
  bool get isOverdue => dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != LoanStatus.paid;

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
    );
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
  final String? method; // Payment method

  LoanPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
    this.method,
  });
}

@HiveType(typeId: 11)
enum LoanType {
  @HiveField(0)
  lent, // You lent money to someone

  @HiveField(1)
  borrowed, // You borrowed money from someone
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