/// Domain-level failures. Never include secrets, recovery phrases, or card bodies.
sealed class AppFailure {
  const AppFailure(this.code, this.message);
  final String code;
  final String message;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(String message) : super('validation', message);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(String message) : super('not_found', message);
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure(String message) : super('forbidden', message);
}

final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure([String message = 'Sign in required.'])
    : super('unauthenticated', message);
}

final class CryptoFailure extends AppFailure {
  const CryptoFailure(String message) : super('crypto', message);
}

final class UnavailableFailure extends AppFailure {
  const UnavailableFailure(String message) : super('unavailable', message);
}
