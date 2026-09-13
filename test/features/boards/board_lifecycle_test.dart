import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_studio.dart';

void main() {
  testWidgets('restricting a board makes the canvas read-only', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Restrict'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.textContaining('Art. 18'), findsWidgets);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('renaming a board updates the list title', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Rename'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(EditableText).last, 'Half-light notes');
    await tester.tap(find.text('Save title'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Half-light notes'), findsWidgets);
  });

  testWidgets('deleting a board removes it after confirm', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.bySemanticsLabel(RegExp('Delete Quiet thoughts')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Delete this board').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Open'), findsNothing);
    expect(find.textContaining('Nothing here yet'), findsOneWidget);
  });

  testWidgets('a selected slip exposes a named Move handle', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await tester.tap(find.text('Enter the studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.text('Private by default.').first);
    await tester.pump();
    expect(find.text('Move'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Move this note')), findsOneWidget);
  });
}
