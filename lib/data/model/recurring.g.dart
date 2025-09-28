// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringAdapter extends TypeAdapter<Recurring> {
  @override
  final typeId = 6;

  @override
  Recurring read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recurring(
      amount: (fields[0] as num).toDouble(),
      startDate: fields[1] as DateTime,
      description: fields[2] as String,
      categoryKeys: (fields[3] as List).cast<int>(),
      interval: fields[4] as String,
      endDate: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Recurring obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.categoryKeys)
      ..writeByte(4)
      ..write(obj.interval)
      ..writeByte(5)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
