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
import '../../boards/domain/node_motion.dart';
import '../../privacy/domain/privacy_models.dart';
import 'paper_slip.dart';

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
  bool _echoConsented = false;
  bool _dragging = false;
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
    final consents = await ref.read(privacyRepositoryProvider).consents();
    if (!mounted) return;
    setState(() {
      _board = board.okOrNull;
      _error = board.errOrNull?.message ?? nodes.errOrNull?.message;
      _nodes = nodes.okOrNull ?? [];
      _echoConsented = hasGrantedConsent(
        consents.okOrNull ?? const [],
        ConsentKind.remoteEcho,
      );
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
        if ((swatch.x - echo.x).abs() < 200 &&
            (swatch.y - echo.y).abs() < 110) {
          await persist(
            swatch.copyWith(
              x: echo.x + EchoPairing.slipWidth + 36,
              y: swatch.y,
            ),
          );
          break;
        }
      }
    }

    if (changed && mounted) setState(() => _nodes = next);
  }

  bool get _restricted => _board?.restricted == true;

  Future<void> _addNote() async {
    if (_restricted) {
      announce(context, 'This board is restricted (Art. 18).');
      return;
    }
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
    if (_restricted) {
      announce(context, 'This board is restricted (Art. 18).');
      return;
    }
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
    if (_nodes.isEmpty || _restricted) {
      if (_restricted) announce(context, 'This board is restricted (Art. 18).');
      return;
    }
    final node = _nodes[_focusedIndex.clamp(0, _nodes.length - 1)];
    await _persistMove(node.id, dx.toDouble(), dy.toDouble());
  }

  Future<void> _persistMove(String id, double dx, double dy) async {
    if (dx == 0 && dy == 0) return;
    final previous = List<BoardNode>.from(_nodes);
    final next = NodeMotion.moved(previous, id: id, dx: dx, dy: dy);
    if (identical(next, previous)) return;
    setState(() => _nodes = next);
    final canvas = ref.read(canvasRepositoryProvider);
    String? error;
    for (final node in next) {
      final old = previous.firstWhere((item) => item.id == node.id);
      if (old.x == node.x && old.y == node.y) continue;
      final result = await canvas.upsert(node);
      result.when(ok: (_) {}, err: (failure) => error = failure.message);
    }
    if (!mounted) return;
    if (error != null) {
      announce(context, error!);
      return;
    }
    await _untangleEchoes();
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
    if (_restricted) {
      announce(context, 'This board is restricted (Art. 18).');
      return;
    }
    final parent = _selected;
    if (parent == null || !EchoPairing.canSummon(parent, _nodes) || _summoning)
      return;
    final composer = ref.read(echoComposerProvider);
    if (composer.remote && !_echoConsented) {
      final agreed = await _confirmRemoteEcho();
      if (!mounted || !agreed) return;
      final recorded = await ref
          .read(privacyRepositoryProvider)
          .recordConsent(ConsentKind.remoteEcho, granted: true);
      if (!mounted) return;
      recorded.when(
        ok: (_) => _echoConsented = true,
        err: (failure) => announce(context, failure.message),
      );
      if (!_echoConsented) return;
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
          _nodes = [
            for (final n in _nodes)
              if (n.id != id) n,
          ];
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

  Future<void> _saveText(BoardNode node, String text) async {
    if (_restricted) {
      announce(context, 'This board is restricted (Art. 18).');
      return;
    }
    final result = await ref
        .read(canvasRepositoryProvider)
        .upsert(node.copyWith(text: text));
    if (!mounted) return;
    result.when(
      ok: (updated) {
        setState(
          () => _nodes = [
            for (final item in _nodes) item.id == updated.id ? updated : item,
          ],
        );
        announce(context, 'Note saved.');
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  Future<void> _deleteHuman(BoardNode node) async {
    if (_restricted) {
      announce(context, 'This board is restricted (Art. 18).');
      return;
    }
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        title: const Text('Remove this slip'),
        body: const Text(
          'The note and its echo, if any, will be removed from this board.',
        ),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('Delete this note'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final result = await ref.read(canvasRepositoryProvider).delete(node.id);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(() {
          _nodes = [
            for (final item in _nodes)
              if (item.id != node.id && item.parentId != node.id) item,
          ];
          if (_nodes.isEmpty) {
            _focusedIndex = 0;
          } else {
            _focusedIndex = _focusedIndex.clamp(0, _nodes.length - 1);
          }
        });
        announce(context, 'Note deleted.');
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  void _acknowledgePhrase() {
    ref.read(authRepositoryProvider).acknowledgeRecoveryPhrase();
    announce(context, 'Recovery phrase saved.');
    setState(() {});
  }

  Future<void> _commitDrag(String id) async {
    setState(() => _dragging = false);
    final canvas = ref.read(canvasRepositoryProvider);
    final node = _nodes.where((item) => item.id == id);
    if (node.isEmpty) return;
    String? error;
    Future<void> save(BoardNode value) async {
      final result = await canvas.upsert(value);
      result.when(ok: (_) {}, err: (failure) => error = failure.message);
    }

    await save(node.first);
    if (node.first.kind == NodeKind.text) {
      final echo = EchoPairing.echoFor(_nodes, id);
      if (echo != null) await save(echo);
    }
    if (!mounted) return;
    if (error != null) {
      announce(context, error!);
      return;
    }
    announce(context, 'Moved');
    await _untangleEchoes();
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
        child: PenumbraPage(
          child: FAlert(
            variant: FAlertVariant.destructive,
            title: Text(_error!),
          ),
        ),
      );
    }
    if (_board == null) {
      return const PenumbraChrome(child: Center(child: FCircularProgress()));
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _nudge(-16, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _nudge(16, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _nudge(0, -16),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _nudge(0, 16),
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
                panEnabled: !_dragging,
                appear: _appear,
                onFocus: (id) => setState(() {
                  final i = _nodes.indexWhere((n) => n.id == id);
                  if (i >= 0) _focusedIndex = i;
                }),
                onDismissEcho: _restricted ? null : _dismissEcho,
                onAcknowledgePhrase: _acknowledgePhrase,
                onSaveText: _restricted
                    ? null
                    : (node, text) => _saveText(node, text),
                onDelete: _restricted ? null : _deleteHuman,
                onDragStart: _restricted
                    ? null
                    : (id) => setState(() {
                        _dragging = true;
                        final i = _nodes.indexWhere((n) => n.id == id);
                        if (i >= 0) _focusedIndex = i;
                      }),
                onDrag: _restricted
                    ? null
                    : (id, delta) => setState(() {
                        _nodes = NodeMotion.moved(
                          _nodes,
                          id: id,
                          dx: delta.dx,
                          dy: delta.dy,
                        );
                      }),
                onDragEnd: _restricted ? null : _commitDrag,
                toolbar: _ComposeBar(
                  controller: _note,
                  enabled: !_restricted,
                  onPlace: _addNote,
                  onSwatch: _addSwatch,
                  onSummon: !_restricted && _canSummon ? _summonEcho : null,
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

class _Atelier extends StatelessWidget {
  const _Atelier({
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
                title: const Text('Save this recovery phrase'),
                subtitle: Text(
                  '$phrase\nOAuth and passkey accounts wrap your key with this phrase. We cannot recover it.',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FButton(
                  onPress: onAcknowledgePhrase,
                  child: const Text('I have saved this phrase'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (board.restricted) ...[
              const FAlert(
                title: Text('This board is restricted (Art. 18).'),
                subtitle: Text(
                  'Place, edit, delete, and move are paused until you unrestrict it.',
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onPlace;
  final VoidCallback onSwatch;
  final VoidCallback? onSummon;
  final bool summoning;
  final bool enabled;

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
                enabled: enabled,
                control: FTextFieldControl.managed(controller: controller),
              );
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(
                    onPress: enabled ? onPlace : null,
                    child: const Text('Place'),
                  ),
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: enabled ? onSwatch : null,
                    child: const Text('Swatch'),
                  ),
                  if (onSummon != null || summoning)
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: summoning || !enabled ? null : onSummon,
                      prefix: summoning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: FCircularProgress(),
                            )
                          : null,
                      child: const Text('Summon an echo'),
                    ),
                ],
              );
              if (tight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [field, const SizedBox(height: 8), actions],
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
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: theme.colors.border,
                      ),
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
          left: stacked
              ? BorderSide.none
              : BorderSide(color: theme.colors.border),
          top: stacked
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
              'Index',
              style: theme.typography.lg.copyWith(
                fontFamily: PenumbraInk.displayFamily,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A conversation. Arrow keys or Move reposition the selected slip.',
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
                                    ? (node.text ?? 'Echo')
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
