import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class PenumbraApp extends ConsumerWidget {
  const PenumbraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appearance = ref.watch(appearanceProvider);
    final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final pair = PenumbraThemes.pair(appearance, platform);
    final light = pair.$1;
    final dark = appearance == PenumbraAppearance.dark || (appearance == PenumbraAppearance.system && platform == Brightness.dark)
        ? pair.$2
        : pair.$1;
    final active = switch (appearance) {
      PenumbraAppearance.dark => dark,
      PenumbraAppearance.highContrast when platform == Brightness.dark => PenumbraThemes.highContrastDark(),
      PenumbraAppearance.highContrast => PenumbraThemes.highContrastLight(),
      PenumbraAppearance.system when platform == Brightness.dark => PenumbraThemes.dark(),
      _ => light,
    };

    return MaterialApp.router(
      title: 'Penumbra',
      debugShowCheckedModeBanner: false,
      theme: light.toApproximateMaterialTheme(),
      darkTheme: PenumbraThemes.dark().toApproximateMaterialTheme(),
      themeMode: switch (appearance) {
        PenumbraAppearance.light => ThemeMode.light,
        PenumbraAppearance.dark => ThemeMode.dark,
        PenumbraAppearance.highContrast => ThemeMode.light,
        PenumbraAppearance.system => ThemeMode.system,
      },
      localizationsDelegates: FLocalizations.localizationsDelegates,
      supportedLocales: FLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return FToaster(
          child: FTheme(
            data: active,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
