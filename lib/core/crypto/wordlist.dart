import 'package:flutter/services.dart';

class Bip39Wordlist {
  const Bip39Wordlist(this.words);

  final List<String> words;

  static const assetPath = 'assets/crypto/bip39_english.txt';

  static Future<Bip39Wordlist> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final words = raw
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (words.length != 2048) {
      throw StateError(
        'BIP39 wordlist must contain 2048 words, found ${words.length}.',
      );
    }
    return Bip39Wordlist(words);
  }
}
