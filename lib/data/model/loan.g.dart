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
      creditorName: fields[1] as String,
      description: fields[2] as String,
      principalAmount: (fields[3] as num).toDouble(),
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
      creditorType: fields[15] == null
          ? LoanCreditorType.person
          : fields[15] as LoanCreditorType,
      interestRate: fields[16] == null ? 0 : (fields[16] as num).toDouble(),
      interestType: fields[17] == null
          ? InterestType.none
          : fields[17] as InterestType,
      tenureMonths: (fields[18] as num?)?.toInt(),
      emiAmount: (fields[19] as num?)?.toDouble(),
      paymentFrequency: fields[20] == null
          ? PaymentFrequency.monthly
          : fields[20] as PaymentFrequency,
      accountNumber: fields[21] as String?,
      referenceNumber: fields[22] as String?,
      linkedTransactionIds: (fields[23] as List?)?.cast<String>(),
      purpose: fields[24] as LoanPurpose?,
      collateral: fields[25] as String?,
      penaltyRate: (fields[26] as num?)?.toDouble(),
      documents: (fields[27] as List?)?.cast<LoanDocument>(),
      firstPaymentDate: fields[28] as DateTime?,
      autoDebitEnabled: fields[29] == null ? false : fields[29] as bool,
      notes: fields[30] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.creditorName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.principalAmount)
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
      ..write(obj.reminderDaysBefore)
      ..writeByte(15)
      ..write(obj.creditorType)
      ..writeByte(16)
      ..write(obj.interestRate)
      ..writeByte(17)
      ..write(obj.interestType)
      ..writeByte(18)
      ..write(obj.tenureMonths)
      ..writeByte(19)
      ..write(obj.emiAmount)
      ..writeByte(20)
      ..write(obj.paymentFrequency)
      ..writeByte(21)
      ..write(obj.accountNumber)
      ..writeByte(22)
      ..write(obj.referenceNumber)
      ..writeByte(23)
      ..write(obj.linkedTransactionIds)
      ..writeByte(24)
      ..write(obj.purpose)
      ..writeByte(25)
      ..write(obj.collateral)
      ..writeByte(26)
      ..write(obj.penaltyRate)
      ..writeByte(27)
      ..write(obj.documents)
      ..writeByte(28)
      ..write(obj.firstPaymentDate)
      ..writeByte(29)
      ..write(obj.autoDebitEnabled)
      ..writeByte(30)
      ..write(obj.notes);
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
      principalPaid: fields[5] == null ? 0 : (fields[5] as num).toDouble(),
      interestPaid: fields[6] == null ? 0 : (fields[6] as num).toDouble(),
      transactionId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LoanPayment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.method)
      ..writeByte(5)
      ..write(obj.principalPaid)
      ..writeByte(6)
      ..write(obj.interestPaid)
      ..writeByte(7)
      ..write(obj.transactionId);
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

class LoanDocumentAdapter extends TypeAdapter<LoanDocument> {
  @override
  final typeId = 13;

  @override
  LoanDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoanDocument(
      id: fields[0] as String,
      name: fields[1] as String,
      filePath: fields[2] as String,
      type: fields[3] as DocumentType,
      uploadedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LoanDocument obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.uploadedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanDocumentAdapter &&
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

class LoanCreditorTypeAdapter extends TypeAdapter<LoanCreditorType> {
  @override
  final typeId = 14;

  @override
  LoanCreditorType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LoanCreditorType.person;
      case 1:
        return LoanCreditorType.bank;
      case 2:
        return LoanCreditorType.nbfc;
      case 3:
        return LoanCreditorType.cooperative;
      case 4:
        return LoanCreditorType.other;
      default:
        return LoanCreditorType.person;
    }
  }

