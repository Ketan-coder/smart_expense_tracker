// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final typeId = 3;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      name: fields[0] as String,
      description: fields[1] as String,
      frequency: fields[2] as String,
      categoryKeys: (fields[3] as List).cast<int>(),
      createdAt: fields[4] as DateTime,
      lastCompletedAt: fields[5] as DateTime?,
      completionHistory: (fields[6] as List?)?.cast<DateTime>(),
      targetAmount: (fields[7] as num?)?.toDouble(),
      targetTime: fields[8] as String?,
      isActive: fields[9] == null ? true : fields[9] as bool,
      type: fields[10] == null ? 'custom' : fields[10] as String,
      streakCount: fields[11] == null ? 0 : (fields[11] as num).toInt(),
      bestStreak: fields[12] == null ? 0 : (fields[12] as num).toInt(),
      icon: fields[13] == null ? 'track_changes' : fields[13] as String,
      color: fields[14] == null ? '#FF6B6B' : fields[14] as String,
      isAutoDetected: fields[15] == null ? false : fields[15] as bool,
      detectionConfidence: fields[16] == null ? 0 : (fields[16] as num).toInt(),
      notes: fields[17] as String?,
      selectedMethod: fields[18] == null ? 'UPI' : fields[18] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.frequency)
      ..writeByte(3)
      ..write(obj.categoryKeys)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastCompletedAt)
      ..writeByte(6)
      ..write(obj.completionHistory)
      ..writeByte(7)
      ..write(obj.targetAmount)
      ..writeByte(8)
      ..write(obj.targetTime)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.type)
      ..writeByte(11)
      ..write(obj.streakCount)
      ..writeByte(12)
      ..write(obj.bestStreak)
      ..writeByte(13)
      ..write(obj.icon)
      ..writeByte(14)
      ..write(obj.color)
      ..writeByte(15)
      ..write(obj.isAutoDetected)
      ..writeByte(16)
      ..write(obj.detectionConfidence)
      ..writeByte(17)
      ..write(obj.notes)
      ..writeByte(18)
      ..write(obj.selectedMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
