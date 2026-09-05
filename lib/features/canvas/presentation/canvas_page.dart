import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';
import '../../boards/domain/board.dart';
import '../../boards/domain/echo_pairing.dart';

class CanvasPage extends ConsumerStatefulWidget {
  const CanvasPage({required this.boardId, super.key});

  final String boardId;

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  Board? _board;
  List<BoardNode> _nodes = [];
  String? _error;
  String? _summonError;
  int _focusedIndex = 0;
  bool _summoning = false;
  bool _echoConsentedThisSession = false;
  final _note = TextEditingController();
  final _seen = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  BoardNode? get _selected {
    if (_nodes.isEmpty) return null;
    return _nodes[_focusedIndex.clamp(0, _nodes.length - 1)];
  }

  bool get _canSummon {
    final node = _selected;
    if (node == null) return false;
    return EchoPairing.canSummon(node, _nodes);
  }

  Future<void> _load() async {
    final boards = ref.read(boardRepositoryProvider);
    final canvas = ref.read(canvasRepositoryProvider);
    final board = await boards.getById(widget.boardId);
    final nodes = await canvas.listNodes(widget.boardId);
    if (!mounted) return;
    setState(() {
      _board = board.okOrNull;
      _error = board.errOrNull?.message ?? nodes.errOrNull?.message;
      _nodes = nodes.okOrNull ?? [];
      _seen.addAll(_nodes.map((n) => n.id));
    });
    await _untangleEchoes();
  }

  Future<void> _untangleEchoes() async {
    final canvas = ref.read(canvasRepositoryProvider);
    var next = [..._nodes];
    var changed = false;

    Future<void> persist(BoardNode updated) async {
      final saved = await canvas.upsert(updated);
      if (!mounted) return;
      saved.when(
        ok: (value) {
          next = [for (final node in next) node.id == value.id ? value : node];
          changed = true;
        },
        err: (_) {},
      );
    }

    for (final node in [...next]) {
      if (node.kind != NodeKind.echo || node.parentId == null) continue;
      BoardNode? parent;
      for (final candidate in next) {
        if (candidate.id == node.parentId) {
          parent = candidate;
          break;
        }
      }
      if (parent == null || !EchoPairing.overlapsParent(node, parent)) continue;
      await persist(EchoPairing.placeBeside(node, parent));
    }

    for (final swatch in [...next]) {
      if (swatch.kind != NodeKind.swatch) continue;
      for (final echo in next) {
        if (echo.kind != NodeKind.echo) continue;
        if ((swatch.x - echo.x).abs() < 200 && (swatch.y - echo.y).abs() < 110) {
          await persist(swatch.copyWith(x: echo.x + EchoPairing.slipWidth + 36, y: swatch.y));
          break;
        }
      }
    }

    if (changed && mounted) setState(() => _nodes = next);
  }

