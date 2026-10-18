import 'package:hive_ce/hive.dart';

part 'expense.g.dart'; // Needed for code generation

@HiveType(typeId: 1)
class Expense {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<int> categoryKeys; // links to Category box keys

  @HiveField(4)
  String? method;

  @HiveField(5)
  int? walletKey;

  @HiveField(6)
  String classification;

  @HiveField(7)
  double? recognizedAmount;

  @HiveField(8)
  bool? balanceApplied;

  Expense({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryKeys,
    this.method,
    this.walletKey,
    this.classification = 'expense',
    this.recognizedAmount,
    this.balanceApplied,
  });

  double get amountForReporting =>
      recognizedAmount ?? (classification == 'expense' ? amount : 0);

  @override
  String toString() =>
      "Expense(amount: $amount, date: $date, desc: $description, categories: $categoryKeys, method: $method)";
}
