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

  Expense({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryKeys,
     this.method,
  });

  @override
  String toString() =>
      "Expense(amount: $amount, date: $date, desc: $description, categories: $categoryKeys, method: $method)";
}
