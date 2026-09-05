import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/features/boards/domain/board.dart';
import 'package:penumbra/features/boards/domain/node_motion.dart';

void main() {
  const parent = BoardNode(
    id: 'p',
    boardId: 'b',
    x: 10,
    y: 20,
    kind: NodeKind.text,
    text: 'note',
  );
  const echo = BoardNode(
    id: 'e',
    boardId: 'b',
    x: 258,
    y: 48,
    kind: NodeKind.echo,
    text: 'aside',
    parentId: 'p',
  );
  const swatch = BoardNode(
    id: 's',
    boardId: 'b',
    x: 400,
    y: 80,
    kind: NodeKind.swatch,
    colorArgb: 0xFF000000,
  );

  test('moving a human slip takes its echo by the same delta', () {
    final moved = NodeMotion.moved(
      [parent, echo, swatch],
      id: 'p',
      dx: 16,
      dy: -8,
    );
    expect(moved.singleWhere((n) => n.id == 'p').x, 26);
    expect(moved.singleWhere((n) => n.id == 'p').y, 12);
    expect(moved.singleWhere((n) => n.id == 'e').x, 274);
    expect(moved.singleWhere((n) => n.id == 'e').y, 40);
    expect(moved.singleWhere((n) => n.id == 's').x, 400);
  });

  test('moving an echo does not move the parent', () {
    final moved = NodeMotion.moved([parent, echo], id: 'e', dx: 4, dy: 4);
    expect(moved.singleWhere((n) => n.id == 'p').x, 10);
    expect(moved.singleWhere((n) => n.id == 'e').x, 262);
  });

  test('unknown ids are a no-op', () {
    expect(NodeMotion.moved([parent], id: 'missing', dx: 10, dy: 10), [parent]);
  });
}