  Future<void> _addNote() async {
    final text = _note.text.trim();
    if (text.isEmpty) return;
    final humans = _nodes.where((n) => n.kind == NodeKind.text).length;
    final col = humans % 2;
    final row = humans ~/ 2;
    final node = BoardNode(
      id: const Uuid().v4(),
      boardId: widget.boardId,
      x: 72 + col * 420,
      y: 80 + row * 220,
      kind: NodeKind.text,
      text: text,
    );
    final result = await ref.read(canvasRepositoryProvider).upsert(node);
    if (!mounted) return;
    result.when(
      ok: (created) {
        setState(() {
          _nodes = [..._nodes, created];
          _focusedIndex = _nodes.length - 1;
          _note.clear();
        });
        announce(context, 'Added card ${_nodes.length} of ${_nodes.length}');
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  Future<void> _addSwatch() async {
    const colors = [0xFF1F4E5A, 0xFFC45C26, 0xFF2C2C2C, 0xFFE8DCC8];
    final node = BoardNode(
      id: const Uuid().v4(),
      boardId: widget.boardId,
      x: 240,
      y: 280,
      kind: NodeKind.swatch,
      colorArgb: colors[_nodes.length % colors.length],
    );
    final result = await ref.read(canvasRepositoryProvider).upsert(node);
    if (!mounted) return;
    result.when(
      ok: (created) => setState(() => _nodes = [..._nodes, created]),
      err: (failure) => announce(context, failure.message),
    );
  }

  Future<void> _nudge(int dx, int dy) async {
    if (_nodes.isEmpty) return;
    final node = _nodes[_focusedIndex.clamp(0, _nodes.length - 1)];
    final moved = node.copyWith(x: node.x + dx, y: node.y + dy);
    final canvas = ref.read(canvasRepositoryProvider);
    final result = await canvas.upsert(moved);
    var next = [for (final n in _nodes) n.id == moved.id ? moved : n];
    result.when(
      ok: (updated) => next = [for (final n in next) n.id == updated.id ? updated : n],
      err: (_) {},
    );
    if (node.kind == NodeKind.text) {
      final echo = EchoPairing.echoFor(_nodes, node.id);
      if (echo != null) {
        final shifted = echo.copyWith(x: echo.x + dx, y: echo.y + dy);
        final echoResult = await canvas.upsert(shifted);
        echoResult.when(
          ok: (updated) => next = [for (final n in next) n.id == updated.id ? updated : n],
          err: (_) {},
        );
      }
    }
    if (mounted) setState(() => _nodes = next);
  }

  Future<bool> _confirmRemoteEcho() async {
    final agreed = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        title: const Text('Summon an echo'),
        body: const Text(
          'This thought will go to Google once. The rest of the board stays here. '
          'Google LLC processes that one slip under your consent (Art. 6(1)(a)).',
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('Send this thought'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Keep it here'),
          ),
        ],
      ),
    );
    return agreed == true;
  }

  Future<void> _summonEcho() async {
    final parent = _selected;
    if (parent == null || !EchoPairing.canSummon(parent, _nodes) || _summoning) return;
    final composer = ref.read(echoComposerProvider);
    if (composer.remote && !_echoConsentedThisSession) {
      final agreed = await _confirmRemoteEcho();
      if (!mounted || !agreed) return;
      _echoConsentedThisSession = true;
    }
    setState(() {
      _summoning = true;
      _summonError = null;
    });
    final result = await composer.echo(source: parent.text ?? '');
    if (!mounted) return;
    await result.when(
      ok: (text) async {
        final echo = BoardNode(
          id: const Uuid().v4(),
          boardId: widget.boardId,
          x: parent.x + EchoPairing.offsetX,
          y: parent.y + EchoPairing.offsetY,
          kind: NodeKind.echo,
          text: text,
          parentId: parent.id,
        );
        final saved = await ref.read(canvasRepositoryProvider).upsert(echo);
        if (!mounted) return;
        saved.when(
          ok: (created) {
            setState(() {
              _nodes = [..._nodes, created];
              _summoning = false;
            });
            announce(context, 'An echo was placed nearby.');
          },
          err: (failure) {
            setState(() {
              _summoning = false;
              _summonError = failure.message;
            });
            announce(context, failure.message);
          },
        );
      },
      err: (failure) {
        setState(() {
          _summoning = false;
          _summonError = failure.message;
        });
        announce(context, failure.message);
      },
    );
  }

  Future<void> _dismissEcho(String id) async {
    final result = await ref.read(canvasRepositoryProvider).delete(id);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(() {
          _nodes = [for (final n in _nodes) if (n.id != id) n];
          if (_nodes.isEmpty) {
            _focusedIndex = 0;
          } else {
            _focusedIndex = _focusedIndex.clamp(0, _nodes.length - 1);
          }
        });
        announce(context, 'Echo dismissed.');
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  bool get _highContrast {
    final bg = context.theme.colors.background;
    return bg == const Color(0xFF000000) || bg == const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);
    final phrase = ref.watch(authRepositoryProvider).pendingRecoveryPhrase;
    if (_error != null) {
      return PenumbraChrome(
        child: PenumbraPage(child: FAlert(variant: FAlertVariant.destructive, title: Text(_error!))),
      );
    }
    if (_board == null) {
      return const PenumbraChrome(child: Center(child: FCircularProgress()));
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _nudge(-16, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _nudge(16, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _nudge(0, -16),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _nudge(0, 16),
      },
      child: Focus(
        autofocus: true,
        child: PenumbraChrome(
          title: _board!.title,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 780;
              final conversation = EchoPairing.conversation(_nodes);
              final studioSheet = _Atelier(
                board: _board!,
                nodes: _nodes,
                conversation: conversation,
                focusedId: _selected?.id,
                highContrast: _highContrast,
                phrase: phrase,
                summonError: _summonError,
                appear: _appear,
                onFocus: (id) => setState(() {
                  final i = _nodes.indexWhere((n) => n.id == id);
                  if (i >= 0) _focusedIndex = i;
                }),
                onDismissEcho: _dismissEcho,
                toolbar: _ComposeBar(
                  controller: _note,
                  onPlace: _addNote,
                  onSwatch: _addSwatch,
                  onSummon: _canSummon ? _summonEcho : null,
                  summoning: _summoning,
                ),
              );
              final index = _CardIndex(
                conversation: conversation,
                focusedId: _selected?.id,
                stacked: stacked,
                onSelect: (id) => setState(() {
                  final i = _nodes.indexWhere((n) => n.id == id);
                  if (i >= 0) _focusedIndex = i;
                }),
              );
              if (stacked) {
                return Column(
                  children: [
                    Expanded(child: studioSheet),
                    SizedBox(height: 240, child: index),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: studioSheet),
                  SizedBox(width: 252, child: index),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _appear(String id, Widget child) {
    final first = !_seen.contains(id);
    if (first) _seen.add(id);
    if (!first) return child;
    return child.penumbraCardAppear(context);
  }
}

List<BoardNode> _paintOrder(List<BoardNode> nodes, List<BoardNode> conversation, String? focusedId) {
  final humans = [for (final node in conversation) if (node.kind != NodeKind.echo) node];
  final echoes = [for (final node in conversation) if (node.kind == NodeKind.echo) node];
  final ordered = [...humans, ...echoes];
  if (focusedId == null) return ordered;
  return [
    for (final node in ordered) if (node.id != focusedId) node,
    for (final node in nodes) if (node.id == focusedId) node,
  ];
}

class _Atelier extends StatelessWidget {
  const _Atelier({
    required this.board,
    required this.nodes,
    required this.conversation,
    required this.focusedId,
    required this.highContrast,
    required this.phrase,
    required this.summonError,
    required this.appear,
    required this.onFocus,
    required this.onDismissEcho,
    required this.toolbar,
  });

  final Board board;
  final List<BoardNode> nodes;
  final List<BoardNode> conversation;
  final String? focusedId;
  final bool highContrast;
  final String? phrase;
  final String? summonError;
  final Widget Function(String id, Widget child) appear;
  final ValueChanged<String> onFocus;
  final ValueChanged<String> onDismissEcho;
  final Widget toolbar;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final well = Color.lerp(theme.colors.background, theme.colors.foreground, 0.04)!;
    return ColoredBox(
      color: well,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (phrase != null) ...[
              FAlert(
                title: const Text('Save this recovery phrase'),
                subtitle: Text(
                  '$phrase\nOAuth and passkey accounts wrap your key with this phrase. We cannot recover it.',
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (summonError != null) ...[
              FAlert(variant: FAlertVariant.destructive, title: Text(summonError!)),
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
                            color: theme.colors.foreground.withValues(alpha: 0.18),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                          BoxShadow(
                            color: theme.colors.foreground.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: InteractiveViewer(
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
                            for (final node in _paintOrder(nodes, conversation, focusedId))
                              Positioned(
                                left: node.x,
                                top: node.y,
                                child: appear(
                                  node.id,
                                  _PaperSlip(
                                    node: node,
                                    numeral: EchoPairing.numeral(conversation, node),
                                    selected: node.id == focusedId,
                                    highContrast: highContrast,
                                    onFocus: () => onFocus(node.id),
                                    onDismiss: node.kind == NodeKind.echo ? () => onDismissEcho(node.id) : null,
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
              count == 1 ? '1 card' : '$count cards',
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

class _ComposeBar extends StatelessWidget {
  const _ComposeBar({
    required this.controller,
    required this.onPlace,
    required this.onSwatch,
    required this.onSummon,
    required this.summoning,
  });

  final TextEditingController controller;
  final VoidCallback onPlace;
  final VoidCallback onSwatch;
  final VoidCallback? onSummon;
  final bool summoning;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.colors.border),
          boxShadow: [
            BoxShadow(
              color: theme.colors.foreground.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tight = constraints.maxWidth < 620;
              final field = FTextField(
                hint: 'A thought, privately held',
                control: FTextFieldControl.managed(controller: controller),
              );
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(onPress: onPlace, child: const Text('Place')),
                  FButton(variant: FButtonVariant.outline, onPress: onSwatch, child: const Text('Swatch')),
                  if (onSummon != null || summoning)
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: summoning ? null : onSummon,
                      prefix: summoning
                          ? const SizedBox(width: 14, height: 14, child: FCircularProgress())
                          : null,
                      child: const Text('Summon an echo'),
                    ),
                ],
              );
              if (tight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field,
                    const SizedBox(height: 8),
                    actions,
                  ],
                );
              }
              return Row(
                children: [
                  Text(
                    'Compose',
                    style: theme.typography.xs.copyWith(
                      fontFamily: PenumbraInk.displayFamily,
                      color: theme.colors.mutedForeground,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: 28,
                      child: VerticalDivider(width: 1, thickness: 1, color: theme.colors.border),
                    ),
                  ),
                  Expanded(child: field),
                  const SizedBox(width: 8),
                  actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardIndex extends StatelessWidget {
  const _CardIndex({
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
  Widget build(BuildContext context) {
    final theme = context.theme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          left: stacked ? BorderSide.none : BorderSide(color: theme.colors.border),
          top: stacked ? BorderSide(color: theme.colors.border) : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Index',
              style: theme.typography.lg.copyWith(
                fontFamily: PenumbraInk.displayFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A conversation. Arrow keys move the selected slip.',
              style: theme.typography.xs.copyWith(color: theme.colors.mutedForeground, height: 1.4),
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
              child: ListView.builder(
                itemCount: conversation.length,
                itemBuilder: (context, index) {
                  final node = conversation[index];
                  final selected = node.id == focusedId;
                  final numeral = EchoPairing.numeral(conversation, node);
                  final echo = node.kind == NodeKind.echo;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: echo
                        ? 'Echo of $numeral, ${node.semanticsLabel}'
                        : 'Card $numeral of ${conversation.where((n) => n.kind != NodeKind.echo).length}, ${node.semanticsLabel}',
                    child: GestureDetector(
                      onTap: () => onSelect(node.id),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: selected ? theme.colors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(echo ? 28 : 12, 12, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                numeral,
                                style: theme.typography.xs.copyWith(
                                  fontFamily: PenumbraInk.displayFamily,
                                  fontStyle: echo ? FontStyle.italic : FontStyle.normal,
                                  color: selected ? theme.colors.primary : theme.colors.mutedForeground,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                echo ? (node.text ?? 'Echo') : node.semanticsLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.typography.sm.copyWith(
                                  fontFamily: PenumbraInk.displayFamily,
                                  fontStyle: echo ? FontStyle.italic : FontStyle.normal,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperSlip extends StatelessWidget {
  const _PaperSlip({
    required this.node,
    required this.numeral,
    required this.selected,
    required this.highContrast,
    required this.onFocus,
    this.onDismiss,
  });

  final BoardNode node;
  final String numeral;
  final bool selected;
  final bool highContrast;
  final VoidCallback onFocus;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final echo = node.kind == NodeKind.echo;
    final slip = ConstrainedBox(
      constraints: BoxConstraints(minWidth: echo ? 168 : 176, maxWidth: echo ? 240 : 260),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected
                ? theme.colors.primary
                : echo
                ? theme.colors.primary.withValues(alpha: highContrast ? 1 : 0.45)
                : theme.colors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: highContrast || echo
              ? const []
              : [
                  BoxShadow(
                    color: theme.colors.foreground.withValues(alpha: selected ? 0.16 : 0.08),
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
                    numeral,
                    style: theme.typography.xs.copyWith(
                      fontFamily: PenumbraInk.displayFamily,
                      fontStyle: echo ? FontStyle.italic : FontStyle.normal,
                      color: selected ? theme.colors.primary : theme.colors.mutedForeground,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (echo && selected && onDismiss != null)
                    Semantics(
                      button: true,
                      label: 'Dismiss this echo',
                      child: GestureDetector(
                        onTap: onDismiss,
                        child: Text(
                          'Dismiss',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    )
                  else if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: theme.colors.primary, shape: BoxShape.circle),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (node.kind == NodeKind.swatch)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColoredBox(
                      color: Color(node.colorArgb ?? 0xFF000000),
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
              else
                Text(
                  node.text ?? (echo ? 'Echo' : 'Untitled note'),
                  style: theme.typography.md.copyWith(
                    fontFamily: PenumbraInk.displayFamily,
                    fontStyle: echo ? FontStyle.italic : FontStyle.normal,
                    height: 1.35,
                    fontWeight: echo ? FontWeight.w400 : FontWeight.w500,
                    color: echo ? theme.colors.mutedForeground : theme.colors.foreground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: echo ? '${node.semanticsLabel}, $numeral' : 'Card $numeral, ${node.semanticsLabel}',
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) onFocus();
        },
        child: GestureDetector(
          onTap: onFocus,
          child: selected && !highContrast && !echo
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colors.primary.withValues(alpha: 0.45)),
                  ),
                  child: Padding(padding: const EdgeInsets.all(5), child: slip),
                )
              : slip,
        ),
      ),
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
        Offset(parent.x + EchoPairing.slipWidth, parent.y + EchoPairing.slipHeight * 0.45),
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
    final plate = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    final rulePaint = Paint()
      ..color = rule
      ..strokeWidth = 1;

    canvas.drawRect(plate, Paint()
      ..color = rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

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
        canvas.drawLine(Offset(plate.left + 16, y), Offset(plate.right - 16, y), line);
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
