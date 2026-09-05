import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/app/app.dart';
import 'package:penumbra/app/providers.dart';
import 'package:penumbra/features/canvas/domain/echo_composer.dart';
import 'package:penumbra/features/studio/in_memory_studio.dart';

InMemoryStudio studio() => InMemoryStudio(
  wordlist: File('assets/crypto/bip39_english.txt').readAsLinesSync(),
);

Future<void> pumpSignedIn(WidgetTester tester, InMemoryStudio s) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioProvider.overrideWithValue(s),
        echoComposerProvider.overrideWithValue(const LocalEchoComposer()),
      ],
      child: const PenumbraApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('recovery phrase can be acknowledged from the canvas', (
    tester,
  ) async {
    final s = studio();
    await s.signInWithGitHub();
    await s.create(title: 'Quiet thoughts');
    await pumpSignedIn(tester, s);
    await tester.tap(find.text('Boards').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('I have saved this phrase'), findsOneWidget);
    await tester.tap(find.text('I have saved this phrase'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('I have saved this phrase'), findsNothing);
    expect(s.pendingRecoveryPhrase, isNull);
  });
}
