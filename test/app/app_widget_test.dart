import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/app/app.dart';
import 'package:penumbra/app/providers.dart';
import 'package:penumbra/features/studio/in_memory_studio.dart';

InMemoryStudio studio() =>
    InMemoryStudio(wordlist: File('assets/crypto/bip39_english.txt').readAsLinesSync());

Future<void> pumpApp(WidgetTester tester, InMemoryStudio s) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
    disableAnimations: true,
  );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [studioProvider.overrideWithValue(s)],
      child: const PenumbraApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('landing exposes the primary actions', (tester) async {
    await pumpApp(tester, studio());
    expect(find.textContaining('quiet studio'), findsOneWidget);
    expect(find.text('Enter the studio'), findsOneWidget);
    expect(find.text('Read the making of'), findsOneWidget);
  });

  testWidgets('making-of lists chapters with control names', (tester) async {
    await pumpApp(tester, studio());
    await tester.tap(find.text('Making of'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Making of Penumbra'), findsWidgets);
    expect(find.textContaining('ADR-001'), findsOneWidget);
  });

  testWidgets('demo studio reaches a named board', (tester) async {
    await pumpApp(tester, studio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Quiet thoughts'), findsWidgets);
  });

  testWidgets('sign-in offers passkey, Google, GitHub, password and magic link', (tester) async {
    await pumpApp(tester, studio());
    await tester.tap(find.text('Sign in').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Continue with a passkey'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with GitHub'), findsOneWidget);
    expect(find.text('Email me a magic link'), findsOneWidget);
    await tester.ensureVisible(find.text('Use a password instead'));
    await tester.tap(find.text('Use a password instead'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text('Sign in with password'));
    expect(find.text('Sign in with password'), findsOneWidget);
  });

  testWidgets('reduced motion uses a static teaser', (tester) async {
    await pumpApp(tester, studio());
    expect(find.byKey(const Key('penumbra-teaser-living')), findsNothing);
    expect(find.byKey(const Key('penumbra-teaser')), findsOneWidget);
    final start = tester.binding.transientCallbackCount;
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.transientCallbackCount, start);
  });

  testWidgets('appearance control names the current and next theme', (tester) async {
    await pumpApp(tester, studio());
    expect(find.bySemanticsLabel('Appearance: System. Switch to Light.'), findsOneWidget);
  });
}
