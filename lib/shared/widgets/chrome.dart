import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

class PenumbraChrome extends ConsumerStatefulWidget {
  const PenumbraChrome({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  @override
  ConsumerState<PenumbraChrome> createState() => _PenumbraChromeState();
}

class _PenumbraChromeState extends ConsumerState<PenumbraChrome> {
  final _mainFocus = FocusNode(debugLabel: 'main');

  @override
  void dispose() {
    _mainFocus.dispose();
    super.dispose();
  }

  String _appearanceName(AppLocalizations l10n, PenumbraAppearance value) {
    return switch (value) {
      PenumbraAppearance.system => l10n.appearanceSystem,
      PenumbraAppearance.light => l10n.appearanceLight,
      PenumbraAppearance.dark => l10n.appearanceDark,
      PenumbraAppearance.highContrast => l10n.appearanceHighContrast,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final locale = ref.watch(localeProvider);
    final swedish = locale.languageCode == 'sv';
    final punctum = appearance == PenumbraAppearance.highContrast
        ? theme.colors.foreground
        : PenumbraInk.copper;

    return Stack(
      children: [
        FScaffold(
          childPad: false,
          header: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colors.background,
              border: Border(bottom: BorderSide(color: theme.colors.border)),
            ),
            child: Builder(
              builder: (context) {
                final width = MediaQuery.sizeOf(context).width;
                final compact = width < 900;
                final tiny = width < 640;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tiny ? 12 : 24,
                    vertical: tiny ? 12 : 16,
                  ),
                  child: Row(
                    children: [
                      _Wordmark(
                        punctum: punctum,
                        compact: tiny,
                        homeLabel: l10n.navHome,
                      ),
                      if (!compact && widget.title != null) ...[
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            widget.title!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!tiny)
                        _NavLink(label: l10n.navMakingOf, path: '/making-of'),
                      if (compact)
                        _OverflowNav(
                          signedIn: user != null,
                          includeMakingOf: tiny,
                          makingOf: l10n.navMakingOf,
                          legal: l10n.navLegal,
                          boards: l10n.navBoards,
                          privacy: l10n.navPrivacy,
                          menuLabel: l10n.navMenu,
                        )
                      else ...[
                        _NavLink(label: l10n.navLegal, path: '/legal/privacy'),
                        if (user != null) ...[
                          _NavLink(label: l10n.navBoards, path: '/boards'),
                          _NavLink(label: l10n.navPrivacy, path: '/privacy'),
                        ],
                      ],
                      const SizedBox(width: 8),
                      if (user != null)
                        tiny
                            ? FButton.icon(
                                semanticsLabel: l10n.navSignOut,
                                onPress: () => ref
                                    .read(authControllerProvider.notifier)
                                    .signOut(),
                                child: const Icon(FLucideIcons.logOut),
                              )
                            : FButton(
                                variant: FButtonVariant.ghost,
                                mainAxisSize: MainAxisSize.min,
                                semanticsLabel: l10n.navSignOut,
                                onPress: () => ref
                                    .read(authControllerProvider.notifier)
                                    .signOut(),
                                prefix: const Icon(FLucideIcons.logOut),
                                child: Text(l10n.navSignOut),
                              )
                      else
                        FButton(
                          variant: FButtonVariant.primary,
                          mainAxisSize: MainAxisSize.min,
                          size: tiny
                              ? FButtonSizeVariant.sm
                              : FButtonSizeVariant.md,
                          onPress: () => context.go('/sign-in'),
                          child: Text(l10n.navSignIn),
                        ),
                      const SizedBox(width: 4),
                      FButton(
                        variant: FButtonVariant.ghost,
                        mainAxisSize: MainAxisSize.min,
                        size: tiny
                            ? FButtonSizeVariant.sm
                            : FButtonSizeVariant.md,
                        semanticsLabel: swedish
                            ? l10n.languageSwitchToEnglish
                            : l10n.languageSwitchToSwedish,
                        onPress: () {
                          ref.read(localeProvider.notifier).toggle();
                          announce(
                            context,
                            swedish
                                ? l10n.languageAnnouncedEnglish
                                : l10n.languageAnnouncedSwedish,
                          );
                        },
                        child: Text(
                          swedish ? l10n.languageEnglish : l10n.languageSwedish,
                        ),
                      ),
                      const SizedBox(width: 4),
                      FButton.icon(
                        semanticsLabel: l10n.appearanceSemantics(
                          _appearanceName(l10n, appearance),
                          _appearanceName(l10n, appearance.next),
                        ),
                        size: tiny
                            ? FButtonSizeVariant.sm
                            : FButtonSizeVariant.md,
                        onPress: () {
                          final next = appearance.next;
                          ref.read(appearanceProvider.notifier).cycle();
                          announce(
                            context,
                            l10n.appearanceAnnounced(
                              _appearanceName(l10n, next),
                            ),
                          );
                        },
                        child: Icon(switch (appearance) {
                          PenumbraAppearance.light => FLucideIcons.sun,
                          PenumbraAppearance.dark => FLucideIcons.moon,
                          PenumbraAppearance.highContrast =>
                            FLucideIcons.contrast,
                          PenumbraAppearance.system => FLucideIcons.sunMoon,
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          child: Focus(
            focusNode: _mainFocus,
            child: Semantics(
              container: true,
              label: l10n.mainContent,
              explicitChildNodes: true,
              child: SelectionArea(child: widget.child),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Focus(
            child: Builder(
              builder: (context) {
                if (!Focus.of(context).hasFocus) return const SizedBox.shrink();
                return FButton(
                  semanticsLabel: l10n.skipToContent,
                  onPress: () => _mainFocus.requestFocus(),
                  child: Text(l10n.skipToContent),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.punctum,
    required this.homeLabel,
    this.compact = false,
  });

  final Color punctum;
  final String homeLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      header: true,
      child: FButton(
        variant: FButtonVariant.ghost,
        mainAxisSize: MainAxisSize.min,
        semanticsLabel: homeLabel,
        onPress: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Penumbra',
              style: (compact ? theme.typography.lg : theme.typography.xl)
                  .copyWith(
                    fontFamily: PenumbraInk.displayFamily,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: punctum, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowNav extends StatelessWidget {
  const _OverflowNav({
    required this.signedIn,
    required this.makingOf,
    required this.legal,
    required this.boards,
    required this.privacy,
    required this.menuLabel,
    this.includeMakingOf = false,
  });

  final bool signedIn;
  final bool includeMakingOf;
  final String makingOf;
  final String legal;
  final String boards;
  final String privacy;
  final String menuLabel;

  @override
  Widget build(BuildContext context) {
    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: [
            if (includeMakingOf)
              FItem(
                title: Text(makingOf),
                onPress: () => context.go('/making-of'),
              ),
            FItem(
              title: Text(legal),
              onPress: () => context.go('/legal/privacy'),
            ),
            if (signedIn) ...[
              FItem(title: Text(boards), onPress: () => context.go('/boards')),
              FItem(
                title: Text(privacy),
                onPress: () => context.go('/privacy'),
              ),
            ],
          ],
        ),
      ],
      builder: (context, controller, _) => FButton.icon(
        semanticsLabel: menuLabel,
        onPress: () => controller.toggle(),
        child: const Icon(FLucideIcons.menu),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.path});

  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;
    final selected =
        current == path || (path != '/' && current.startsWith(path));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FButton(
        variant: selected ? FButtonVariant.secondary : FButtonVariant.ghost,
        mainAxisSize: MainAxisSize.min,
        onPress: () => context.go(path),
        child: Text(label),
      ),
    );
  }
}

class PenumbraPage extends StatelessWidget {
  const PenumbraPage({required this.child, this.maxWidth = 1120, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pad = width >= 900 ? 48.0 : 24.0;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        ),
      ),
    );
  }
}

Future<void> announce(BuildContext context, String message) async {
  await SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}
