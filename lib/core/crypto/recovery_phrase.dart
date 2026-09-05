import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../errors.dart';
import '../result.dart';

/// BIP39-style 128-bit mnemonic (12 words) used as a wrapping secret for OAuth
/// and passkey users when WebAuthn PRF is unavailable.
class RecoveryPhrase {
  const RecoveryPhrase(this.words);

  final List<String> words;

  String get display => words.join(' ');

  static Result<RecoveryPhrase, CryptoFailure> fromEntropy({
    required Uint8List entropy,
    required List<String> wordlist,
  }) {
    if (entropy.length != 16) {
      return const Err(CryptoFailure('Entropy must be 16 bytes.'));
    }
    if (wordlist.length != 2048) {
      return const Err(CryptoFailure('Wordlist must contain 2048 words.'));
    }
    final indices = _bitsToIndices(_entropyWithChecksum(entropy));
    return Ok(RecoveryPhrase([for (final i in indices) wordlist[i]]));
  }

  static Result<RecoveryPhrase, CryptoFailure> parse({
    required String phrase,
    required List<String> wordlist,
  }) {
    final words = phrase.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.length != 12) {
      return const Err(CryptoFailure('Recovery phrase must be 12 words.'));
    }
    if (wordlist.length != 2048) {
      return const Err(CryptoFailure('Wordlist must contain 2048 words.'));
    }
    final lookup = <String, int>{
      for (var i = 0; i < wordlist.length; i++) wordlist[i]: i,
    };
    final indices = <int>[];
    for (final word in words) {
      final index = lookup[word];
      if (index == null) {
        return const Err(CryptoFailure('Unknown recovery word.'));
      }
      indices.add(index);
    }
    final entropy = _indicesToEntropy(indices);
    final checksumOk = switch (fromEntropy(
      entropy: entropy,
      wordlist: wordlist,
    )) {
      Ok(:final value) => value.display == words.join(' '),
      Err() => false,
    };
    if (!checksumOk) {
      return const Err(CryptoFailure('Recovery phrase checksum failed.'));
    }
    return Ok(RecoveryPhrase(words));
  }

  Result<Uint8List, CryptoFailure> toEntropy(List<String> wordlist) {
    return parse(phrase: display, wordlist: wordlist).when(
      ok: (phrase) {
        final lookup = <String, int>{
          for (var i = 0; i < wordlist.length; i++) wordlist[i]: i,
        };
        final indices = [for (final word in phrase.words) lookup[word]!];
        return Ok(_indicesToEntropy(indices));
      },
      err: Err.new,
    );
  }

  static Uint8List _entropyWithChecksum(Uint8List entropy) {
    final hash = sha256.convert(entropy).bytes;
    final bits = <int>[];
    for (final byte in entropy) {
      for (var i = 7; i >= 0; i--) {
        bits.add((byte >> i) & 1);
      }
    }
    for (var i = 7; i >= 4; i--) {
      bits.add((hash.first >> i) & 1);
    }
    return Uint8List.fromList(bits);
  }

  static List<int> _bitsToIndices(Uint8List bits) {
    final indices = <int>[];
    for (var i = 0; i < 12; i++) {
      var value = 0;
      for (var j = 0; j < 11; j++) {
        value = (value << 1) | bits[i * 11 + j];
      }
      indices.add(value);
    }
    return indices;
  }

  static Uint8List _indicesToEntropy(List<int> indices) {
    final bits = <int>[];
    for (final index in indices) {
      for (var i = 10; i >= 0; i--) {
        bits.add((index >> i) & 1);
      }
    }
    final entropy = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      var value = 0;
      for (var j = 0; j < 8; j++) {
        value = (value << 1) | bits[i * 8 + j];
      }
      entropy[i] = value;
    }
    return entropy;
  }
}
