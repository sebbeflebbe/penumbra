import 'board.dart';
import 'echo_pairing.dart';

/// Pointer and keyboard moves share this rule: a human slip takes its echo with it.
abstract final class NodeMotion {
  static List<BoardNode> moved(
    List<BoardNode> nodes, {
    required String id,
    required double dx,
    required double dy,
  }) {
    BoardNode? target;
    for (final node in nodes) {
      if (node.id == id) {
        target = node;
        break;
      }
    }
    if (target == null || (dx == 0 && dy == 0)) return nodes;

    var next = [
      for (final node in nodes) node.id == id ? node.movedBy(dx, dy) : node,
    ];
    if (target.kind == NodeKind.text) {
      final echo = EchoPairing.echoFor(nodes, id);
      if (echo != null) {
        next = [
          for (final node in next)
            node.id == echo.id ? node.movedBy(dx, dy) : node,
        ];
      }
    }
    return next;
  }
}
