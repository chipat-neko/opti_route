import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Construit le `ThemeData` global de l'application en se basant sur les
/// tokens du handoff (`app_tokens.dart`).
///
/// - **Police UI** : Manrope (Google Fonts) — 400/500/600/700/800.
/// - **Police chiffres / mono** : JetBrains Mono — exposée via [appMonoStyle].
/// - **Couleurs** : palette cream/ink/lime/emerald de la spec.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );

  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.paper,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    tertiary: AppColors.emerald,
    onTertiary: AppColors.paper,
    error: AppColors.red,
    onError: AppColors.paper,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    surfaceContainerLowest: AppColors.paper,
    surfaceContainerLow: AppColors.cream,
    surfaceContainer: AppColors.creamSoft,
    surfaceContainerHigh: AppColors.creamSoft,
    surfaceContainerHighest: AppColors.creamSoft,
    onSurfaceVariant: AppColors.textMute,
    outline: AppColors.inkLine,
    outlineVariant: AppColors.divider,
    shadow: AppColors.ink,
  );

  final manropeText = GoogleFonts.manropeTextTheme(base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
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
      color: AppColors.textMute,
    ),
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.paper,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r18)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: const BorderSide(color: AppColors.inkLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: const BorderSide(color: AppColors.inkLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      labelStyle: const TextStyle(color: AppColors.textMute),
      hintStyle: const TextStyle(color: AppColors.textFaint),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.lime,
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
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 1.5),
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
        foregroundColor: AppColors.ink,
        textStyle: textTheme.labelLarge,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.lime,
      elevation: 6,
      extendedTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: AppColors.paper,
      iconColor: AppColors.ink,
      textColor: AppColors.ink,
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.creamSoft,
      labelStyle: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: StadiumBorder(),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r22)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: AppColors.paper),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
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
