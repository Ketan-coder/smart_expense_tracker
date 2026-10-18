// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final typeId = 1;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      amount: (fields[0] as num).toDouble(),
      date: fields[1] as DateTime,
      description: fields[2] as String,
      categoryKeys: (fields[3] as List).cast<int>(),
      method: fields[4] as String?,
      walletKey: (fields[5] as num?)?.toInt(),
      classification: fields[6] == null ? 'expense' : fields[6] as String,
      recognizedAmount: (fields[7] as num?)?.toDouble(),
      balanceApplied: fields[8] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categoryKeys)
      ..writeByte(4)
      ..write(obj.method)
      ..writeByte(5)
      ..write(obj.walletKey)
      ..writeByte(6)
      ..write(obj.classification)
      ..writeByte(7)
      ..write(obj.recognizedAmount)
      ..writeByte(8)
      ..write(obj.balanceApplied);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
