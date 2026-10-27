import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/models/account_form_validators.dart';
import 'package:landing_page/models/initial_password.dart';

void main() {
  test(
    'generated passwords satisfy the API policy and vary across accounts',
    () {
      final passwords = List.generate(100, (_) => generateInitialPassword());
      for (final password in passwords) {
        expect(password.length, 24);
        expect(AccountFormValidators.password(password), isNull);
      }
      expect(passwords.toSet().length, passwords.length);
    },
  );
}
