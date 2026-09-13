import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/features/boards/domain/board.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/pump_studio.dart';

void main() {
  testWidgets('locked studio unlocks notes with the recovery phrase', (
    tester,
  ) async {
    final s = memoryStudio();
    await s.signInWithGitHub();
    final phrase = s.pendingRecoveryPhrase!;
    s.acknowledgeRecoveryPhrase();
    final board = (await s.create(title: 'Quiet thoughts')).okOrNull!;
    await s.upsert(
      BoardNode(
        id: const Uuid().v4(),
        boardId: board.id,
        x: 72,
        y: 80,
        kind: NodeKind.text,
        text: 'Private by default.',
      ),
    );
    s.debugLockSession();
    expect(s.current?.needsPhraseUnlock, isTrue);

    await pumpStudio(tester, s);
    await tester.tap(find.text('Boards').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.text('Private by default.'), findsNothing);

    await tester.enterText(find.byType(EditableText).first, phrase);
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(s.current?.needsPhraseUnlock, isFalse);
    expect(find.text('Private by default.'), findsWidgets);
  });
}
