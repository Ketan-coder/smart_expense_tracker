// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final typeId = 9;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      personName: fields[1] as String,
      description: fields[2] as String,
      amount: (fields[3] as num).toDouble(),
      date: fields[4] as DateTime,
      dueDate: fields[5] as DateTime?,
      type: fields[6] as LoanType,
      status: fields[7] == null ? LoanStatus.pending : fields[7] as LoanStatus,
      paidAmount: fields[8] == null ? 0 : (fields[8] as num).toDouble(),
      method: fields[10] as String?,
      categoryKeys: (fields[11] as List).cast<int>(),
      payments: (fields[9] as List?)?.cast<LoanPayment>(),
      phoneNumber: fields[12] as String?,
      reminderEnabled: fields[13] == null ? true : fields[13] as bool,
      reminderDaysBefore: fields[14] == null ? 3 : (fields[14] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.paidAmount)
      ..writeByte(9)
      ..write(obj.payments)
      ..writeByte(10)
      ..write(obj.method)
      ..writeByte(11)
      ..write(obj.categoryKeys)
      ..writeByte(12)
      ..write(obj.phoneNumber)
      ..writeByte(13)
      ..write(obj.reminderEnabled)
      ..writeByte(14)
      ..write(obj.reminderDaysBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoanPaymentAdapter extends TypeAdapter<LoanPayment> {
  @override
  final typeId = 10;

  @override
  LoanPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoanPayment(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      date: fields[2] as DateTime,
      note: fields[3] as String?,
      method: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LoanPayment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.method);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoanTypeAdapter extends TypeAdapter<LoanType> {
  @override
  final typeId = 11;

  @override
  LoanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LoanType.lent;
      case 1:
        return LoanType.borrowed;
      default:
        return LoanType.lent;
    }
  }

  @override
  void write(BinaryWriter writer, LoanType obj) {
    switch (obj) {
      case LoanType.lent:
        writer.writeByte(0);
      case LoanType.borrowed:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoanStatusAdapter extends TypeAdapter<LoanStatus> {
  @override
  final typeId = 12;

  @override
  LoanStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LoanStatus.pending;
      case 1:
        return LoanStatus.partiallyPaid;
      case 2:
        return LoanStatus.paid;
      case 3:
        return LoanStatus.overdue;
      default:
        return LoanStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, LoanStatus obj) {
    switch (obj) {
      case LoanStatus.pending:
        writer.writeByte(0);
      case LoanStatus.partiallyPaid:
        writer.writeByte(1);
      case LoanStatus.paid:
        writer.writeByte(2);
      case LoanStatus.overdue:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
