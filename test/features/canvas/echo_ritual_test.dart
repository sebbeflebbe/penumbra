import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/app/app.dart';
import 'package:penumbra/app/providers.dart';
import 'package:penumbra/features/canvas/domain/echo_composer.dart';
import 'package:penumbra/features/legal/presentation/legal_catalog.dart';
import 'package:penumbra/features/studio/in_memory_studio.dart';

InMemoryStudio studio() =>
    InMemoryStudio(wordlist: File('assets/crypto/bip39_english.txt').readAsLinesSync());

Future<void> pumpStudio(WidgetTester tester, InMemoryStudio s) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
    disableAnimations: true,
  );
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
  testWidgets('summoning an echo with the local composer places a companion slip', (tester) async {
    await pumpStudio(tester, studio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Quiet thoughts'), findsWidgets);
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Private by default.'), findsWidgets);

    await tester.tap(find.text('Private by default.').first);
    await tester.pump();
    await tester.ensureVisible(find.text('Summon an echo'));
    await tester.tap(find.text('Summon an echo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final echo = LocalEchoComposer.rephrase('Private by default.');
    expect(find.text(echo), findsWidgets);
    expect(find.text('Private by default.'), findsWidgets);
    expect(find.text('Summon an echo'), findsNothing);
    expect(find.text('Compose'), findsOneWidget);
    expect(find.text('Place'), findsOneWidget);

    await tester.tap(find.text(echo).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Dismiss'), findsOneWidget);
  });

  test('privacy names the optional Google processor and consent basis', () {
    expect(LegalCatalog.privacy.body, contains('Google LLC'));
    expect(LegalCatalog.privacy.body, contains('Art. 6(1)(a)'));
    expect(LegalCatalog.privacy.body, contains('rest of the board is not sent'));
    expect(LegalCatalog.security.body, contains('ADR-007'));
    expect(LegalCatalog.accessibility.body, contains('28 June 2025'));
    expect(LegalCatalog.accessibility.body, contains('do not claim full EAA conformance'));
  });
}
