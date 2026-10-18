import 'package:expense_tracker/data/model/expense.dart';
import 'package:expense_tracker/data/model/income.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transaction reporting amounts', () {
    test('ordinary income and expense report their full amount', () {
      final expense = Expense(
        amount: 42,
        date: DateTime(2025),
        description: 'Groceries',
        categoryKeys: const [],
      );
      final income = Income(
        amount: 120,
        date: DateTime(2025),
        description: 'Salary',
        categoryKeys: const [],
      );

      expect(expense.amountForReporting, 42);
      expect(income.amountForReporting, 120);
    });

    test('loan principal is excluded while interest remains reportable', () {
      final principal = Income(
        amount: 500,
        date: DateTime(2025),
        description: 'Loan proceeds',
        categoryKeys: const [],
        classification: 'loan_proceeds',
        recognizedAmount: 0,
      );
      final interest = Expense(
        amount: 100,
        date: DateTime(2025),
        description: 'Loan repayment',
        categoryKeys: const [],
        classification: 'loan_repayment',
        recognizedAmount: 12,
      );

      expect(principal.amountForReporting, 0);
      expect(interest.amountForReporting, 12);
    });
  });
}
