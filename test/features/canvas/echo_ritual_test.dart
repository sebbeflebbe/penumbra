import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/core/errors.dart';
import 'package:penumbra/core/result.dart';
import 'package:penumbra/features/canvas/domain/echo_composer.dart';
import 'package:penumbra/features/legal/presentation/legal_catalog.dart';
import 'package:penumbra/features/privacy/domain/privacy_models.dart';

import '../../helpers/pump_studio.dart';

void main() {
  testWidgets(
    'summoning an echo with the local composer places a companion slip',
    (tester) async {
      await pumpStudio(tester, memoryStudio());
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
    },
  );

  test('privacy names the optional Google processor and consent basis', () {
    expect(LegalCatalog.privacy.body, contains('Google LLC'));
    expect(LegalCatalog.privacy.body, contains('Art. 6(1)(a)'));
    expect(LegalCatalog.privacy.body, contains('Art. 7(3)'));
    expect(LegalCatalog.privacy.body, contains('Art. 16'));
    expect(LegalCatalog.privacy.body, contains('JSON file'));
    expect(
      LegalCatalog.privacy.body,
      contains('rest of the board is not sent'),
    );
    expect(LegalCatalog.security.body, contains('ADR-007'));
    expect(LegalCatalog.accessibility.body, contains('28 June 2025'));
    expect(
      LegalCatalog.accessibility.body,
      contains('do not claim full EAA conformance'),
    );
  });

  testWidgets('remote echo asks for Art. 6(1)(a) consent and records it', (
    tester,
  ) async {
    final s = memoryStudio();
    await pumpStudio(tester, s, composer: const _RemoteEcho());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Private by default.').first);
    await tester.pump();
    await tester.ensureVisible(find.text('Summon an echo'));
    await tester.tap(find.text('Summon an echo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Google LLC'), findsOneWidget);
    expect(find.textContaining('Art. 6(1)(a)'), findsOneWidget);
    await tester.tap(find.text('Send this thought'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('A remote aside.'), findsWidgets);
    expect(
      hasGrantedConsent((await s.consents()).okOrNull!, ConsentKind.remoteEcho),
      isTrue,
    );
  });
}

class _RemoteEcho implements EchoComposer {
  const _RemoteEcho();

  @override
  bool get remote => true;

  @override
  Future<Result<String, AppFailure>> echo({required String source}) async =>
      const Ok('A remote aside.');
}
