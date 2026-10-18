import 'package:expense_tracker/core/profile_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileScope', () {
    test('keeps the default profile on legacy box names', () {
      ProfileScope.activeProfileId = 'default';

      expect(ProfileScope.boxName('expenses'), 'expenses');
    });

    test('isolates non-default profiles by ID', () {
      ProfileScope.activeProfileId = 'europe';

      expect(ProfileScope.boxName('expenses'), 'expenses__profile_europe');
    });
  });
}
