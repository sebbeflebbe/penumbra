import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:penumbra/core/errors.dart';
import 'package:penumbra/features/canvas/domain/echo_composer.dart';

void main() {
  test(
    'local echo is non-empty, not a copy, and at most sixty words',
    () async {
      const source = 'Private by default.';
      final result = await const LocalEchoComposer().echo(source: source);
      final text = result.okOrNull!;
      expect(text, isNotEmpty);
      expect(text, isNot(source));
      expect(
        text.toLowerCase(),
        isNot(contains(source.toLowerCase().replaceAll('.', ''))),
      );
      expect(text.split(RegExp(r'\s+')).length, lessThanOrEqualTo(60));
      expect(LocalEchoComposer.rephrase(source), text);
      expect(text, isNot(contains('The same weather:')));
    },
  );

  test(
    'local echo offers a philosophical companion instead of concatenating the source',
    () async {
      final sad = LocalEchoComposer.rephrase('I am sad');
      expect(sad.toLowerCase(), isNot(contains('i am sad')));
      expect(
        sad,
        anyOf(contains('Sorrow'), contains('hurts'), contains('Grief')),
      );

      final problem = LocalEchoComposer.rephrase('this is a problem');
      expect(problem.toLowerCase(), isNot(contains('this is a problem')));
      expect(
        problem,
        anyOf(
          contains('difficulty'),
          contains('problem is often'),
          contains('trouble'),
        ),
      );

      expect(sad, isNot(problem));
    },
  );

  test('local echo refuses an empty slip', () async {
    final result = await const LocalEchoComposer().echo(source: '   ');
    expect(result.errOrNull, isA<ValidationFailure>());
  });

  test('factory without a key stays local', () {
    final composer = penumbraEchoComposer(geminiApiKey: '', systemPrompt: 'x');
    expect(composer, isA<LocalEchoComposer>());
    expect(composer.remote, isFalse);
  });

  test('gemini composer posts only the source slip', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        json.encode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'A quieter weather. The thought still sits.'},
                ],
              },
            },
          ],
        }),
        200,
      );
    });
    final composer = GeminiEchoComposer(
      apiKey: 'test-key',
      systemPrompt: 'Be brief.',
      client: client,
    );
    final result = await composer.echo(source: 'Private by default.');
    expect(result.okOrNull, 'A quieter weather. The thought still sits.');
    expect(captured!.url.host, 'generativelanguage.googleapis.com');
    expect(captured!.url.path, contains('gemini-3.5-flash-lite'));
    expect(captured!.headers['x-goog-api-key'], 'test-key');
    expect(captured!.body, contains('Private by default.'));
    expect(captured!.body, isNot(contains('Accessible by design')));
    expect(captured!.body, contains('Be brief.'));
  });

  test('gemini 4xx fails closed', () async {
    final client = MockClient((request) async => http.Response('nope', 403));
    final composer = GeminiEchoComposer(
      apiKey: 'k',
      systemPrompt: 'x',
      client: client,
    );
    final result = await composer.echo(source: 'A thought.');
    expect(result.errOrNull, isA<UnavailableFailure>());
  });

  test('empty model fails closed', () async {
    final client = MockClient(
      (request) async =>
          http.Response(json.encode({'candidates': <Object>[]}), 200),
    );
    final composer = GeminiEchoComposer(
      apiKey: 'k',
      systemPrompt: 'x',
      client: client,
    );
    final result = await composer.echo(source: 'A thought.');
    expect(result.errOrNull, isA<UnavailableFailure>());
  });
}
