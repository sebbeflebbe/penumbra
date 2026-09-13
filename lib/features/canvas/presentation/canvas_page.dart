import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';
import '../../auth/presentation/locked_studio.dart';
import '../../boards/domain/board.dart';
import '../../boards/domain/echo_pairing.dart';
import '../../boards/domain/node_motion.dart';
import '../../privacy/domain/privacy_models.dart';
import 'atelier.dart';
import 'card_index.dart';
import 'compose_bar.dart';

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
    final locked =
        ref.read(authRepositoryProvider).current?.needsPhraseUnlock ?? false;
    if (!mounted) return;
    setState(() {
      _board = board.okOrNull;
      _error =
          board.errOrNull?.message ??
          (locked ? null : nodes.errOrNull?.message);
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
    final moved = next.firstWhere((item) => item.id == id);
    announce(
      context,
      'Moved. Card ${EchoPairing.numeral(EchoPairing.conversation(_nodes), moved)}.',
    );
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
    final numeral = EchoPairing.numeral(
      EchoPairing.conversation(_nodes),
      node.first,
    );
    announce(context, 'Moved. Card $numeral.');
    await _untangleEchoes();
  }

  bool get _highContrast {
    final bg = context.theme.colors.background;
    return bg == const Color(0xFF000000) || bg == const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final phrase = ref.watch(authRepositoryProvider).pendingRecoveryPhrase;
    if (user?.needsPhraseUnlock == true) {
      return PenumbraChrome(
        title: _board?.title,
        child: LockedStudio(onUnlocked: _load),
      );
    }
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

    return PenumbraChrome(
      title: _board!.title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 780;
          final conversation = EchoPairing.conversation(_nodes);
          final studioSheet = CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                  _nudge(-16, 0),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                  _nudge(16, 0),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _nudge(0, -16),
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _nudge(0, 16),
            },
            child: Focus(
              autofocus: true,
              child: Atelier(
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
                toolbar: ComposeBar(
                  controller: _note,
                  enabled: !_restricted,
                  onPlace: _addNote,
                  onSwatch: _addSwatch,
                  onSummon: !_restricted && _canSummon ? _summonEcho : null,
                  summoning: _summoning,
                ),
              ),
            ),
          );
          final index = CardIndex(
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
    );
  }

  Widget _appear(String id, Widget child) {
    final first = !_seen.contains(id);
    if (first) _seen.add(id);
    if (!first) return child;
    return child.penumbraCardAppear(context);
  }
}
