import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../boards/domain/board.dart';
import '../../boards/domain/echo_pairing.dart';

class CardIndex extends StatefulWidget {
  const CardIndex({
    required this.conversation,
    required this.focusedId,
    required this.stacked,
    required this.onSelect,
  });

  final List<BoardNode> conversation;
  final String? focusedId;
  final bool stacked;
  final ValueChanged<String> onSelect;

  @override
  State<CardIndex> createState() => _CardIndexState();
}

class _CardIndexState extends State<CardIndex> {
  late List<FocusNode> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _nodesFor(widget.conversation.length);
  }

  @override
  void didUpdateWidget(covariant CardIndex oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameIds(oldWidget.conversation, widget.conversation)) {
      for (final node in _rows) {
        node.dispose();
      }
      _rows = _nodesFor(widget.conversation.length);
    }
  }

  @override
  void dispose() {
    for (final node in _rows) {
      node.dispose();
    }
    super.dispose();
  }

  List<FocusNode> _nodesFor(int count) => [
    for (var i = 0; i < count; i++) FocusNode(debugLabel: 'Index row $i'),
  ];

  bool _sameIds(List<BoardNode> a, List<BoardNode> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _focusRow(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index < 0 || index >= _rows.length) return;
      _rows[index].requestFocus();
    });
  }

  void _rove(int from, int delta) {
    if (widget.conversation.isEmpty) return;
    final next = (from + delta).clamp(0, widget.conversation.length - 1);
    widget.onSelect(widget.conversation[next].id);
    _focusRow(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          left: widget.stacked
              ? BorderSide.none
              : BorderSide(color: theme.colors.border),
          top: widget.stacked
              ? BorderSide(color: theme.colors.border)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.index,
              style: theme.typography.lg.copyWith(
                fontFamily: PenumbraInk.displayFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.indexHint,
              style: theme.typography.xs.copyWith(
                color: theme.colors.mutedForeground,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colors.border)),
              ),
              child: const SizedBox(width: double.infinity, height: 1),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FocusTraversalGroup(
                child: ListView.builder(
                  itemCount: widget.conversation.length,
                  itemBuilder: (context, index) {
                    final node = widget.conversation[index];
                    final selected = node.id == widget.focusedId;
                    final numeral = EchoPairing.numeral(
                      widget.conversation,
                      node,
                    );
                    final echo = node.kind == NodeKind.echo;
                    final humans = widget.conversation
                        .where((n) => n.kind != NodeKind.echo)
                        .length;
                    return Focus(
                      focusNode: _rows[index],
                      onKeyEvent: (focus, event) {
                        if (event is! KeyDownEvent &&
                            event is! KeyRepeatEvent) {
                          return KeyEventResult.ignored;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _rove(index, 1);
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          _rove(index, -1);
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.space) {
                          widget.onSelect(node.id);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Semantics(
                        container: true,
                        button: true,
                        selected: selected,
                        label: echo
                            ? 'Echo of $numeral, ${node.semanticsLabel}'
                            : 'Card $numeral of $humans, ${node.semanticsLabel}',
                        child: GestureDetector(
                          onTap: () {
                            widget.onSelect(node.id);
                            _focusRow(index);
                          },
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: selected
                                      ? theme.colors.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                echo ? 28 : 12,
                                12,
                                8,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    numeral,
                                    style: theme.typography.xs.copyWith(
                                      fontFamily: PenumbraInk.displayFamily,
                                      fontStyle: echo
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      color: selected
                                          ? theme.colors.primary
                                          : theme.colors.mutedForeground,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    echo
                                        ? (node.text ?? l10n.echoLabel)
                                        : node.semanticsLabel,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.typography.sm.copyWith(
                                      fontFamily: PenumbraInk.displayFamily,
                                      fontStyle: echo
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
