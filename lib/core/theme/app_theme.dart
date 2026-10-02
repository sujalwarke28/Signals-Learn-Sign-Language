import 'package:flutter/material.dart';

/// All of Signals' colour comes from one seed run through Material 3's tonal
/// palette generator, so light and dark stay in harmony and nothing gets
/// eye-searingly saturated.
class AppPalette {
  const AppPalette._();

  /// Friendly violet. Playful without being loud.
  static const seed = Color(0xFF6C5CE7);

  /// Semantic accents for the gamified bits (streaks, badges, scores). These
  /// are picked to sit calmly on both the light and dark surfaces.
  static const streak = Color(0xFFF2994A);
  static const streakDark = Color(0xFFFFB86C);
  static const success = Color(0xFF2E9E6B);
  static const successDark = Color(0xFF6FD3A3);
  static const wrong = Color(0xFFD15C5C);
  static const wrongDark = Color(0xFFF08B8B);

  /// Per-category tints used on lesson cards and the progress breakdown.
  static const categoryTints = <String, Color>{
    'Alphabet': Color(0xFF6C5CE7),
    'Numbers': Color(0xFF2EC4B6),
    'Common Phrases': Color(0xFFF2994A),
    'Greetings': Color(0xFF4DA3FF),
    'Family': Color(0xFFE07A9B),
    'Colors': Color(0xFF8BC34A),
  };

  /// The same six hues re-stepped for a dark surface.
  ///
  /// Not an automatic flip: on a dark background the light-mode steps sit at
  /// OKLCH L 0.70–0.76, above the 0.48–0.67 band where categorical colour stays
  /// separable, so each hue is re-stepped to L 0.645 with chroma scaled to
  /// match. Checked with the palette validator — lightness band, chroma floor,
  /// CVD separation, normal-vision separation and contrast all pass in both
  /// modes. Alphabet's violet was already in band and is unchanged.
  static const categoryTintsDark = <String, Color>{
    'Alphabet': Color(0xFF6C5CE7),
    'Numbers': Color(0xFF24A296),
    'Common Phrases': Color(0xFFC37A3A),
    'Greetings': Color(0xFF4390E3),
    'Family': Color(0xFFC86C8A),
    'Colors': Color(0xFF709E3A),
  };

  static Color categoryTint(String category, ColorScheme scheme) {
    final tints = scheme.brightness == Brightness.dark
        ? categoryTintsDark
        : categoryTints;
    return tints[category] ?? scheme.primary;
  }
}

/// Extra colours the widgets reach for that aren't part of [ColorScheme].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.streak,
    required this.success,
    required this.wrong,
    required this.cardShadow,
  });

  final Color streak;
  final Color success;
  final Color wrong;
  final Color cardShadow;

  @override
  AppColors copyWith({
    Color? streak,
    Color? success,
    Color? wrong,
    Color? cardShadow,
  }) {
    return AppColors(
      streak: streak ?? this.streak,
      success: success ?? this.success,
      wrong: wrong ?? this.wrong,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      streak: Color.lerp(streak, other.streak, t)!,
      success: Color.lerp(success, other.success, t)!,
      wrong: Color.lerp(wrong, other.wrong, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;
}

class AppTheme {
  const AppTheme._();

  // Outfit: geometric, low-contrast, and tight enough at display sizes to
  // read as modern rather than cheerful. Nunito keeps the body warm so the
  // app doesn't tip over into cold.
  static const _display = 'Outfit';
  static const _body = 'Nunito';

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seed,
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: _body,
      scaffoldBackgroundColor: isLight
          // A hair warmer than pure white so long reading sessions are kinder.
          ? Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.025),
              Colors.white,
            )
          : scheme.surface,
    );

    final text = base.textTheme
        .apply(fontFamily: _body)
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontFamily: _display,
            letterSpacing: -1.4,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontFamily: _display,
            letterSpacing: -1.2,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: _display,
            letterSpacing: -1.0,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: _display,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        );

    return base.copyWith(
      textTheme: text,
      extensions: [
        AppColors(
          streak: isLight ? AppPalette.streak : AppPalette.streakDark,
          success: isLight ? AppPalette.success : AppPalette.successDark,
          wrong: isLight ? AppPalette.wrong : AppPalette.wrongDark,
          cardShadow: isLight
              ? AppPalette.seed.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.45),
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      // NB: `Size.fromHeight(h)` is `Size(double.infinity, h)` — an infinite
      // *minimum width*. Buttons themed that way explode with "BoxConstraints
      // forces an infinite width" anywhere width is unbounded, e.g. as a
      // non-flex child of a Row. Pin the height only; full-width comes from the
      // parent (a stretching Column still stretches them).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide.none,
        labelStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary.withValues(alpha: isLight ? 0.16 : 0.28),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 10,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),
      // Android and web both get Material 3's forwards-fade transition, which
      // suits the app's soft motion better than the platform default slide.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
