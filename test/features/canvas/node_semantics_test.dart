import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/features/boards/domain/board.dart';

void main() {
  test('text cards expose a screen-reader label', () {
    const node = BoardNode(
      id: '1',
      boardId: 'b',
      x: 0,
      y: 0,
      kind: NodeKind.text,
      text: 'Private by default',
    );
    expect(node.semanticsLabel, 'Private by default');
  });

  test('empty text cards fall back to Untitled note', () {
    const node = BoardNode(
      id: '1',
      boardId: 'b',
      x: 0,
      y: 0,
      kind: NodeKind.text,
      text: '  ',
    );
    expect(node.semanticsLabel, 'Untitled note');
  });

  test('swatches announce as colour swatch', () {
    const node = BoardNode(
      id: '1',
      boardId: 'b',
      x: 0,
      y: 0,
      kind: NodeKind.swatch,
      colorArgb: 0xFF000000,
    );
    expect(node.semanticsLabel, 'Colour swatch');
  });

  test('echo cards announce as a companion', () {
    const node = BoardNode(
      id: 'e1',
      boardId: 'b',
      x: 28,
      y: 36,
      kind: NodeKind.echo,
      text: 'The same weather, only quieter.',
      parentId: '1',
    );
    expect(node.semanticsLabel, 'Echo of The same weather, only quieter.');
  });

  test('payload round-trips parentId and echo kind', () {
    const node = BoardNode(
      id: 'e1',
      boardId: 'b',
      x: 28,
      y: 36,
      kind: NodeKind.echo,
      text: 'Half-light',
      parentId: 'p1',
    );
    final restored = BoardNode.fromPayload(
      id: node.id,
      boardId: node.boardId,
      payload: node.toPayload(),
    );
    expect(restored.kind, NodeKind.echo);
    expect(restored.parentId, 'p1');
    expect(restored.text, 'Half-light');
  });
}
