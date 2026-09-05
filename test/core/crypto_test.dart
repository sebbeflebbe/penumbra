import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/core/crypto/payload_cipher.dart';
import 'package:penumbra/core/crypto/recovery_phrase.dart';

List<String> loadWordlist() =>
    File('assets/crypto/bip39_english.txt').readAsLinesSync();

void main() {
  late List<String> wordlist;
  late PayloadCipher cipher;

  setUp(() {
    wordlist = loadWordlist();
    cipher = PayloadCipher();
  });

  test('wordlist has 2048 unique words', () {
    expect(wordlist, hasLength(2048));
    expect(wordlist.toSet(), hasLength(2048));
  });

  test('AES-GCM round-trips and rejects tampering', () async {
    final dek = List<int>.generate(32, (i) => i + 1);
    final encrypted = await cipher.encrypt(
      dekBytes: dek,
      plaintext: 'quiet thoughts'.codeUnits,
    );
    final cipherText = encrypted.okOrNull!;
    final decrypted = await cipher.decrypt(
      dekBytes: dek,
      ciphertext: cipherText,
    );
    expect(String.fromCharCodes(decrypted.okOrNull!), 'quiet thoughts');

    final tampered = Ciphertext(
      nonce: cipherText.nonce,
      cipherBytes: Uint8List.fromList([...cipherText.cipherBytes]..[0] ^= 0x01),
      mac: cipherText.mac,
    );
    final failed = await cipher.decrypt(dekBytes: dek, ciphertext: tampered);
    expect(failed.isErr, isTrue);
  });

  test('ciphertext storage is reversible and contains no plaintext', () async {
    final dek = List<int>.generate(32, (i) => 32 - i);
    final encrypted = await cipher.encrypt(
      dekBytes: dek,
      plaintext: 'secret-card'.codeUnits,
    );
    final stored = encrypted.okOrNull!.toStorage();
    expect(stored.contains('secret-card'), isFalse);
    final parsed = Ciphertext.fromStorage(stored).okOrNull!;
    final decrypted = await cipher.decrypt(dekBytes: dek, ciphertext: parsed);
    expect(String.fromCharCodes(decrypted.okOrNull!), 'secret-card');
  });

  test('recovery phrase encodes 16 bytes with a checksum', () {
    final entropy = Uint8List.fromList(List<int>.generate(16, (i) => i * 3));
    final phrase = RecoveryPhrase.fromEntropy(
      entropy: entropy,
      wordlist: wordlist,
    ).okOrNull!;
    expect(phrase.words, hasLength(12));
    final parsed = RecoveryPhrase.parse(
      phrase: phrase.display,
      wordlist: wordlist,
    );
    expect(parsed.isOk, isTrue);
    expect(parsed.okOrNull!.toEntropy(wordlist).okOrNull, entropy);
  });

  test('recovery phrase rejects a flipped word', () {
    final entropy = Uint8List.fromList(List<int>.filled(16, 7));
    final phrase = RecoveryPhrase.fromEntropy(
      entropy: entropy,
      wordlist: wordlist,
    ).okOrNull!;
    final mutated = [...phrase.words]
      ..[0] = phrase.words[0] == 'abandon' ? 'ability' : 'abandon';
    final parsed = RecoveryPhrase.parse(
      phrase: mutated.join(' '),
      wordlist: wordlist,
    );
    expect(parsed.isErr, isTrue);
  });
}
