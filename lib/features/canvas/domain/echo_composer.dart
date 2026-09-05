import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/errors.dart';
import '../../../core/result.dart';

/// Fallback system instruction when the asset prompt is not loaded.
const kPenumbraEchoSystemPrompt = '''
You are the half-light of Penumbra — a quiet companion to one private thought.
The writer has already said the words. Do not quote them back. Answer beside them.
Voice: restraint, dusk, paper. A short philosophical seeing, not a pep talk.
No cheer, no coaching, no lists, no questions, no "as an AI", no "I understand".
One to three sentences. At most sixty words.
Do not add facts, names, places, or advice the writer did not give.
''';

abstract class EchoComposer {
  const EchoComposer();

  /// Whether this composer sends the slip to a remote processor.
  bool get remote;

  Future<Result<String, AppFailure>> echo({required String source});
}

EchoComposer penumbraEchoComposer({
  required String geminiApiKey,
  required String systemPrompt,
  http.Client? client,
}) {
  if (geminiApiKey.trim().isEmpty) return const LocalEchoComposer();
  return GeminiEchoComposer(
    apiKey: geminiApiKey,
    systemPrompt: systemPrompt,
    client: client,
  );
}

class LocalEchoComposer implements EchoComposer {
  const LocalEchoComposer();

  @override
  bool get remote => false;

  @override
  Future<Result<String, AppFailure>> echo({required String source}) async {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Nothing to echo.'));
    }
    return Ok(rephrase(trimmed));
  }

  /// Deterministic companion voice. A quiet philosophical aside, never a copy of the slip.
  static String rephrase(String source) {
    final trimmed = source.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return 'A stillness. Nothing to add.';
    final family = _family(trimmed.toLowerCase());
    final lines = _companions[family]!;
    var line = lines[trimmed.hashCode.abs() % lines.length];
    if (line.toLowerCase() == trimmed.toLowerCase()) {
      line = 'Meaning often waits where we stop improving the sentence.';
    }
    return clipWords(line);
  }

  static String _family(String lower) {
    bool has(List<String> needles) => needles.any(lower.contains);
    if (has(const [
      'sad',
      'sorrow',
      'grief',
      'lonely',
      'alone',
      'miss you',
      'despair',
      'cry',
      'hurt',
    ])) {
      return 'sorrow';
    }
    if (has(const [
      'problem',
      'stuck',
      'fail',
      'wrong',
      'broken',
      'worry',
      'anxi',
      'fear',
      'afraid',
      'issue',
    ])) {
      return 'trouble';
    }
    if (has(const ['angry', 'anger', 'rage', 'hate', 'furious']))
      return 'anger';
    if (has(const ['private', 'secret', 'hidden', 'hide', 'unseen']))
      return 'privacy';
    if (has(const [
      'lost',
      'unsure',
      'maybe',
      "don't know",
      'perhaps',
      'confused',
    ]))
      return 'doubt';
    if (has(const ['love', 'dear', 'miss', 'heart'])) return 'tender';
    if (has(const ['hope', 'wish', 'want', 'need'])) return 'longing';
    return 'still';
  }

  static const _companions = <String, List<String>>{
    'sorrow': [
      'Sorrow is a kind of weather. It does not ask to be solved, only sat with until the room is dim enough.',
      'What hurts is already a form of attention. Let it occupy the hour without being improved.',
      'Grief keeps its own clock. Company, not brightness, is the older courtesy.',
    ],
    'trouble': [
      'A difficulty is not yet a verdict. It is a knot, and knots still remember the hands that tied them.',
      'What we name a problem is often a thought that wanted more room than the day allowed.',
      'Stand next to the trouble without dressing it. Some shapes only declare themselves in shade.',
    ],
    'anger': [
      'Heat is information. It need not become a speech to be true.',
      'Anger is a boundary arriving late. Let it stand; it will tell you what was crossed.',
      'The flare will cool. What remains is the outline of what mattered.',
    ],
    'privacy': [
      'Some thoughts belong to the inner room. Visibility is not the same as truth.',
      'What stays unspoken is not unfinished. Silence is a way of keeping.',
      'A closed door is also care. Not every light is owed to the street.',
    ],
    'doubt': [
      'Uncertainty is not a failure of the map. It is the land still unlit.',
      'Not knowing can be a honest posture. The next step often waits in that pause.',
      'Fog is still weather. Walk as if the ground continues, because it does.',
    ],
    'tender': [
      'Affection does not need an audience. It is already a complete sentence.',
      'What is loved is often kept in half-light so it will not be spent too quickly.',
      'Tenderness is a kind of courage that refuses spectacle.',
    ],
    'longing': [
      'Want is a direction, not a defect. Let it point without forcing the arrival.',
      'Desire names a distance. The distance, too, is part of the thought.',
      'To hope is to leave a window unlatched. That is enough for dusk.',
    ],
    'still': [
      'The thought has already arrived. Philosophy, here, is only the patience not to explain it away.',
      'Meaning often waits at the edge of a sentence, where we stop improving it.',
      'Hold the words as they are. A quiet seeing is already a reply.',
    ],
  };
}

class GeminiEchoComposer implements EchoComposer {
  GeminiEchoComposer({
    required this.apiKey,
    required this.systemPrompt,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  static final endpoint = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent',
  );

  final String apiKey;
  final String systemPrompt;
  final Duration timeout;
  final http.Client _client;

  @override
  bool get remote => true;

  @override
  Future<Result<String, AppFailure>> echo({required String source}) async {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Nothing to echo.'));
    }
    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: json.encode({
              'system_instruction': {
                'parts': [
                  {'text': systemPrompt},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': trimmed},
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.6, 'maxOutputTokens': 160},
            }),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const Err(UnavailableFailure('The half-light did not answer.'));
      }
      final decoded = json.decode(response.body);
      final text = _extractText(decoded);
      if (text == null || text.trim().isEmpty) {
        return const Err(UnavailableFailure('The half-light did not answer.'));
      }
      return Ok(clipWords(text));
    } on TimeoutException {
      return const Err(UnavailableFailure('The half-light timed out.'));
    } catch (_) {
      return const Err(UnavailableFailure('The half-light did not answer.'));
    }
  }

  String? _extractText(Object? decoded) {
    if (decoded is! Map) return null;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map) return null;
    final content = first['content'];
    if (content is! Map) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    final raw = buffer.toString().trim();
    if (raw.isEmpty) return null;
    return raw.replaceAll(RegExp(r'^["“]|["”]$'), '');
  }
}

String clipWords(String text, {int max = 60}) {
  final words = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.length <= max) return words.join(' ');
  return '${words.take(max).join(' ')}…';
}
