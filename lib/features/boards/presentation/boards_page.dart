import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/a11y/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/chrome.dart';
import '../domain/board.dart';

class BoardsPage extends ConsumerWidget {
  const BoardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PenumbraChrome(
      title: AppLocalizations.of(context).navBoards,
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
    final next = await showFDialog<String>(
      context: context,
      builder: (context, style, animation) =>
          _RenameBoardDialog(animation: animation, initial: board.title),
    );
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
        announce(context, AppLocalizations.of(context).boardRenamed);
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
              ? AppLocalizations.of(context).boardRestrictedAnnounce
              : AppLocalizations.of(context).boardUnrestricted,
        );
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  Future<void> _delete(Board board) async {
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) {
        final l10n = AppLocalizations.of(context);
        return FDialog(
          animation: animation,
          title: Text(l10n.deleteBoardTitle),
          body: Text(l10n.deleteBoardBody),
          actions: [
            FButton(
              variant: FButtonVariant.destructive,
              onPress: () => Navigator.of(context).pop(true),
              child: Text(l10n.deleteThisBoard),
            ),
            FButton(
              variant: FButtonVariant.outline,
              onPress: () => Navigator.of(context).pop(false),
              child: Text(l10n.keepIt),
            ),
          ],
        );
      },
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
        announce(context, AppLocalizations.of(context).boardDeleted);
      },
      err: (failure) => announce(context, failure.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    return PenumbraPage(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.boardsTitle,
              style: theme.typography.xl3.copyWith(fontWeight: FontWeight.w500),
            ).penumbraEnter(context),
            const SizedBox(height: 8),
            Text(
              l10n.boardsLede,
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
                    label: Text(l10n.newBoard),
                    hint: l10n.newBoardHint,
                    control: FTextFieldControl.managed(controller: _title),
                  ),
                ),
                const SizedBox(width: 12),
                FButton(
                  onPress: _create,
                  prefix: const Icon(FLucideIcons.plus),
                  child: Text(l10n.create),
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

class _RenameBoardDialog extends StatefulWidget {
  const _RenameBoardDialog({required this.animation, required this.initial});

  final Animation<double> animation;
  final String initial;

  @override
  State<_RenameBoardDialog> createState() => _RenameBoardDialogState();
}

class _RenameBoardDialogState extends State<_RenameBoardDialog> {
  late final _title = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FDialog(
      animation: widget.animation,
      title: Text(AppLocalizations.of(context).renameDialogTitle),
      body: FTextField(
        label: Text(AppLocalizations.of(context).titleLabel),
        control: FTextFieldControl.managed(controller: _title),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.of(context).pop(_title.text.trim()),
          child: Text(AppLocalizations.of(context).saveTitle),
        ),
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ],
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
    final l10n = AppLocalizations.of(context);
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
                board.restricted
                    ? l10n.restricted
                    : _relative(board.updatedAt, l10n, context),
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
                    label: l10n.openBoard(board.title),
                    child: GestureDetector(
                      onTap: widget.onOpen,
                      child: Text(
                        l10n.open,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.renameBoard(board.title),
                    child: GestureDetector(
                      onTap: widget.onRename,
                      child: Text(
                        l10n.rename,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: board.restricted
                        ? l10n.unrestrictBoard(board.title)
                        : l10n.restrictBoard(board.title),
                    child: GestureDetector(
                      onTap: widget.onToggleRestrict,
                      child: Text(
                        board.restricted ? l10n.unrestrict : l10n.restrict,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.deleteBoard(board.title),
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Text(
                        l10n.delete,
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
          AppLocalizations.of(context).emptyBoards,
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

String _relative(DateTime time, AppLocalizations l10n, BuildContext context) {
  final delta = DateTime.now().toUtc().difference(time.toUtc());
  if (delta.inMinutes < 1) return l10n.justNow;
  if (delta.inHours < 1) return l10n.minutesAgo(delta.inMinutes);
  if (delta.inDays < 1) return l10n.hoursAgo(delta.inHours);
  if (delta.inDays < 14) return l10n.daysAgo(delta.inDays);
  final locale = Localizations.localeOf(context);
  final tag = locale.languageCode == 'sv' ? 'sv_SE' : 'en';
  return DateFormat.yMd(tag).format(time.toLocal());
}
