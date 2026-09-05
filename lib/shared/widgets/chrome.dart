import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final user = ref.watch(authControllerProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final punctum = appearance == PenumbraAppearance.highContrast ? theme.colors.foreground : PenumbraInk.copper;

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
                  padding: EdgeInsets.symmetric(horizontal: tiny ? 12 : 24, vertical: tiny ? 12 : 16),
                  child: Row(
                    children: [
                      _Wordmark(punctum: punctum, compact: tiny),
                      if (!compact && widget.title != null) ...[
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            widget.title!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.sm.copyWith(color: theme.colors.mutedForeground),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (!tiny) const _NavLink(label: 'Making of', path: '/making-of'),
                      if (compact)
                        _OverflowNav(signedIn: user != null, includeMakingOf: tiny)
                      else ...[
                        const _NavLink(label: 'Legal', path: '/legal/privacy'),
                        if (user != null) ...[
                          const _NavLink(label: 'Boards', path: '/boards'),
                          const _NavLink(label: 'Privacy', path: '/privacy'),
                        ],
                      ],
                      const SizedBox(width: 8),
                      if (user != null)
                        tiny
                            ? FButton.icon(
                                semanticsLabel: 'Sign out',
                                onPress: () => ref.read(authControllerProvider.notifier).signOut(),
                                child: const Icon(FLucideIcons.logOut),
                              )
                            : FButton(
                                variant: FButtonVariant.ghost,
                                mainAxisSize: MainAxisSize.min,
                                semanticsLabel: 'Sign out',
                                onPress: () => ref.read(authControllerProvider.notifier).signOut(),
                                prefix: const Icon(FLucideIcons.logOut),
                                child: const Text('Sign out'),
                              )
                      else
                        FButton(
                          variant: FButtonVariant.primary,
                          mainAxisSize: MainAxisSize.min,
                          size: tiny ? FButtonSizeVariant.sm : FButtonSizeVariant.md,
                          onPress: () => context.go('/sign-in'),
                          child: const Text('Sign in'),
                        ),
                      const SizedBox(width: 4),
                      FButton.icon(
                        semanticsLabel:
                            'Appearance: ${appearance.spokenName}. Switch to ${appearance.next.spokenName}.',
                        size: tiny ? FButtonSizeVariant.sm : FButtonSizeVariant.md,
                        onPress: () {
                          final next = appearance.next;
                          ref.read(appearanceProvider.notifier).cycle();
                          announce(context, 'Appearance: ${next.spokenName}');
                        },
                        child: Icon(switch (appearance) {
                          PenumbraAppearance.light => FLucideIcons.sun,
                          PenumbraAppearance.dark => FLucideIcons.moon,
                          PenumbraAppearance.highContrast => FLucideIcons.contrast,
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
              label: 'Main content',
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
                  semanticsLabel: 'Skip to content',
                  onPress: () => _mainFocus.requestFocus(),
                  child: const Text('Skip to content'),
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
  const _Wordmark({required this.punctum, this.compact = false});

  final Color punctum;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      header: true,
      child: FButton(
        variant: FButtonVariant.ghost,
        mainAxisSize: MainAxisSize.min,
        semanticsLabel: 'Penumbra home',
        onPress: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Penumbra',
              style: (compact ? theme.typography.lg : theme.typography.xl).copyWith(
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
  const _OverflowNav({required this.signedIn, this.includeMakingOf = false});

  final bool signedIn;
  final bool includeMakingOf;

  @override
  Widget build(BuildContext context) {
    return FPopoverMenu(
      menu: [
        FItemGroup(
          children: [
            if (includeMakingOf) FItem(title: const Text('Making of'), onPress: () => context.go('/making-of')),
            FItem(title: const Text('Legal'), onPress: () => context.go('/legal/privacy')),
            if (signedIn) ...[
              FItem(title: const Text('Boards'), onPress: () => context.go('/boards')),
              FItem(title: const Text('Privacy'), onPress: () => context.go('/privacy')),
            ],
          ],
        ),
      ],
      builder: (context, controller, _) => FButton.icon(
        semanticsLabel: 'Open menu',
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
    final selected = current == path || (path != '/' && current.startsWith(path));
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
  await SemanticsService.sendAnnouncement(View.of(context), message, TextDirection.ltr);
}
