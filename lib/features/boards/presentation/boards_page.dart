import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../shared/widgets/chrome.dart';
import '../domain/board.dart';

class BoardsPage extends ConsumerWidget {
  const BoardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PenumbraChrome(
      title: 'Boards',
      child: FutureBuilder(
        future: ref.read(boardRepositoryProvider).listMine(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: FCircularProgress());
          }
          final result = snapshot.data!;
          return result.when(
            err: (failure) => PenumbraPage(
              child: FAlert(
                variant: FAlertVariant.destructive,
                title: Text(failure.message),
              ),
            ),
            ok: (boards) => _BoardsBody(boards: boards),
          );
        },
      ),
    );
  }
}

class _BoardsBody extends ConsumerStatefulWidget {
  const _BoardsBody({required this.boards});
  final List<Board> boards;

  @override
  ConsumerState<_BoardsBody> createState() => _BoardsBodyState();
}

class _BoardsBodyState extends ConsumerState<_BoardsBody> {
  late List<Board> _boards = widget.boards;
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final result = await ref
        .read(boardRepositoryProvider)
        .create(title: _title.text);
    if (!mounted) return;
    result.when(
      ok: (board) {
        setState(() => _boards = [board, ..._boards]);
        _title.clear();
        context.go('/boards/${board.id}');
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  Future<void> _rename(Board board) async {
    final controller = TextEditingController(text: board.title);
    final next = await showFDialog<String>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        title: const Text('Rename this board'),
        body: FTextField(
          label: const Text('Title'),
          control: FTextFieldControl.managed(controller: controller),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save title'),
          ),
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || next == null || next.isEmpty || next == board.title) return;
    final result = await ref
        .read(boardRepositoryProvider)
        .rename(id: board.id, title: next);
    if (!mounted) return;
    result.when(
      ok: (updated) {
        setState(
          () => _boards = [
            for (final item in _boards) item.id == updated.id ? updated : item,
          ],
        );
        announce(context, 'Board renamed.');
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  Future<void> _toggleRestrict(Board board) async {
    final result = await ref
        .read(boardRepositoryProvider)
        .setRestricted(id: board.id, restricted: !board.restricted);
    if (!mounted) return;
    result.when(
      ok: (updated) {
        setState(
          () => _boards = [
            for (final item in _boards) item.id == updated.id ? updated : item,
          ],
        );
        announce(
          context,
          updated.restricted
              ? 'Board restricted (Art. 18).'
              : 'Board unrestricted.',
        );
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  Future<void> _delete(Board board) async {
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => FDialog(
        animation: animation,
        title: const Text('Delete this board'),
        body: const Text(
          'The board and its cards will be removed. This cannot be undone.',
        ),
        actions: [
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () => Navigator.of(context).pop(true),
            child: const Text('Delete this board'),
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
    final result = await ref.read(boardRepositoryProvider).delete(board.id);
    if (!mounted) return;
    result.when(
      ok: (_) {
        setState(
          () => _boards = [
            for (final item in _boards)
              if (item.id != board.id) item,
          ],
        );
        announce(context, 'Board deleted.');
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return PenumbraPage(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Boards',
              style: theme.typography.xl3.copyWith(fontWeight: FontWeight.w500),
            ).penumbraEnter(context),
            const SizedBox(height: 8),
            Text(
              'Each board is yours alone. Titles are metadata; the cards inside are ciphertext.',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ).penumbraEnter(context, delayMs: 40),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FTextField(
                    label: const Text('New board'),
                    hint: 'Quiet thoughts',
                    control: FTextFieldControl.managed(controller: _title),
                  ),
                ),
                const SizedBox(width: 12),
                FButton(
                  onPress: _create,
                  prefix: const Icon(FLucideIcons.plus),
                  child: const Text('Create'),
                ),
              ],
            ).penumbraEnter(context, delayMs: 80),
            const SizedBox(height: 36),
            if (_boards.isEmpty)
              const _EmptyBoards().penumbraEnter(context, delayMs: 100)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _boards.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  childAspectRatio: 0.92,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final board = _boards[index];
                  return _BoardTile(
                    board: board,
                    onOpen: () => context.go('/boards/${board.id}'),
                    onRename: () => _rename(board),
                    onToggleRestrict: () => _toggleRestrict(board),
                    onDelete: () => _delete(board),
                  ).penumbraEnter(context, index: index);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardTile extends StatefulWidget {
  const _BoardTile({
    required this.board,
    required this.onOpen,
    required this.onRename,
    required this.onToggleRestrict,
    required this.onDelete,
  });

  final Board board;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onToggleRestrict;
  final VoidCallback onDelete;

  @override
  State<_BoardTile> createState() => _BoardTileState();
}

class _BoardTileState extends State<_BoardTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final board = widget.board;
    final motion = !penumbraReduceMotion(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        label: board.title,
        child: AnimatedContainer(
          duration: motion ? const Duration(milliseconds: 180) : Duration.zero,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colors.border),
            boxShadow: motion && _hover
                ? [
                    BoxShadow(
                      color: theme.colors.foreground.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                board.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.lg.copyWith(
                  fontFamily: PenumbraInk.displayFamily,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                board.restricted ? 'Restricted' : _relative(board.updatedAt),
                style: theme.typography.xs.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Semantics(
                    button: true,
                    label: 'Open ${board.title}',
                    child: GestureDetector(
                      onTap: widget.onOpen,
                      child: Text(
                        'Open',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Rename ${board.title}',
                    child: GestureDetector(
                      onTap: widget.onRename,
                      child: Text(
                        'Rename',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: board.restricted
                        ? 'Unrestrict ${board.title}'
                        : 'Restrict ${board.title}',
                    child: GestureDetector(
                      onTap: widget.onToggleRestrict,
                      child: Text(
                        board.restricted ? 'Unrestrict' : 'Restrict',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Delete ${board.title}',
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Text(
                        'Delete',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBoards extends StatelessWidget {
  const _EmptyBoards();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nothing here yet. Name a board, or enter the demo studio from home.',
          style: theme.typography.md.copyWith(
            color: theme.colors.mutedForeground,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 140,
          child: Stack(
            children: [
              Positioned(left: 0, top: 24, child: _ghost(theme, 180)),
              Positioned(left: 48, top: 8, child: _ghost(theme, 200)),
              Positioned(left: 96, top: 0, child: _ghost(theme, 160)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ghost(FThemeData theme, double width) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.border),
      ),
      child: SizedBox(width: width, height: 110),
    );
  }
}

String _relative(DateTime time) {
  final delta = DateTime.now().toUtc().difference(time.toUtc());
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  if (delta.inDays < 14) return '${delta.inDays}d ago';
  final local = time.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
