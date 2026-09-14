import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../boards/domain/board.dart';
import '../../boards/domain/echo_pairing.dart';
import 'paper_slip.dart';

List<BoardNode> _paintOrder(
  List<BoardNode> nodes,
  List<BoardNode> conversation,
  String? focusedId,
) {
  final humans = [
    for (final node in conversation)
      if (node.kind != NodeKind.echo) node,
  ];
  final echoes = [
    for (final node in conversation)
      if (node.kind == NodeKind.echo) node,
  ];
  final ordered = [...humans, ...echoes];
  if (focusedId == null) return ordered;
  return [
    for (final node in ordered)
      if (node.id != focusedId) node,
    for (final node in nodes)
      if (node.id == focusedId) node,
  ];
}

class Atelier extends StatelessWidget {
  const Atelier({
    required this.board,
    required this.nodes,
    required this.conversation,
    required this.focusedId,
    required this.highContrast,
    required this.phrase,
    required this.summonError,
    required this.panEnabled,
    required this.appear,
    required this.onFocus,
    required this.onDismissEcho,
    required this.onAcknowledgePhrase,
    required this.onSaveText,
    required this.onDelete,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    required this.toolbar,
  });

  final Board board;
  final List<BoardNode> nodes;
  final List<BoardNode> conversation;
  final String? focusedId;
  final bool highContrast;
  final String? phrase;
  final String? summonError;
  final bool panEnabled;
  final Widget Function(String id, Widget child) appear;
  final ValueChanged<String> onFocus;
  final ValueChanged<String>? onDismissEcho;
  final VoidCallback onAcknowledgePhrase;
  final void Function(BoardNode node, String text)? onSaveText;
  final ValueChanged<BoardNode>? onDelete;
  final ValueChanged<String>? onDragStart;
  final void Function(String id, Offset delta)? onDrag;
  final ValueChanged<String>? onDragEnd;
  final Widget toolbar;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final well = Color.lerp(
      theme.colors.background,
      theme.colors.foreground,
      0.04,
    )!;
    return ColoredBox(
      color: well,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (phrase != null) ...[
              FAlert(
                title: Text(AppLocalizations.of(context).savePhraseTitle),
                subtitle: Text(
                  '$phrase\n${AppLocalizations.of(context).savePhraseBody}',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FButton(
                  onPress: onAcknowledgePhrase,
                  child: Text(AppLocalizations.of(context).savedPhrase),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (board.restricted) ...[
              FAlert(
                title: Text(AppLocalizations.of(context).boardRestrictedArt18),
                subtitle: Text(
                  AppLocalizations.of(context).boardRestrictedSubtitle,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (summonError != null) ...[
              FAlert(
                variant: FAlertVariant.destructive,
                title: Text(summonError!),
              ),
              const SizedBox(height: 12),
            ],
            _RunningHead(title: board.title, count: nodes.length),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colors.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: theme.colors.border),
                  boxShadow: highContrast
                      ? const []
                      : [
                          BoxShadow(
                            color: theme.colors.foreground.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                          BoxShadow(
                            color: theme.colors.foreground.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: InteractiveViewer(
                    panEnabled: panEnabled,
                    constrained: false,
                    minScale: 0.5,
                    maxScale: 2.5,
                    child: SizedBox(
                      width: 1600,
                      height: 1200,
                      child: CustomPaint(
                        painter: _SheetPainter(
                          ink: theme.colors.foreground,
                          rule: theme.colors.border,
                          copper: theme.colors.primary,
                          paper: theme.colors.card,
                          highContrast: highContrast,
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _EchoHairlinePainter(
                                    nodes: nodes,
                                    copper: theme.colors.primary,
                                  ),
                                ),
                              ),
                            ),
                            for (final node in _paintOrder(
                              nodes,
                              conversation,
                              focusedId,
                            ))
                              Positioned(
                                left: node.x,
                                top: node.y,
                                child: appear(
                                  node.id,
                                  PaperSlip(
                                    node: node,
                                    numeral: EchoPairing.numeral(
                                      conversation,
                                      node,
                                    ),
                                    selected: node.id == focusedId,
                                    highContrast: highContrast,
                                    readOnly: board.restricted,
                                    onFocus: () => onFocus(node.id),
                                    onDismiss:
                                        node.kind == NodeKind.echo &&
                                            onDismissEcho != null
                                        ? () => onDismissEcho!(node.id)
                                        : null,
                                    onSaveText: onSaveText == null
                                        ? null
                                        : (text) => onSaveText!(node, text),
                                    onDelete: onDelete == null
                                        ? null
                                        : () => onDelete!(node),
                                    onDragStart: onDragStart == null
                                        ? null
                                        : () => onDragStart!(node.id),
                                    onDrag: onDrag == null
                                        ? null
                                        : (delta) => onDrag!(node.id, delta),
                                    onDragEnd: onDragEnd == null
                                        ? null
                                        : () => onDragEnd!(node.id),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            toolbar,
          ],
        ),
      ),
    );
  }
}

class _RunningHead extends StatelessWidget {
  const _RunningHead({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.typography.xl2.copyWith(
                  fontFamily: PenumbraInk.displayFamily,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
            Text(
              count == 1
                  ? AppLocalizations.of(context).cardCountOne
                  : AppLocalizations.of(context).cardCountMany(count),
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.colors.border)),
          ),
          child: const SizedBox(width: double.infinity, height: 1),
        ),
      ],
    );
  }
}

class _EchoHairlinePainter extends CustomPainter {
  const _EchoHairlinePainter({required this.nodes, required this.copper});

  final List<BoardNode> nodes;
  final Color copper;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = copper.withValues(alpha: 0.7)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (final echo in nodes) {
      if (echo.kind != NodeKind.echo || echo.parentId == null) continue;
      BoardNode? parent;
      for (final node in nodes) {
        if (node.id == echo.parentId) {
          parent = node;
          break;
        }
      }
      if (parent == null) continue;
      canvas.drawLine(
        Offset(
          parent.x + EchoPairing.slipWidth,
          parent.y + EchoPairing.slipHeight * 0.45,
        ),
        Offset(echo.x, echo.y + 36),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EchoHairlinePainter oldDelegate) =>
      oldDelegate.nodes != nodes || oldDelegate.copper != copper;
}

class _SheetPainter extends CustomPainter {
  const _SheetPainter({
    required this.ink,
    required this.rule,
    required this.copper,
    required this.paper,
    required this.highContrast,
  });

  final Color ink;
  final Color rule;
  final Color copper;
  final Color paper;
  final bool highContrast;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);

    const inset = 36.0;
    final plate = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rulePaint = Paint()
      ..color = rule
      ..strokeWidth = 1;

    canvas.drawRect(
      plate,
      Paint()
        ..color = rule
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    _crop(canvas, plate.topLeft, 1, 1, rulePaint);
    _crop(canvas, plate.topRight, -1, 1, rulePaint);
    _crop(canvas, plate.bottomLeft, 1, -1, rulePaint);
    _crop(canvas, plate.bottomRight, -1, -1, rulePaint);

    if (!highContrast) {
      final eclipse = Offset(size.width * 0.72, size.height * 0.34);
      canvas.drawCircle(
        eclipse,
        210,
        Paint()
          ..color = copper.withValues(alpha: 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(
        eclipse + const Offset(54, 10),
        210,
        Paint()..color = ink.withValues(alpha: 0.045),
      );

      final line = Paint()
        ..color = rule.withValues(alpha: 0.7)
        ..strokeWidth = 0.6;
      const step = 28.0;
      for (var y = plate.top + 48; y < plate.bottom - 8; y += step) {
        canvas.drawLine(
          Offset(plate.left + 16, y),
          Offset(plate.right - 16, y),
          line,
        );
      }
      final dots = Paint()..color = rule;
      for (var x = plate.left + 16; x < plate.right - 8; x += step) {
        for (var y = plate.top + 48; y < plate.bottom - 8; y += step) {
          canvas.drawCircle(Offset(x, y), 0.7, dots);
        }
      }

      final vignette = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawRect(
        vignette,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.15, -0.2),
            radius: 1.05,
            colors: [paper.withValues(alpha: 0), ink.withValues(alpha: 0.12)],
          ).createShader(vignette),
      );
    }
  }

  void _crop(Canvas canvas, Offset corner, double dx, double dy, Paint paint) {
    const arm = 14.0;
    canvas.drawLine(corner, corner + Offset(dx * arm, 0), paint);
    canvas.drawLine(corner, corner + Offset(0, dy * arm), paint);
  }

  @override
  bool shouldRepaint(covariant _SheetPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.rule != rule ||
      oldDelegate.copper != copper ||
      oldDelegate.paper != paper ||
      oldDelegate.highContrast != highContrast;
}
