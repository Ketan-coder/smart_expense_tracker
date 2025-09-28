// import 'package:hive_ce/hive.dart';
//
// part 'models.g.dart';

// @HiveType(typeId: 0)
// class Category {
//   @HiveField(0)
//   String name;
//
//   @HiveField(1)
//   String color; // e.g. hex color string
//
//   @HiveField(2)
//   String type; // "expense", "income", "habit", or "general"
//
//   Category({
//     required this.name,
//     required this.color,
//     required this.type,
//   });
//
//   @override
//   String toString() => "Category(name: $name, type: $type)";
// }

// @HiveType(typeId: 1)
// class Expense {
//   @HiveField(0)
//   double amount;
//
//   @HiveField(1)
//   DateTime date;
//
//   @HiveField(2)
//   String description;
//
//   @HiveField(3)
//   List<int> categoryKeys; // links to Category box keys
//
//   Expense({
//     required this.amount,
//     required this.date,
//     required this.description,
//     required this.categoryKeys,
//   });
//
//   @override
//   String toString() =>
//       "Expense(amount: $amount, date: $date, desc: $description, categories: $categoryKeys)";
// }

// @HiveType(typeId: 2)
// class Income {
//   @HiveField(0)
//   double amount;
//
//   @HiveField(1)
//   DateTime date;
//
//   @HiveField(2)
//   String description;
//
//   @HiveField(3)
//   List<int> categoryKeys; // links to Category box keys
//
//   Income({
//     required this.amount,
//     required this.date,
//     required this.description,
//     required this.categoryKeys,
//   });
//
//   @override
//   String toString() =>
//       "Income(amount: $amount, date: $date, desc: $description, categories: $categoryKeys)";
// }

// @HiveType(typeId: 3)
// class Habit {
//   @HiveField(0)
//   String name;
//
//   @HiveField(1)
//   String frequency; // e.g. daily, weekly, monthly
//
//   @HiveField(2)
//   List<int> categoryKeys; // links to Category box keys
//
//   Habit({
//     required this.name,
//     required this.frequency,
//     required this.categoryKeys,
//   });
//
//   @override
//   String toString() =>
//       "Habit(name: $name, freq: $frequency, categories: $categoryKeys)";
// }
