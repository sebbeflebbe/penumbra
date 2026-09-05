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

Future<void> pumpStudio(WidgetTester tester, InMemoryStudio s) async {
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

Future<void> openSeededCanvas(WidgetTester tester) async {
  await tester.tap(find.text('Enter the studio'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('a selected human slip can be deleted after confirm', (
    tester,
  ) async {
    await pumpStudio(tester, studio());
    await openSeededCanvas(tester);
    expect(find.text('Private by default.'), findsWidgets);

    await tester.tap(find.text('Private by default.').first);
    await tester.pump();
    await tester.ensureVisible(find.text('Delete'));
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Delete this note'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Private by default.'), findsNothing);
  });

  testWidgets('editing a human slip updates the Index', (tester) async {
    await pumpStudio(tester, studio());
    await openSeededCanvas(tester);
    await tester.tap(find.text('Private by default.').first);
    await tester.pump();
    await tester.ensureVisible(find.text('Edit'));
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.enterText(
      find.byType(EditableText).last,
      'Corrected in the half-light.',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Corrected in the half-light.'), findsWidgets);
  });
}
