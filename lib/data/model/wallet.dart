import 'package:hive_ce/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 7) // make sure to give unique typeId
class Wallet {
  @HiveField(0)
  String name; // Wallet name (e.g., Cash, Bank, UPI, Paytm, Credit Card)

  @HiveField(1)
  double balance; // Current balance of wallet

  @HiveField(2)
  String type; // e.g. "cash", "bank", "upi", "credit"

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? updatedAt;

  Wallet({
    required this.name,
    required this.balance,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  String toString() =>
      "Wallet(name: $name, balance: $balance, type: $type, createdAt: $createdAt)";
}
