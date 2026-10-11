import 'package:expense_tracker/ai/input_token_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateInputTokens', () {
    test('estimates ASCII text conservatively', () {
      expect(estimateInputTokens('a' * 300), 150);
    });

    test('counts non-ASCII characters conservatively', () {
      expect(estimateInputTokens('हिंदी'), 5);
    });
  });

  group('limitTextToTokens', () {
    test('keeps text within the requested input budget', () {
      final result = limitTextToTokens('financial facts ' * 100, 120);

      expect(estimateInputTokens(result), lessThanOrEqualTo(120));
      expect(result, startsWith('financial facts'));
    });

    test('preserves the beginning and end of long single-shot prompts', () {
      final result = limitTextToTokens(
        '${'context ' * 100}FINAL REQUEST',
        80,
        preserveEnds: true,
      );

      expect(estimateInputTokens(result), lessThanOrEqualTo(80));
      expect(result, startsWith('context'));
      expect(result, endsWith('FINAL REQUEST'));
    });
  });
}
