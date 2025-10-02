import 'package:hive_ce/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 2)
class Income {
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

  Income({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryKeys,
    this.method,
  });

  @override
  String toString() =>
      "Income(amount: $amount, date: $date, desc: $description, categories: $categoryKeys, method: $method)";
}