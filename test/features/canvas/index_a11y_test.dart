import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_studio.dart';

Future<void> openSeededCanvas(WidgetTester tester) async {
  await tester.tap(find.text('Enter the studio'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('Index marks the focused card as selected', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await openSeededCanvas(tester);

    final first = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'Card 01 of 3, Private by default')),
    );
    expect(first.flagsCollection.isSelected.toString(), 'Tristate.isTrue');
  });

  testWidgets('tapping an Index row selects that slip', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await openSeededCanvas(tester);

    await tester.tap(
      find.bySemanticsLabel(RegExp(r'Card 02 of 3, Accessible by design')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final second = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'Card 02 of 3, Accessible by design')),
    );
    expect(second.flagsCollection.isSelected.toString(), 'Tristate.isTrue');
    expect(find.text('Edit'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Move this note')), findsOneWidget);
  });

  testWidgets('Index Up and Down change the selected slip', (tester) async {
    await pumpStudio(tester, memoryStudio());
    await openSeededCanvas(tester);

    await tester.tap(
      find.bySemanticsLabel(RegExp(r'Card 01 of 3, Private by default')),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final second = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'Card 02 of 3, Accessible by design')),
    );
    expect(second.flagsCollection.isSelected.toString(), 'Tristate.isTrue');
  });
}
