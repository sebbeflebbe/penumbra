import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../app/theme.dart';
import '../../boards/domain/board.dart';

class PaperSlip extends StatefulWidget {
  const PaperSlip({
    required this.node,
    required this.numeral,
    required this.selected,
    required this.highContrast,
    required this.readOnly,
    required this.onFocus,
    this.onDismiss,
    this.onSaveText,
    this.onDelete,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
    super.key,
  });

  final BoardNode node;
  final String numeral;
  final bool selected;
  final bool highContrast;
  final bool readOnly;
  final VoidCallback onFocus;
  final VoidCallback? onDismiss;
  final ValueChanged<String>? onSaveText;
  final VoidCallback? onDelete;
  final VoidCallback? onDragStart;
  final ValueChanged<Offset>? onDrag;
  final VoidCallback? onDragEnd;

  @override
  State<PaperSlip> createState() => _PaperSlipState();
}

class _PaperSlipState extends State<PaperSlip> {
  var _editing = false;
  late final TextEditingController _edit = TextEditingController(
    text: widget.node.text ?? '',
  );

  @override
  void didUpdateWidget(covariant PaperSlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.node.text != widget.node.text) {
      _edit.text = widget.node.text ?? '';
    }
    if (!widget.selected) _editing = false;
  }

  @override
  void dispose() {
    _edit.dispose();
    super.dispose();
  }

  bool get _human => widget.node.kind != NodeKind.echo;
  bool get _echo => widget.node.kind == NodeKind.echo;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final echo = _echo;
    final selected = widget.selected;
    final highContrast = widget.highContrast;
    final slip = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: echo ? 168 : 176,
        maxWidth: echo ? 240 : 280,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected
                ? theme.colors.primary
                : echo
                ? theme.colors.primary.withValues(
                    alpha: highContrast ? 1 : 0.45,
                  )
                : theme.colors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: highContrast || echo
              ? const []
              : [
                  BoxShadow(
                    color: theme.colors.foreground.withValues(
                      alpha: selected ? 0.16 : 0.08,
                    ),
                    blurRadius: selected ? 22 : 14,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: theme.colors.foreground.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.numeral,
                    style: theme.typography.xs.copyWith(
                      fontFamily: PenumbraInk.displayFamily,
                      fontStyle: echo ? FontStyle.italic : FontStyle.normal,
                      color: selected
                          ? theme.colors.primary
                          : theme.colors.mutedForeground,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (echo && selected && widget.onDismiss != null)
                    _namedAction(
                      theme,
                      label: 'Dismiss',
                      spoken: 'Dismiss this echo',
                      onTap: widget.onDismiss!,
                    )
                  else if (selected && !_editing)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (widget.node.kind == NodeKind.swatch)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColoredBox(
                      color: Color(widget.node.colorArgb ?? 0xFF000000),
                      child: const SizedBox(width: 132, height: 88),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Specimen',
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                )
              else if (_editing)
                FTextField(
                  hint: 'A thought, privately held',
                  control: FTextFieldControl.managed(controller: _edit),
                )
              else
                Text(
                  widget.node.text ?? (echo ? 'Echo' : 'Untitled note'),
                  style: theme.typography.md.copyWith(
                    fontFamily: PenumbraInk.displayFamily,
                    fontStyle: echo ? FontStyle.italic : FontStyle.normal,
                    height: 1.35,
                    fontWeight: echo ? FontWeight.w400 : FontWeight.w500,
                    color: echo
                        ? theme.colors.mutedForeground
                        : theme.colors.foreground,
                  ),
                ),
              if (selected && _human && !widget.readOnly) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (widget.node.kind == NodeKind.text &&
                        widget.onSaveText != null)
                      _editing
                          ? _namedAction(
                              theme,
                              label: 'Save',
                              spoken: 'Save this note',
                              onTap: () {
                                final text = _edit.text.trim();
                                if (text.isEmpty) return;
                                widget.onSaveText!(text);
                                setState(() => _editing = false);
                              },
                            )
                          : _namedAction(
                              theme,
                              label: 'Edit',
                              spoken: 'Edit this note',
                              onTap: () => setState(() {
                                _edit.text = widget.node.text ?? '';
                                _editing = true;
                              }),
                            ),
                    if (_editing)
                      _namedAction(
                        theme,
                        label: 'Cancel',
                        spoken: 'Cancel editing',
                        onTap: () => setState(() => _editing = false),
                      ),
                    if (!_editing && widget.onDelete != null)
                      _namedAction(
                        theme,
                        label: 'Delete',
                        spoken: 'Delete this note',
                        onTap: widget.onDelete!,
                      ),
                    if (!_editing && widget.onDrag != null) _moveHandle(theme),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: echo
          ? '${widget.node.semanticsLabel}, ${widget.numeral}'
          : 'Card ${widget.numeral}, ${widget.node.semanticsLabel}',
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) widget.onFocus();
        },
        child: GestureDetector(
          onTap: widget.onFocus,
          child: selected && !highContrast && !echo
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colors.primary.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(padding: const EdgeInsets.all(5), child: slip),
                )
              : slip,
        ),
      ),
    );
  }

  Widget _moveHandle(FThemeData theme) {
    return Semantics(
      button: true,
      label: 'Move this note',
      child: GestureDetector(
        onPanStart: (_) => widget.onDragStart?.call(),
        onPanUpdate: (details) => widget.onDrag?.call(details.delta),
        onPanEnd: (_) => widget.onDragEnd?.call(),
        onPanCancel: () => widget.onDragEnd?.call(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Move',
              style: theme.typography.xs.copyWith(
                color: theme.colors.primary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _namedAction(
    FThemeData theme, {
    required String label,
    required String spoken,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: spoken,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: theme.typography.xs.copyWith(
                color: theme.colors.primary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
