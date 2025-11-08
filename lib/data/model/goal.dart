// models/goal.dart
import 'package:hive_ce/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 8)
class Goal {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  final DateTime targetDate;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  final String category; // "Savings", "Investment", "Purchase", etc.

  @HiveField(8)
  final String priority; // "Low", "Medium", "High"

  @HiveField(9)
  final bool isCompleted;

  @HiveField(10)
  final String walletType; // Which wallet to use for installments

  @HiveField(11)
  final double installmentAmount; // Regular installment amount

  @HiveField(12)
  final String installmentFrequency; // "Daily", "Weekly", "Monthly"

  @HiveField(13)
  DateTime? lastInstallmentDate;

  Goal({
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.targetDate,
    required this.category,
    required this.priority,
    required this.walletType,
    required this.installmentAmount,
    required this.installmentFrequency,
    this.currentAmount = 0.0,
    this.isCompleted = false,
    this.lastInstallmentDate,
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  double get remainingAmount => targetAmount - currentAmount;
  double get progressPercentage => (currentAmount / targetAmount) * 100;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
  bool get isOnTrack {
    final daysPassed = DateTime.now().difference(createdAt).inDays;
    final expectedAmount = (daysPassed / totalDays) * targetAmount;
    return currentAmount >= expectedAmount * 0.8; // 80% of expected progress
  }

  int get totalDays => targetDate.difference(createdAt).inDays;

  void addInstallment(double amount) {
    currentAmount += amount;
    updatedAt = DateTime.now();
    lastInstallmentDate = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
      'walletType': walletType,
      'installmentAmount': installmentAmount,
      'installmentFrequency': installmentFrequency,
      'progressPercentage': progressPercentage,
      'remainingAmount': remainingAmount,
      'daysRemaining': daysRemaining,
    };
  }
}