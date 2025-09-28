import 'package:hive_ce/hive.dart';

part 'recurring.g.dart';

@HiveType(typeId: 6)
class Recurring {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime startDate;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<int> categoryKeys; // links to Category box keys

  @HiveField(4)
  String interval; // e.g. "daily", "weekly", "monthly", "yearly"

  @HiveField(5)
  DateTime? endDate; // optional: when recurrence stops

  Recurring({
    required this.amount,
    required this.startDate,
    required this.description,
    required this.categoryKeys,
    required this.interval,
    this.endDate,
  });

  @override
  String toString() =>
      "Recurring(amount: $amount, startDate: $startDate, desc: $description, interval: $interval, categories: $categoryKeys, endDate: $endDate)";
}
