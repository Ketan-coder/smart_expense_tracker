import 'package:hive_ce/hive.dart';

part 'habit.g.dart'; // Needed for code generation

@HiveType(typeId: 3)
class Habit {
  @HiveField(0)
  String name;

  @HiveField(1)
  String frequency; // e.g. daily, weekly, monthly

  @HiveField(2)
  List<int> categoryKeys; // links to Category box keys

  Habit({
    required this.name,
    required this.frequency,
    required this.categoryKeys,
  });

  @override
  String toString() =>
      "Habit(name: $name, freq: $frequency, categories: $categoryKeys)";
}