import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/a11y/motion.dart';
import '../features/auth/presentation/sign_in_page.dart';
import '../features/boards/presentation/boards_page.dart';
import '../features/canvas/presentation/canvas_page.dart';
import '../features/landing/presentation/landing_page.dart';
import '../features/legal/presentation/legal_page.dart';
import '../features/privacy/presentation/privacy_page.dart';
import '../features/story/presentation/making_of_page.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authControllerProvider).value;
      final path = state.uri.path;
      final protected = path.startsWith('/boards') || path == '/privacy';
      if (protected && user == null) return '/sign-in';
      if (path == '/sign-in' && user != null) return '/boards';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => penumbraRoutePage(
          key: state.pageKey,
          child: const LandingPage(),
          context: context,
        ),
      ),
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => penumbraRoutePage(
          key: state.pageKey,
          child: const SignInPage(),
          context: context,
        ),
      ),
      GoRoute(
        path: '/boards',
        pageBuilder: (context, state) => penumbraRoutePage(
          key: state.pageKey,
          child: const BoardsPage(),
          context: context,
        ),
      ),
      GoRoute(
        path: '/boards/:id',
        pageBuilder: (context, state) => penumbraRoutePage(
          key: state.pageKey,
          child: CanvasPage(boardId: state.pathParameters['id']!),
          context: context,
        ),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) => penumbraRoutePage(
          key: state.pageKey,
          child: const PrivacyPage(),
          context: context,
        ),
      ),
      GoRoute(
        path: '/making-of',
        pageBuilder: (context, state) => penumbraRoutePage(
          key: state.pageKey,
          child: const MakingOfPage(),
          context: context,
        ),
      ),
      GoRoute(
        path: '/legal/:slug',
        pageBuilder: (context, state) => penumbraRoutePage(
          key: state.pageKey,
          child: LegalPage(slug: state.pathParameters['slug'] ?? 'privacy'),
          context: context,
        ),
      ),
    ],
    errorBuilder: (context, state) => const LandingPage(),
  );
});

CustomTransitionPage<void> penumbraRoutePage({
  required LocalKey key,
  required Widget child,
  required BuildContext context,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: penumbraRouteDuration(context),
    reverseTransitionDuration: penumbraRouteDuration(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (penumbraReduceMotion(context)) return child;
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
