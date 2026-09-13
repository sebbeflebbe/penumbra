import 'package:flutter/widgets.dart';
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
  testWidgets('a selected human slip can be deleted after confirm', (
    tester,
  ) async {
    await pumpStudio(tester, memoryStudio());
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
    await pumpStudio(tester, memoryStudio());
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
