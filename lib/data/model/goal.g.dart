// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final typeId = 8;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Goal(
      name: fields[0] as String,
      description: fields[1] as String,
      targetAmount: (fields[2] as num).toDouble(),
      targetDate: fields[4] as DateTime,
      category: fields[7] as String,
      priority: fields[8] as String,
      walletType: fields[10] as String,
      installmentAmount: (fields[11] as num).toDouble(),
      installmentFrequency: fields[12] as String,
      currentAmount: fields[3] == null ? 0.0 : (fields[3] as num).toDouble(),
      isCompleted: fields[9] == null ? false : fields[9] as bool,
      lastInstallmentDate: fields[13] as DateTime?,
    )..updatedAt = fields[6] as DateTime;
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.currentAmount)
      ..writeByte(4)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.walletType)
      ..writeByte(11)
      ..write(obj.installmentAmount)
      ..writeByte(12)
      ..write(obj.installmentFrequency)
      ..writeByte(13)
      ..write(obj.lastInstallmentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
