import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Type semantique d'un SnackBar -> couleur de fond coherente.
/// Centralise les couleurs qui etaient repetees a la main sur 170+
/// sites (audit #224). [info] = couleur par defaut du theme.
enum SnackKind { info, success, warning, error }

Color? _backgroundFor(SnackKind kind, Color? override) {
  if (override != null) return override;
  return switch (kind) {
    SnackKind.info => null, // couleur par defaut du theme
    SnackKind.success => AppColors.emerald,
    SnackKind.warning => AppColors.amber,
    SnackKind.error => AppColors.red,
  };
}

SnackBar _buildSnack(
  String message,
  SnackKind kind,
  Color? color,
  Duration? duration,
  SnackBarAction? action,
) {
  return SnackBar(
    content: Text(message),
    backgroundColor: _backgroundFor(kind, color),
    // 4 s = duree par defaut de Flutter -> migrer un site sans duree
    // explicite ne change pas son comportement.
    duration: duration ?? const Duration(seconds: 4),
    action: action,
  );
}

/// Helper centralise pour afficher un SnackBar (audit #224).
///
/// Extension sur [ScaffoldMessengerState] : c'est le pattern dominant du
/// projet (`final messenger = ScaffoldMessenger.of(context)` capture
/// AVANT un await, puis `messenger.showSnackBar(...)` apres) -- preserve
/// la securite "BuildContext across async gaps". Pour les sites
/// synchrones, voir l'extension [SnackContext] sur BuildContext.
///
/// **Comportement preserve** : couleur mappee sur la variante existante,
/// duree par defaut 4 s (= Flutter), [duration]/[action] passes tels
/// quels. Migrer un site est donc un refactor 1:1, sans changement de
/// rendu.
extension SnackMessenger on ScaffoldMessengerState {
  void showSnack(
    String message, {
    SnackKind kind = SnackKind.info,
    Color? color,
    Duration? duration,
    SnackBarAction? action,
  }) =>
      showSnackBar(_buildSnack(message, kind, color, duration, action));

  void showSuccess(String message,
          {Duration? duration, SnackBarAction? action}) =>
      showSnack(message,
          kind: SnackKind.success, duration: duration, action: action);

  void showError(String message,
          {Duration? duration, SnackBarAction? action}) =>
      showSnack(message,
          kind: SnackKind.error, duration: duration, action: action);

  void showWarning(String message,
          {Duration? duration, SnackBarAction? action}) =>
      showSnack(message,
          kind: SnackKind.warning, duration: duration, action: action);

  void showInfo(String message,
          {Duration? duration, SnackBarAction? action}) =>
      showSnack(message,
          kind: SnackKind.info, duration: duration, action: action);
}

/// Variante BuildContext pour les sites SYNCHRONES (pas d'await entre le
/// `context` et l'affichage). Pour un appel apres un await, capturer
/// `ScaffoldMessenger.of(context)` avant et utiliser [SnackMessenger].
extension SnackContext on BuildContext {
  void showSnack(
    String message, {
    SnackKind kind = SnackKind.info,
    Color? color,
    Duration? duration,
    SnackBarAction? action,
  }) =>
      ScaffoldMessenger.of(this).showSnack(message,
          kind: kind, color: color, duration: duration, action: action);

  void showSuccess(String message,
          {Duration? duration, SnackBarAction? action}) =>
      ScaffoldMessenger.of(this)
          .showSuccess(message, duration: duration, action: action);

  void showError(String message,
          {Duration? duration, SnackBarAction? action}) =>
      ScaffoldMessenger.of(this)
          .showError(message, duration: duration, action: action);

  void showWarning(String message,
          {Duration? duration, SnackBarAction? action}) =>
      ScaffoldMessenger.of(this)
          .showWarning(message, duration: duration, action: action);

  void showInfo(String message,
          {Duration? duration, SnackBarAction? action}) =>
      ScaffoldMessenger.of(this)
          .showInfo(message, duration: duration, action: action);
}
