import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_studio.dart';

void main() {
  testWidgets('recovery phrase can be acknowledged from the canvas', (
    tester,
  ) async {
    final s = memoryStudio();
    await s.signInWithGitHub();
    await s.create(title: 'Quiet thoughts');
    await pumpStudio(tester, s);
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
