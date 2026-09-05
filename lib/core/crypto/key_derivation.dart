import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../errors.dart';
import '../result.dart';

/// Argon2id wrapping-key derivation. Parameters are injectable so tests stay fast
/// while production uses a stronger memory cost (NIS2-style crypto policy).
class KeyDerivation {
  KeyDerivation({Argon2id? kdf})
    : _kdf =
          kdf ??
          Argon2id(
            parallelism: 1,
            memory: 19456,
            iterations: 2,
            hashLength: 32,
          );

  final Argon2id _kdf;

  /// Test-only constructor: tiny memory so unit tests do not stall.
  factory KeyDerivation.testing() => KeyDerivation(
    kdf: Argon2id(parallelism: 1, memory: 8, iterations: 1, hashLength: 32),
  );

  Future<Result<Uint8List, CryptoFailure>> deriveWrappingKey({
    required String secret,
    required List<int> salt,
  }) async {
    if (secret.isEmpty) {
      return const Err(CryptoFailure('Wrapping secret is empty.'));
    }
    if (salt.length < 8) {
      return const Err(CryptoFailure('Salt is too short.'));
    }
    try {
      final key = await _kdf.deriveKeyFromPassword(
        password: secret,
        nonce: salt,
      );
      final bytes = await key.extractBytes();
      return Ok(Uint8List.fromList(bytes));
    } on Object {
      return const Err(CryptoFailure('Key derivation failed.'));
    }
  }
}
