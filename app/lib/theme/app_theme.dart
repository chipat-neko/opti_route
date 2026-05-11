import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Construit le `ThemeData` global de l'application en se basant sur les
/// tokens du handoff (`app_tokens.dart`).
///
/// - **Police UI** : Manrope (Google Fonts) — 400/500/600/700/800.
/// - **Police chiffres / mono** : JetBrains Mono — exposée via [appMonoStyle].
/// - **Couleurs** : palette cream/ink/lime/emerald de la spec.
ThemeData buildAppTheme() => _buildTheme(brightness: Brightness.light);

/// Variante sombre du thème pour la conduite de nuit (#73).
///
/// Inverse les surfaces (background ink, paper -> inkSoft) tout en
/// conservant les couleurs de marque (lime / emerald / red / amber)
/// qui restent lisibles sur fond sombre.
///
/// **Limite connue** : certains widgets custom utilisent encore les
/// constantes `AppColors.*` en dur (cream/paper/ink) et ne basculent
/// pas. Ils gardent leur apparence claire. Refactor complet à faire
/// dans une PR future si ce n'est pas assez sombre la nuit.
ThemeData buildAppThemeDark() => _buildTheme(brightness: Brightness.dark);

ThemeData _buildTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  // Palette dynamique selon le mode.
  final bg = isDark ? AppColors.ink : AppColors.cream;
  final bgSoft = isDark ? AppColors.inkSoft : AppColors.creamSoft;
  final surface = isDark ? AppColors.inkSoft : AppColors.paper;
  final onSurface = isDark ? AppColors.cream : AppColors.ink;
  final onSurfaceMute = isDark
      ? AppColors.cream.withValues(alpha: 0.65)
      : AppColors.textMute;
  final outline = isDark
      ? AppColors.cream.withValues(alpha: 0.15)
      : AppColors.inkLine;
  final divider = isDark
      ? AppColors.cream.withValues(alpha: 0.08)
      : AppColors.divider;
  final primaryFg = isDark ? AppColors.lime : AppColors.lime;
  final primaryBg = isDark ? AppColors.cream : AppColors.ink;

  final base = ThemeData(useMaterial3: true, brightness: brightness);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primaryBg,
    onPrimary: primaryFg,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    tertiary: AppColors.emerald,
    onTertiary: AppColors.paper,
    error: AppColors.red,
    onError: AppColors.paper,
    surface: bg,
    onSurface: onSurface,
    surfaceContainerLowest: surface,
    surfaceContainerLow: bg,
    surfaceContainer: bgSoft,
    surfaceContainerHigh: bgSoft,
    surfaceContainerHighest: bgSoft,
    onSurfaceVariant: onSurfaceMute,
    outline: outline,
    outlineVariant: divider,
    shadow: AppColors.ink,
  );

  final manropeText = GoogleFonts.manropeTextTheme(base.textTheme).apply(
    bodyColor: onSurface,
    displayColor: onSurface,
  );

  final textTheme = manropeText.copyWith(
    displayLarge: manropeText.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
    displayMedium: manropeText.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
    headlineLarge: manropeText.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineMedium: manropeText.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineSmall: manropeText.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleLarge: manropeText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: manropeText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    titleSmall: manropeText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: manropeText.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    bodyMedium: manropeText.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    labelLarge: manropeText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelSmall: manropeText.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: onSurfaceMute,
    ),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[
      isDark ? AppPalette.dark : AppPalette.light,
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r18)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: divider,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: BorderSide(color: onSurface, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      labelStyle: TextStyle(color: onSurfaceMute),
      hintStyle: TextStyle(color: onSurfaceMute.withValues(alpha: 0.7)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryBg,
        foregroundColor: primaryFg,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x22,
          vertical: AppSpacing.x14,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.r14)),
        ),
        minimumSize: const Size(0, 52),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: BorderSide(color: onSurface, width: 1.5),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x22,
          vertical: AppSpacing.x14,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.r14)),
        ),
        minimumSize: const Size(0, 52),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: onSurface,
        textStyle: textTheme.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryBg,
      foregroundColor: primaryFg,
      elevation: 6,
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: surface,
      iconColor: onSurface,
      textColor: onSurface,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: bgSoft,
      labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r22)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? AppColors.cream : AppColors.ink,
      contentTextStyle: TextStyle(
        color: isDark ? AppColors.ink : AppColors.paper,
      ),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r14)),
      ),
    ),
  );
}

/// Style mono (JetBrains Mono) à utiliser pour tous les chiffres,
/// codes, ETA et metrics. À combiner avec `Theme.of(context).textTheme`
/// pour la taille.
TextStyle appMonoStyle({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double? letterSpacing,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.ink,
    letterSpacing: letterSpacing,
  );
}
