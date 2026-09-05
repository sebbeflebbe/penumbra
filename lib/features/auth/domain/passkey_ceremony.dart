import 'auth_models.dart';

const kPasskeyUnavailableMessage =
    'This browser cannot create a passkey. Use Google, GitHub, a magic link, or a password.';

const kPasskeyProjectDisabledMessage =
    'Passkeys are not enabled on this Supabase project yet. Use Google, GitHub, a magic link, or a password.';

/// Platform WebAuthn ceremony. Binary-free JSON maps in W3C Level 3 form.
abstract class PasskeyCeremony {
  bool get isSupported;

  Future<Map<String, dynamic>> create(Map<String, dynamic> publicKeyOptions);

  Future<Map<String, dynamic>> get(Map<String, dynamic> publicKeyOptions);
}

class PasskeyCancelled implements Exception {
  const PasskeyCancelled();
}

class UnsupportedPasskeyCeremony implements PasskeyCeremony {
  const UnsupportedPasskeyCeremony();

  @override
  bool get isSupported => false;

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> publicKeyOptions) {
    throw const PasskeyCancelled();
  }

  @override
  Future<Map<String, dynamic>> get(Map<String, dynamic> publicKeyOptions) {
    throw const PasskeyCancelled();
  }
}

AuthFailure passkeyUnavailable({
  required bool supported,
  bool projectDisabled = false,
}) {
  if (projectDisabled)
    return const AuthUnavailableFailure(kPasskeyProjectDisabledMessage);
  if (!supported)
    return const AuthUnavailableFailure(kPasskeyUnavailableMessage);
  return const AuthUnavailableFailure(kPasskeyUnavailableMessage);
}
