import 'package:hive_ce/hive.dart';

part 'users.g.dart'; // Needed for code generation

@HiveType(typeId: 5) // Each models must have a unique typeId
class User {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  User({required this.name, required this.age});

  @override
  String toString() => "User(name: $name, age: $age)";
}
