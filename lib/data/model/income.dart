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

  @HiveField(5)
  int? walletKey;

  @HiveField(6)
  String classification;

  @HiveField(7)
  double? recognizedAmount;

  @HiveField(8)
  bool? balanceApplied;

  Income({
    required this.amount,
    required this.date,
    required this.description,
    required this.categoryKeys,
    this.method,
    this.walletKey,
    this.classification = 'income',
    this.recognizedAmount,
    this.balanceApplied,
  });

  double get amountForReporting =>
      recognizedAmount ?? (classification == 'income' ? amount : 0);

  @override
  String toString() =>
      "Income(amount: $amount, date: $date, desc: $description, categories: $categoryKeys, method: $method)";
}
