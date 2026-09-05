import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/core/errors.dart';
import 'package:penumbra/features/boards/domain/board.dart';
import 'package:penumbra/features/boards/domain/echo_pairing.dart';

BoardNode human({required String id, String text = 'A thought'}) => BoardNode(
      id: id,
      boardId: 'b',
      x: 0,
      y: 0,
      kind: NodeKind.text,
      text: text,
    );

BoardNode echo({required String id, required String parentId}) => BoardNode(
      id: id,
      boardId: 'b',
      x: 28,
      y: 36,
      kind: NodeKind.echo,
      text: 'Quieter.',
      parentId: parentId,
    );

void main() {
  test('a second echo on the same parent is refused', () {
    final parent = human(id: 'h1');
    final first = echo(id: 'e1', parentId: 'h1');
    final second = echo(id: 'e2', parentId: 'h1');
    expect(EchoPairing.validateWrite(first, [parent]).isOk, isTrue);
    final refused = EchoPairing.validateWrite(second, [parent, first]);
    expect(refused.errOrNull, isA<ValidationFailure>());
    expect(refused.errOrNull?.message, contains('already has an echo'));
  });

  test('dismissing the echo allows a later summon', () {
    final parent = human(id: 'h1');
    final first = echo(id: 'e1', parentId: 'h1');
    expect(EchoPairing.canSummon(parent, [parent, first]), isFalse);
    expect(EchoPairing.canSummon(parent, [parent]), isTrue);
    expect(EchoPairing.validateWrite(echo(id: 'e2', parentId: 'h1'), [parent]).isOk, isTrue);
  });

  test('swatches cannot be echoed', () {
    const swatch = BoardNode(
      id: 's1',
      boardId: 'b',
      x: 0,
      y: 0,
      kind: NodeKind.swatch,
      colorArgb: 0xFF000000,
    );
    expect(EchoPairing.canSummon(swatch, [swatch]), isFalse);
    final result = EchoPairing.validateWrite(echo(id: 'e1', parentId: 's1'), [swatch]);
    expect(result.isErr, isTrue);
  });

  test('conversation nests the echo after its parent', () {
    final a = human(id: 'a', text: 'First');
    final b = human(id: 'b', text: 'Second');
    final echoA = echo(id: 'ea', parentId: 'a');
    final ordered = EchoPairing.conversation([a, b, echoA]);
    expect(ordered.map((n) => n.id), ['a', 'ea', 'b']);
    expect(EchoPairing.numeral(ordered, a), '01');
    expect(EchoPairing.numeral(ordered, echoA), '01′');
    expect(EchoPairing.numeral(ordered, b), '02');
  });

  test('an echo that sits on its parent is overlapping', () {
    final parent = human(id: 'h1');
    final stacked = echo(id: 'e1', parentId: 'h1');
    expect(EchoPairing.overlapsParent(stacked, parent), isTrue);
    final beside = EchoPairing.placeBeside(stacked, parent);
    expect(EchoPairing.overlapsParent(beside, parent), isFalse);
    expect(beside.x, parent.x + EchoPairing.offsetX);
  });
}
