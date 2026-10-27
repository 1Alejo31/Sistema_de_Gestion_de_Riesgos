import 'package:flutter_test/flutter_test.dart';
import 'package:landing_page/models/account_form_validators.dart';

void main() {
  test('email supports common valid addresses and surrounding spaces', () {
    for (final email in [
      'person@example.com',
      'person+sst@company.com.co',
      ' person@my-company.co ',
    ]) {
      expect(AccountFormValidators.email(email), isNull);
    }
  });

  test('email rejects missing address and malformed local or domain parts', () {
    for (final email in [
      '',
      'person',
      'a@@example.com',
      'a b@example.com',
      'a..b@example.com',
      '.a@example.com',
      'a.@example.com',
      'a@example',
      'a@-example.com',
      'a@example..com',
      'a@example.c',
    ]) {
      expect(AccountFormValidators.email(email), isNotNull);
    }
  });

  test(
    'password enforces API length and complexity, confirmation must match',
    () {
      expect(AccountFormValidators.password(null), isNotNull);
      expect(AccountFormValidators.password('       '), isNotNull);
      expect(AccountFormValidators.password('Abcdefghij1!xy'), isNull);
      expect(AccountFormValidators.password('Abcdefgh1!xy'), isNotNull);
      expect(AccountFormValidators.password('abcdefghijklmn1!'), isNotNull);
      expect(AccountFormValidators.password('ABCDEFGHIJKLMN1!'), isNotNull);
      expect(AccountFormValidators.password('Abcdefghijklmn!'), isNotNull);
      expect(AccountFormValidators.password('Abcdefghijklmn1'), isNotNull);
      expect(AccountFormValidators.password('Abcdefghijklmn1!' * 8), isNull);
      expect(AccountFormValidators.password('Abcdefghijklmn1!' * 9), isNotNull);
      expect(
        AccountFormValidators.confirmation('', 'Abcdefghij1!xy'),
        isNotNull,
      );
      expect(
        AccountFormValidators.confirmation('Abcdefghij1!xz', 'Abcdefghij1!xy'),
        isNotNull,
      );
      expect(
        AccountFormValidators.confirmation('Abcdefghij1!xy ', 'Abcdefghij1!xy'),
        isNotNull,
      );
      expect(
        AccountFormValidators.confirmation('Abcdefghij1!xy', 'Abcdefghij1!xy'),
        isNull,
      );
    },
  );
}
