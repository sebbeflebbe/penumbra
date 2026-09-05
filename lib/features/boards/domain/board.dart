import 'package:clock/clock.dart';

class Board {
  const Board({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.updatedAt,
    this.restricted = false,
  });

  final String id;
  final String ownerId;
  final String title;
  final DateTime updatedAt;
  final bool restricted;

  Board copyWith({String? title, DateTime? updatedAt, bool? restricted}) {
    return Board(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      restricted: restricted ?? this.restricted,
    );
  }

  factory Board.create({
    required String id,
    required String ownerId,
    required String title,
  }) {
    return Board(
      id: id,
      ownerId: ownerId,
      title: title,
      updatedAt: clock.now().toUtc(),
    );
  }
}

enum NodeKind { text, swatch, echo }

class BoardNode {
  const BoardNode({
    required this.id,
    required this.boardId,
    required this.x,
    required this.y,
    required this.kind,
    this.text,
    this.colorArgb,
    this.parentId,
  });

  final String id;
  final String boardId;
  final double x;
  final double y;
  final NodeKind kind;
  final String? text;
  final int? colorArgb;
  final String? parentId;

  String get semanticsLabel {
    final body = switch (kind) {
      NodeKind.text =>
        text?.trim().isNotEmpty == true ? text!.trim() : 'Untitled note',
      NodeKind.swatch => 'Colour swatch',
      NodeKind.echo =>
        text?.trim().isNotEmpty == true
            ? 'Echo of ${text!.trim()}'
            : 'Echo of an unnamed thought',
    };
    return body;
  }

  BoardNode movedBy(double dx, double dy) => copyWith(x: x + dx, y: y + dy);

  BoardNode copyWith({
    double? x,
    double? y,
    String? text,
    int? colorArgb,
    String? parentId,
  }) {
    return BoardNode(
      id: id,
      boardId: boardId,
      x: x ?? this.x,
      y: y ?? this.y,
      kind: kind,
      text: text ?? this.text,
      colorArgb: colorArgb ?? this.colorArgb,
      parentId: parentId ?? this.parentId,
    );
  }

  Map<String, Object?> toPayload() => {
    'kind': kind.name,
    'text': text,
    'colorArgb': colorArgb,
    'x': x,
    'y': y,
    'parentId': parentId,
  };

  factory BoardNode.fromPayload({
    required String id,
    required String boardId,
    required Map<String, Object?> payload,
  }) {
    final kindName = payload['kind'] as String? ?? 'text';
    final parent = payload['parentId'] as String?;
    return BoardNode(
      id: id,
      boardId: boardId,
      x: (payload['x'] as num?)?.toDouble() ?? 0,
      y: (payload['y'] as num?)?.toDouble() ?? 0,
      kind: switch (kindName) {
        'swatch' => NodeKind.swatch,
        'echo' => NodeKind.echo,
        _ => NodeKind.text,
      },
      text: payload['text'] as String?,
      colorArgb: payload['colorArgb'] as int?,
      parentId: (parent == null || parent.isEmpty) ? null : parent,
    );
  }
}
