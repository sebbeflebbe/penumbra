import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/features/auth/domain/eid.dart';

void main() {
  test('sanitizeEidClaims drops national-id keys and keeps opaque sub', () {
    final clean = sanitizeEidClaims({
      'sub': 'opaque-subject',
      'email': 'ada@example.invalid',
      'ssn': '197001011234',
      'personalNumber': '19700101-1234',
      'personal_number': '7001011234',
      'swedishPersonalIdentityNumber': '197001011234',
      'name': 'Ada',
    });
    expect(clean['sub'], 'opaque-subject');
    expect(clean['email'], 'ada@example.invalid');
    expect(clean.containsKey('ssn'), isFalse);
    expect(clean.containsKey('personalNumber'), isFalse);
    expect(clean.containsKey('personal_number'), isFalse);
    expect(clean.containsKey('swedishPersonalIdentityNumber'), isFalse);
  });

  test(
    'unset BankID copy is honest and does not mention a password fallback',
    () {
      final failure = bankIdUnavailable(configured: false);
      expect(failure.message, contains('not configured'));
      expect(failure.message.toLowerCase(), isNot(contains('falling back')));
    },
  );
}
