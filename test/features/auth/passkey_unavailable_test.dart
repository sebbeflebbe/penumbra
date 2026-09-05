import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/features/auth/domain/auth_models.dart';
import 'package:penumbra/features/auth/domain/passkey_ceremony.dart';

class _FakeCeremony implements PasskeyCeremony {
  _FakeCeremony({required this.supported});

  final bool supported;

  @override
  bool get isSupported => supported;

  @override
  Future<Map<String, dynamic>> create(
    Map<String, dynamic> publicKeyOptions,
  ) async => publicKeyOptions;

  @override
  Future<Map<String, dynamic>> get(
    Map<String, dynamic> publicKeyOptions,
  ) async => publicKeyOptions;
}

void main() {
  test(
    'unsupported browsers get honest copy, never a silent password fallback',
    () {
      final failure = passkeyUnavailable(
        supported: _FakeCeremony(supported: false).isSupported,
      );
      expect(failure, isA<AuthUnavailableFailure>());
      expect(failure.message, contains('cannot create a passkey'));
      expect(failure.message.toLowerCase(), isNot(contains('falling back')));
    },
  );

  test('a disabled Supabase project is named as the operator gap', () {
    final failure = passkeyUnavailable(supported: true, projectDisabled: true);
    expect(failure.message, contains('Supabase project'));
  });
}
