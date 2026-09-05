import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

enum PenumbraAppearance { system, light, dark, highContrast }

extension PenumbraAppearanceLabels on PenumbraAppearance {
  String get spokenName => switch (this) {
    PenumbraAppearance.system => 'System',
    PenumbraAppearance.light => 'Light',
    PenumbraAppearance.dark => 'Dark',
    PenumbraAppearance.highContrast => 'High contrast',
  };

  PenumbraAppearance get next {
    const values = PenumbraAppearance.values;
    return values[(index + 1) % values.length];
  }
}

PenumbraAppearance appearanceFromName(String? name) {
  for (final value in PenumbraAppearance.values) {
    if (value.name == name) return value;
  }
  return PenumbraAppearance.system;
}

abstract final class PenumbraInk {
  static const paper = Color(0xFFF4EFE6);
  static const ink = Color(0xFF1C1712);
  static const mute = Color(0xFF534C44);
  static const copper = Color(0xFFC45C26);
  static const darkPaper = Color(0xFF16130F);
  static const cream = Color(0xFFF4EFE6);
  static const displayFamily = 'Fraunces';
}

abstract final class PenumbraThemes {
  static FThemeData light() => _paper(
    debugLabel: 'Penumbra Light',
    colors: FColors.zincLight.copyWith(
      background: PenumbraInk.paper,
      foreground: PenumbraInk.ink,
      primary: PenumbraInk.copper,
      primaryForeground: PenumbraInk.paper,
      secondary: const Color(0xFFEBE4D8),
      secondaryForeground: PenumbraInk.ink,
      muted: const Color(0xFFEBE4D8),
      mutedForeground: PenumbraInk.mute,
      card: const Color(0xFFF8F4EC),
      border: const Color(0xFFDDD4C6),
    ),
  );

  static FThemeData dark() => _paper(
    debugLabel: 'Penumbra Dark',
    colors: FColors.zincDark.copyWith(
      background: PenumbraInk.darkPaper,
      foreground: PenumbraInk.cream,
      primary: PenumbraInk.copper,
      primaryForeground: PenumbraInk.cream,
      secondary: const Color(0xFF1F1A15),
      secondaryForeground: PenumbraInk.cream,
      muted: const Color(0xFF1F1A15),
      mutedForeground: const Color(0xFFB7AFA4),
      card: const Color(0xFF1C1712),
      border: const Color(0xFF2F2922),
    ),
  );

  static FThemeData highContrastLight() => _paper(
    debugLabel: 'High contrast light',
    colors: FColors.neutralLight.copyWith(
      background: const Color(0xFFFFFFFF),
      foreground: const Color(0xFF000000),
      primary: const Color(0xFF000000),
      primaryForeground: const Color(0xFFFFFFFF),
      secondary: const Color(0xFFFFFFFF),
      secondaryForeground: const Color(0xFF000000),
      muted: const Color(0xFFFFFFFF),
      mutedForeground: const Color(0xFF000000),
      card: const Color(0xFFFFFFFF),
      border: const Color(0xFF000000),
    ),
  );

  static FThemeData highContrastDark() => _paper(
    debugLabel: 'High contrast dark',
    colors: FColors.neutralDark.copyWith(
      background: const Color(0xFF000000),
      foreground: const Color(0xFFFFFFFF),
      primary: const Color(0xFFFFFFFF),
      primaryForeground: const Color(0xFF000000),
      secondary: const Color(0xFF000000),
      secondaryForeground: const Color(0xFFFFFFFF),
      muted: const Color(0xFF000000),
      mutedForeground: const Color(0xFFFFFFFF),
      card: const Color(0xFF000000),
      border: const Color(0xFFFFFFFF),
    ),
  );

  static FThemeData _paper({
    required String debugLabel,
    required FColors colors,
  }) {
    final typography = FTypography.inherit(colors: colors, touch: false);
    return FThemeData(
      touch: false,
      debugLabel: debugLabel,
      colors: colors,
      typography: typography.copyWith(
        xl3: typography.xl3.copyWith(
          fontFamily: PenumbraInk.displayFamily,
          fontWeight: FontWeight.w500,
          height: 1.15,
        ),
        xl4: typography.xl4.copyWith(
          fontFamily: PenumbraInk.displayFamily,
          fontWeight: FontWeight.w500,
          height: 1.1,
        ),
        xl5: typography.xl5.copyWith(
          fontFamily: PenumbraInk.displayFamily,
          fontWeight: FontWeight.w500,
          height: 1.05,
        ),
      ),
    );
  }

  static (FThemeData light, FThemeData dark) pair(
    PenumbraAppearance appearance,
    Brightness platform,
  ) {
    return switch (appearance) {
      PenumbraAppearance.light => (light(), light()),
      PenumbraAppearance.dark => (dark(), dark()),
      PenumbraAppearance.highContrast => (
        highContrastLight(),
        highContrastDark(),
      ),
      PenumbraAppearance.system =>
        platform == Brightness.dark ? (dark(), dark()) : (light(), light()),
    };
  }
}
