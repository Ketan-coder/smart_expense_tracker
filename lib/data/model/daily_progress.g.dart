// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyProgressAdapter extends TypeAdapter<DailyProgress> {
  @override
  final typeId = 19;

  @override
  DailyProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyProgress(
      date: fields[0] as DateTime,
      hasGoalProgress: fields[1] == null ? false : fields[1] as bool,
      hasHabitCompletion: fields[2] == null ? false : fields[2] as bool,
      hasProductiveTransaction: fields[3] == null ? false : fields[3] as bool,
      completedGoalNames: fields[4] == null
          ? const []
          : (fields[4] as List).cast<String>(),
      completedHabitNames: fields[5] == null
          ? const []
          : (fields[5] as List).cast<String>(),
      totalSavings: fields[6] == null ? 0.0 : (fields[6] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.hasGoalProgress)
      ..writeByte(2)
      ..write(obj.hasHabitCompletion)
      ..writeByte(3)
      ..write(obj.hasProductiveTransaction)
      ..writeByte(4)
      ..write(obj.completedGoalNames)
      ..writeByte(5)
      ..write(obj.completedHabitNames)
      ..writeByte(6)
      ..write(obj.totalSavings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
