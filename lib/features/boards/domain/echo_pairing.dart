import '../../../core/errors.dart';
import '../../../core/result.dart';
import 'board.dart';

/// One echo per human slip. Swatches do not speak.
abstract final class EchoPairing {
  /// Sit beside the parent, not on it. A short slip is ~220×100.
  static const offsetX = 248.0;
  static const offsetY = 28.0;
  static const slipWidth = 220.0;
  static const slipHeight = 100.0;

  static bool overlapsParent(BoardNode echo, BoardNode parent) {
    final dx = (echo.x - parent.x).abs();
    final dy = (echo.y - parent.y).abs();
    return dx < slipWidth * 0.75 && dy < slipHeight;
  }

  static BoardNode placeBeside(BoardNode echo, BoardNode parent) {
    return echo.copyWith(x: parent.x + offsetX, y: parent.y + offsetY);
  }

  static Result<void, AppFailure> validateWrite(
    BoardNode node,
    List<BoardNode> siblings,
  ) {
    if (node.kind != NodeKind.echo) {
      if (node.parentId != null) {
        return const Err(ValidationFailure('Only an echo names a parent.'));
      }
      return const Ok(null);
    }
    final parentId = node.parentId;
    if (parentId == null || parentId.isEmpty) {
      return const Err(ValidationFailure('An echo must name its parent.'));
    }
    BoardNode? parent;
    for (final sibling in siblings) {
      if (sibling.id == parentId) {
        parent = sibling;
        break;
      }
    }
    if (parent == null) {
      return const Err(NotFoundFailure('The parent slip is gone.'));
    }
    if (parent.kind != NodeKind.text) {
      return const Err(ValidationFailure('Echoes answer human slips only.'));
    }
    for (final sibling in siblings) {
      if (sibling.id != node.id &&
          sibling.kind == NodeKind.echo &&
          sibling.parentId == parentId) {
        return const Err(
          ValidationFailure(
            'This slip already has an echo. Dismiss it to summon again.',
          ),
        );
      }
    }
    return const Ok(null);
  }

  static BoardNode? echoFor(List<BoardNode> nodes, String parentId) {
    for (final node in nodes) {
      if (node.kind == NodeKind.echo && node.parentId == parentId) return node;
    }
    return null;
  }

  static bool canSummon(BoardNode node, List<BoardNode> nodes) {
    return node.kind == NodeKind.text && echoFor(nodes, node.id) == null;
  }

  /// Human slips and swatches in board order, each echo nested after its parent.
  static List<BoardNode> conversation(List<BoardNode> nodes) {
    final byParent = <String, BoardNode>{};
    for (final node in nodes) {
      final parentId = node.parentId;
      if (node.kind == NodeKind.echo && parentId != null) {
        byParent.putIfAbsent(parentId, () => node);
      }
    }
    final out = <BoardNode>[];
    final seen = <String>{};
    for (final node in nodes) {
      if (node.kind == NodeKind.echo) continue;
      out.add(node);
      seen.add(node.id);
      final echo = byParent[node.id];
      if (echo != null) {
        out.add(echo);
        seen.add(echo.id);
      }
    }
    for (final node in nodes) {
      if (!seen.contains(node.id)) out.add(node);
    }
    return out;
  }

  static String numeral(List<BoardNode> conversation, BoardNode node) {
    final humans = [
      for (final item in conversation)
        if (item.kind != NodeKind.echo) item,
    ];
    if (node.kind == NodeKind.echo) {
      final parentIndex = humans.indexWhere((item) => item.id == node.parentId);
      final n = parentIndex < 0 ? humans.length + 1 : parentIndex + 1;
      return '${n.toString().padLeft(2, '0')}′';
    }
    final i = humans.indexWhere((item) => item.id == node.id);
    return (i < 0 ? 1 : i + 1).toString().padLeft(2, '0');
  }
}
