import 'package:material_ui/material_ui.dart';

/// Palette taken from the game itself.
///
/// Light theme is a day match: sightscreen white, club green, red ball.
/// Dark theme is a day-night match: floodlit dark and the pink ball.
abstract final class AppColors {
  static const Color clubGreen = Color(0xFF0E4D3A);
  static const Color sightscreen = Color(0xFFF5F8F6);
  static const Color redBall = Color(0xFFB5121B);
  static const Color pinkBall = Color(0xFFF2578C);
  static const Color pitchStraw = Color(0xFFD8C690);
  static const Color ink = Color(0xFF14211B);
  static const Color floodlit = Color(0xFF0D1613);
}

abstract final class AppTheme {
  /// Condensed face used for headlines and scoreboard-style numerals.
  static const String displayFont = 'BarlowCondensed';

  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.clubGreen,
          primary: AppColors.clubGreen,
          tertiary: AppColors.redBall,
          surface: AppColors.sightscreen,
          onSurface: AppColors.ink,
        ),
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.clubGreen,
          brightness: Brightness.dark,
          tertiary: AppColors.pinkBall,
          surface: AppColors.floodlit,
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme);
    final text = base.textTheme;

    TextStyle? display(TextStyle? style) => style?.copyWith(
          fontFamily: displayFont,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        displaySmall: display(text.displaySmall),
        headlineLarge: display(text.headlineLarge),
        headlineMedium: display(text.headlineMedium),
        headlineSmall: display(text.headlineSmall),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Scoreboard-style number.
  static TextStyle numeral(ThemeData theme, double size, {Color? color}) {
    return TextStyle(
      fontFamily: displayFont,
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1,
      color: color ?? theme.colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Decoration shared by every text field.
  static InputDecoration field(
    String label, {
    Widget? suffixIcon,
    String? helper,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
