/// Explicit success/failure without throwing across domain boundaries.
sealed class Result<S, F> {
  const Result();

  T when<T>({
    required T Function(S value) ok,
    required T Function(F failure) err,
  }) {
    return switch (this) {
      Ok(:final value) => ok(value),
      Err(:final failure) => err(failure),
    };
  }

  S? get okOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  F? get errOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  bool get isOk => this is Ok<S, F>;
  bool get isErr => this is Err<S, F>;
}

final class Ok<S, F> extends Result<S, F> {
  const Ok(this.value);
  final S value;
}

final class Err<S, F> extends Result<S, F> {
  const Err(this.failure);
  final F failure;
}
