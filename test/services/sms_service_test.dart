import 'package:expense_tracker/services/sms_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SMS transaction parsing', () {
    test('ignores messages without a clear debit or credit direction', () {
      expect(
        SmsListener.parseTransactionSms(
          'BANK',
          'Your account transaction amount Rs 100',
          1735689600000,
        ),
        isNull,
      );
    });

    test('ignores messages that indicate both debit and credit', () {
      expect(
        SmsListener.parseTransactionSms(
          'BANK',
          'Rs 100 debited and Rs 50 credited to your account',
          1735689600000,
        ),
        isNull,
      );
    });

    test('preserves unambiguous credit direction and timestamp', () {
      final parsed = SmsListener.parseTransactionSms(
        'BANK',
        'Rs 250 credited to your account',
        1735689600000,
      );

      expect(parsed?['type'], 'credit');
      expect(
        parsed?['timestamp'],
        DateTime.fromMillisecondsSinceEpoch(1735689600000),
      );
    });
  });
}
