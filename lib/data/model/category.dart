import 'package:hive_ce/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category {
  @HiveField(0)
  String name;

  @HiveField(1)
  String color; // e.g. hex color string

  @HiveField(2)
  String type; // "expense", "income", "habit", or "general"

  @HiveField(3)
  String icon; // Material icon code

  Category({
    required this.name,
    required this.color,
    required this.type,
    required this.icon,
  });

  // Helper method to get icon data
  String getIconCode() {
    return icon;
  }

  @override
  String toString() => "Category(name: $name, type: $type, icon: $icon)";
}