  @override
  void write(BinaryWriter writer, LoanCreditorType obj) {
    switch (obj) {
      case LoanCreditorType.person:
        writer.writeByte(0);
      case LoanCreditorType.bank:
        writer.writeByte(1);
      case LoanCreditorType.nbfc:
        writer.writeByte(2);
      case LoanCreditorType.cooperative:
        writer.writeByte(3);
      case LoanCreditorType.other:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanCreditorTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InterestTypeAdapter extends TypeAdapter<InterestType> {
  @override
  final typeId = 15;

  @override
  InterestType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InterestType.none;
      case 1:
        return InterestType.simple;
      case 2:
        return InterestType.compound;
      case 3:
        return InterestType.reducing;
      default:
        return InterestType.none;
    }
  }

  @override
  void write(BinaryWriter writer, InterestType obj) {
    switch (obj) {
      case InterestType.none:
        writer.writeByte(0);
      case InterestType.simple:
        writer.writeByte(1);
      case InterestType.compound:
        writer.writeByte(2);
      case InterestType.reducing:
        writer.writeByte(3);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterestTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentFrequencyAdapter extends TypeAdapter<PaymentFrequency> {
  @override
  final typeId = 16;

  @override
  PaymentFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PaymentFrequency.weekly;
      case 1:
        return PaymentFrequency.biweekly;
      case 2:
        return PaymentFrequency.monthly;
      case 3:
        return PaymentFrequency.quarterly;
      case 4:
        return PaymentFrequency.yearly;
      case 5:
        return PaymentFrequency.custom;
      default:
        return PaymentFrequency.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, PaymentFrequency obj) {
    switch (obj) {
      case PaymentFrequency.weekly:
        writer.writeByte(0);
      case PaymentFrequency.biweekly:
        writer.writeByte(1);
      case PaymentFrequency.monthly:
        writer.writeByte(2);
      case PaymentFrequency.quarterly:
        writer.writeByte(3);
      case PaymentFrequency.yearly:
        writer.writeByte(4);
      case PaymentFrequency.custom:
        writer.writeByte(5);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoanPurposeAdapter extends TypeAdapter<LoanPurpose> {
  @override
  final typeId = 17;

  @override
  LoanPurpose read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LoanPurpose.personal;
      case 1:
        return LoanPurpose.business;
      case 2:
        return LoanPurpose.education;
      case 3:
        return LoanPurpose.medical;
      case 4:
        return LoanPurpose.home;
      case 5:
        return LoanPurpose.vehicle;
      case 6:
        return LoanPurpose.emergency;
      case 7:
        return LoanPurpose.investment;
      case 8:
        return LoanPurpose.other;
      default:
        return LoanPurpose.personal;
    }
  }

  @override
  void write(BinaryWriter writer, LoanPurpose obj) {
    switch (obj) {
      case LoanPurpose.personal:
        writer.writeByte(0);
      case LoanPurpose.business:
        writer.writeByte(1);
      case LoanPurpose.education:
        writer.writeByte(2);
      case LoanPurpose.medical:
        writer.writeByte(3);
      case LoanPurpose.home:
        writer.writeByte(4);
      case LoanPurpose.vehicle:
        writer.writeByte(5);
      case LoanPurpose.emergency:
        writer.writeByte(6);
      case LoanPurpose.investment:
        writer.writeByte(7);
      case LoanPurpose.other:
        writer.writeByte(8);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanPurposeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DocumentTypeAdapter extends TypeAdapter<DocumentType> {
  @override
  final typeId = 18;

  @override
  DocumentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DocumentType.agreement;
      case 1:
        return DocumentType.invoice;
      case 2:
        return DocumentType.receipt;
      case 3:
        return DocumentType.promissoryNote;
      case 4:
        return DocumentType.other;
      default:
        return DocumentType.agreement;
    }
  }

  @override
  void write(BinaryWriter writer, DocumentType obj) {
    switch (obj) {
      case DocumentType.agreement:
        writer.writeByte(0);
      case DocumentType.invoice:
        writer.writeByte(1);
      case DocumentType.receipt:
        writer.writeByte(2);
      case DocumentType.promissoryNote:
        writer.writeByte(3);
      case DocumentType.other:
        writer.writeByte(4);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
