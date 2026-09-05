import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../errors.dart';
import '../result.dart';

/// AES-256-GCM ciphertext stored as `nonce.cipher.mac` (base64url, no padding).
final class Ciphertext {
  const Ciphertext({
    required this.nonce,
    required this.cipherBytes,
    required this.mac,
  });

  final Uint8List nonce;
  final Uint8List cipherBytes;
  final Uint8List mac;

  String toStorage() {
    String enc(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
    return '${enc(nonce)}.${enc(cipherBytes)}.${enc(mac)}';
  }

  static Result<Ciphertext, CryptoFailure> fromStorage(String stored) {
    final parts = stored.split('.');
    if (parts.length != 3) {
      return const Err(CryptoFailure('Malformed ciphertext.'));
    }
    try {
      return Ok(
        Ciphertext(
          nonce: Uint8List.fromList(_decode(parts[0])),
          cipherBytes: Uint8List.fromList(_decode(parts[1])),
          mac: Uint8List.fromList(_decode(parts[2])),
        ),
      );
    } on FormatException {
      return const Err(CryptoFailure('Malformed ciphertext encoding.'));
    }
  }

  static List<int> _decode(String value) {
    final pad = (4 - value.length % 4) % 4;
    return base64Url.decode(value + ('=' * pad));
  }
}

/// Encrypts board node payloads. The DEK never leaves the client.
class PayloadCipher {
  PayloadCipher({AesGcm? algorithm}) : _algorithm = algorithm ?? AesGcm.with256bits();

  final AesGcm _algorithm;

  Future<Result<Ciphertext, CryptoFailure>> encrypt({
    required List<int> dekBytes,
    required List<int> plaintext,
  }) async {
    if (dekBytes.length != 32) {
      return const Err(CryptoFailure('DEK must be 32 bytes.'));
    }
    try {
      final secretKey = SecretKey(dekBytes);
      final nonce = _algorithm.newNonce();
      final box = await _algorithm.encrypt(
        plaintext,
        secretKey: secretKey,
        nonce: nonce,
      );
      return Ok(
        Ciphertext(
          nonce: Uint8List.fromList(box.nonce),
          cipherBytes: Uint8List.fromList(box.cipherText),
          mac: Uint8List.fromList(box.mac.bytes),
        ),
      );
    } on Object {
      return const Err(CryptoFailure('Encryption failed.'));
    }
  }

  Future<Result<Uint8List, CryptoFailure>> decrypt({
    required List<int> dekBytes,
    required Ciphertext ciphertext,
  }) async {
    if (dekBytes.length != 32) {
      return const Err(CryptoFailure('DEK must be 32 bytes.'));
    }
    try {
      final box = SecretBox(
        ciphertext.cipherBytes,
        nonce: ciphertext.nonce,
        mac: Mac(ciphertext.mac),
      );
      final clear = await _algorithm.decrypt(box, secretKey: SecretKey(dekBytes));
      return Ok(Uint8List.fromList(clear));
    } on SecretBoxAuthenticationError {
      return const Err(CryptoFailure('Authentication tag mismatch.'));
    } on Object {
      return const Err(CryptoFailure('Decryption failed.'));
    }
  }

  Future<SecretKey> newDek() => _algorithm.newSecretKey();
}
