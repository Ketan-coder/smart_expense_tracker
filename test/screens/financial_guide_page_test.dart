import 'package:expense_tracker/screens/financial_guide_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'report email is addressed to the app contact with a prefilled message',
    () {
      final uri = financialGuideReportUri(
        subject: 'SmartSpend issue report',
        body: 'What I expected:\nWhat happened:',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'ketanv288@gmail.com');
      expect(uri.toString(), contains('SmartSpend%20issue%20report'));
      expect(uri.toString(), isNot(contains('+')));
      expect(uri.queryParameters['subject'], 'SmartSpend issue report');
      expect(uri.queryParameters['body'], 'What I expected:\nWhat happened:');
    },
  );
}
