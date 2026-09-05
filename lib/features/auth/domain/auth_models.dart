import '../../../core/result.dart';

enum AuthMethod { password, magicLink, google, github, passkey }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.methods,
    this.email,
    this.displayName,
    this.needsRecoveryPhraseReveal = false,
  });

  final String id;
  final String? email;
  final String? displayName;
  final Set<AuthMethod> methods;
  final bool needsRecoveryPhraseReveal;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    Set<AuthMethod>? methods,
    bool? needsRecoveryPhraseReveal,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      methods: methods ?? this.methods,
      needsRecoveryPhraseReveal:
          needsRecoveryPhraseReveal ?? this.needsRecoveryPhraseReveal,
    );
  }
}

sealed class AuthFailure {
  const AuthFailure(this.message);
  final String message;
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([
    super.message = 'Those credentials were not accepted.',
  ]);
}

final class RateLimitedFailure extends AuthFailure {
  const RateLimitedFailure([
    super.message = 'Too many attempts. Wait a moment.',
  ]);
}

final class AuthCancelledFailure extends AuthFailure {
  const AuthCancelledFailure([super.message = 'Sign-in was cancelled.']);
}

final class AuthUnavailableFailure extends AuthFailure {
  const AuthUnavailableFailure([
    super.message = 'This sign-in method is not available here.',
  ]);
}

final class WeakSecretFailure extends AuthFailure {
  const WeakSecretFailure([super.message = 'Choose a longer secret.']);
}

abstract class AuthRepository {
  Stream<AuthUser?> watch();
  AuthUser? get current;

  Future<Result<AuthUser, AuthFailure>> signInWithPassword({
    required String email,
    required String password,
  });
  Future<Result<AuthUser, AuthFailure>> signUpWithPassword({
    required String email,
    required String password,
  });
  Future<Result<void, AuthFailure>> sendMagicLink({required String email});
  Future<Result<AuthUser, AuthFailure>> signInWithGoogle();
  Future<Result<AuthUser, AuthFailure>> signInWithGitHub();
  Future<Result<AuthUser, AuthFailure>> signInWithPasskey();
  Future<Result<void, AuthFailure>> registerPasskey();
  Future<Result<AuthUser, AuthFailure>> enterDemoStudio();
  Future<Result<void, AuthFailure>> signOut();
  Future<Result<void, AuthFailure>> reauthenticate({String? password});
  Future<Result<void, AuthFailure>> deleteAccount();

  /// Twelve-word phrase shown once for OAuth/passkey wrapping. Null otherwise.
  String? get pendingRecoveryPhrase;

  /// Clears [pendingRecoveryPhrase] after the person has had a chance to copy it.
  void acknowledgeRecoveryPhrase();
}
