import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/app/providers.dart';
import 'package:penumbra/core/errors.dart';
import 'package:penumbra/core/result.dart';
import 'package:penumbra/features/auth/domain/auth_models.dart';
import 'package:penumbra/features/canvas/domain/echo_composer.dart';
import 'package:penumbra/features/privacy/domain/privacy_models.dart';

import '../../helpers/pump_studio.dart';

class _RemoteEcho implements EchoComposer {
  const _RemoteEcho();

  @override
  bool get remote => true;

  @override
  Future<Result<String, AppFailure>> echo({required String source}) async =>
      const Ok('A remote aside.');
}

void main() {
  testWidgets('withdrawing echo consent asks again on the next summon', (
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
    await tester.tap(find.text('Send this thought'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      hasGrantedConsent((await s.consents()).okOrNull!, ConsentKind.remoteEcho),
      isTrue,
    );

    await tester.tap(find.text('Privacy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('Withdraw echo consent'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Withdraw echo consent'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Withdraw consent'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      hasGrantedConsent((await s.consents()).okOrNull!, ConsentKind.remoteEcho),
      isFalse,
    );
  });

  testWidgets('password users can add a passkey from Privacy', (tester) async {
    final s = memoryStudio();
    await s.signUpWithPassword(
      email: 'ada@penumbra.studio',
      password: 'long-enough-1',
    );
    await pumpStudio(tester, s);
    await tester.tap(find.text('Privacy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('Add a passkey'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Add a passkey'), findsOneWidget);
    await tester.tap(find.text('Add a passkey'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Passkey added.'), findsOneWidget);
    expect(s.current?.methods, contains(AuthMethod.passkey));
  });

  testWidgets('display name saves and export can download JSON', (
    tester,
  ) async {
    final s = memoryStudio();
    await s.signUpWithPassword(
      email: 'ada@penumbra.studio',
      password: 'long-enough-1',
    );
    String? downloaded;
    await pumpStudio(
      tester,
      s,
      extraOverrides: [
        exportDownloaderProvider.overrideWithValue((filename, json) async {
          downloaded = '$filename|$json';
        }),
      ],
    );
    await tester.tap(find.text('Privacy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(EditableText).first, 'Ada Lovelace');
    await tester.tap(find.text('Save display name'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Display name saved.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Export my data'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Export my data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.scrollUntilVisible(
      find.text('Download JSON'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Download JSON'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(downloaded, startsWith('penumbra-export.json|'));
    expect(downloaded, contains('Ada Lovelace'));
  });

  testWidgets('export shows JSON and erase returns to landing', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Privacy').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('Export my data'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Export my data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('"displayName"'), findsWidgets);
    expect(find.textContaining('Ada'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Password to erase'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('erase-password')),
      'demo-studio-key',
    );
    await tester.scrollUntilVisible(
      find.text('Erase my account'),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Erase my account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Enter the studio'), findsOneWidget);
    expect(find.text('Your rights'), findsNothing);
  });
}
