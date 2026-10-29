import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/sms_service.dart';

void main() {
  Map<String, dynamic>? parse(String sender, String msg) =>
      SmsListener.parseTransactionSms(
          sender, msg, DateTime.now().millisecondsSinceEpoch);

  group('Must be REJECTED', () {
    test('Kotak personal-loan promo (the bug)', () {
      expect(parse(
        'JX-KOTAKB-P',
        'Dear Customer, Thankyou for speaking to Kotak Bank representative '
            'regarding your Personal Loan. Click here https://14.kotak.bank.in/KOTAKB/f773d085 '
            'to complete your application and receive Rs. 565000 credited in your '
            'account instantly. T&C apply.',
      ), isNull);
    });

    test('same text even from a -S sender (text check alone)', () {
      expect(parse(
        'JX-KOTAKB-S',
        'Click here to complete your application and receive Rs. 565000 '
            'credited in your account instantly. T&C apply.',
      ), isNull);
    });

    test('promo from -P sender', () {
      expect(parse('VA-HAVELL-P',
          'Get Rs.1000 cashback on your next purchase. Offer valid till Sunday.'),
          isNull);
    });

    test('OTP', () {
      expect(parse('AX-HDFCBK-S',
          '123456 is the OTP for txn of Rs.500 at Amazon. Do not share.'),
          isNull);
    });

    test('personal number', () {
      expect(parse('+919876543210', 'Sent Rs.500 to you via UPI Ref 123456789012'),
          isNull);
    });
  });

  group('Must be ACCEPTED', () {
    test('UPI debit', () {
      final t = parse('JM-KOTAKB-S',
          'Sent Rs.1275.00 from Kotak Bank AC X1234 to shop@upi on 27-10-26. '
              'UPI Ref 123456789012.');
      expect(t, isNotNull);
      expect(t!['type'], 'debit');
      expect(t['amount'], 1275.0);
    });

    test('bank credit', () {
      final t = parse('AX-HDFCBK-S',
          'Rs.5000.00 credited to a/c XX1234 on 27-10-26 by UPI Ref 123456789012. '
              'Avl bal Rs 9000.00');
      expect(t, isNotNull);
      expect(t!['type'], 'credit');
      expect(t['amount'], 5000.0); // not the balance
    });

    test('credit card spend', () {
      final t = parse('VM-HDFCBK-S',
          'Rs.2500.00 spent on HDFC Credit Card XX4321 at AMAZON on 27-10-26.');
      expect(t, isNotNull);
      expect(t!['type'], 'debit');
    });

    test('real alert that also has a link', () {
      final t = parse('JM-KOTAKB-S',
          'Rs.500.00 debited from A/c XX1234 on 27-10-26. Not you? '
              'Click https://kotak.com/block to block.');
      expect(t, isNotNull);
    });
    test('ATM withdrawal', () {
      expect(parse('AX-AXISBK-S',
          'Rs 2000.00 withdrawn at ATM on 27-10-26. Avl Bal Rs 8000.00'), isNotNull);
    });

    test('EMI debit', () {
      expect(parse('JM-KOTAKB-S',
          'Rs.4500.00 debited from A/c XX1234 towards loan EMI.'), isNotNull);
    });

    test('failed txn stays rejected', () {
      expect(parse('JM-KOTAKB-S',
          'Txn of Rs.500 on A/c XX1234 failed.'), isNull);
    });
  });
}