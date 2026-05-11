import 'package:flutter/material.dart';

/// Primitives de design issues directement du handoff
/// `docs/design/handoff/design_handoff_optiroute/tokens.jsx`.
///
/// On expose des constantes primitives ici. Le `ThemeData` Material
/// vit dans `app_theme.dart` et s'appuie sur ces valeurs.

abstract final class AppColors {
  // Surfaces
  static const cream = Color(0xFFF5F3EE);
  static const creamSoft = Color(0xFFEFEAE0);
  static const paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0E1410);
  static const inkSoft = Color(0xFF1A211C);
  static const inkLine = Color(0xFFE3DED1);
  static const divider = Color(0x140E1410); // rgba(14,20,16,0.08)

  // Brand
  static const emerald = Color(0xFF0E7C5A);
  static const emeraldDark = Color(0xFF0A5C43);
  static const emeraldSoft = Color(0xFFD5EBE0);
  static const lime = Color(0xFFB8F24A);
  static const limeDark = Color(0xFF86C72A);
  static const amber = Color(0xFFF2A341);
  static const red = Color(0xFFD9483B);

  // Map placeholder (utile plus tard)
  static const mapLand = Color(0xFFEAE6DD);
  static const mapLandAlt = Color(0xFFE0DAC9);
  static const mapWater = Color(0xFFC4D8E5);
  static const mapPark = Color(0xFFD6E2C7);
  static const mapRoad = Color(0xFFFFFFFF);
  static const mapHwy = Color(0xFFF8DCA0);
  static const mapStroke = Color(0xFFD4CCB8);

  // Text
  static const text = Color(0xFF0E1410);
  static const textMute = Color(0xFF5C6660);
  static const textFaint = Color(0xFF8A9089);
}

/// Echelle d'espacement du handoff : 4 / 6 / 8 / 10 / 12 / 14 / 16 / 18 / 22 / 28 px.
abstract final class AppSpacing {
  static const x4 = 4.0;
  static const x6 = 6.0;
  static const x8 = 8.0;
  static const x10 = 10.0;
  static const x12 = 12.0;
  static const x14 = 14.0;
  static const x16 = 16.0;
  static const x18 = 18.0;
  static const x22 = 22.0;
  static const x28 = 28.0;
}

/// Echelle de radius du handoff : 6 / 8 / 10 / 12 / 14 / 16 / 18 / 22 / 26 / 28.
/// Pour les pills, utiliser `height / 2` directement.
abstract final class AppRadius {
  static const r6 = 6.0;
  static const r8 = 8.0;
  static const r10 = 10.0;
  static const r12 = 12.0;
  static const r14 = 14.0;
  static const r16 = 16.0;
  static const r18 = 18.0;
  static const r22 = 22.0;
  static const r26 = 26.0;
  static const r28 = 28.0;
}

/// Mapping nom de tag -> Color de la palette. Sert pour la couleur
/// custom d'un client dans le carnet (`SavedDestination.colorTag`).
/// Tag null ou inconnu -> retourne `defaultColor`.
Color colorFromTag(String? tag, {required Color defaultColor}) {
  return switch (tag) {
    'lime' => AppColors.lime,
    'emerald' => AppColors.emerald,
    'red' => AppColors.red,
    'amber' => AppColors.amber,
    'cream' => AppColors.creamSoft,
    'ink' => AppColors.ink,
    _ => defaultColor,
  };
}

/// Liste des tags de couleur exposes dans le picker UI.
const colorTagOptions = <(String, Color)>[
  ('lime', AppColors.lime),
  ('emerald', AppColors.emerald),
  ('amber', AppColors.amber),
  ('red', AppColors.red),
  ('cream', AppColors.creamSoft),
  ('ink', AppColors.ink),
];

/// Palette context-aware qui bascule selon le ThemeMode (clair / sombre).
/// Sert aux widgets custom qui veulent supporter le mode sombre sans
/// passer par le `colorScheme` Material standard.
///
/// Usage :
/// ```dart
/// final p = Theme.of(context).extension<AppPalette>()!;
/// Container(color: p.cream, ...)
/// ```
///
/// Les couleurs de **marque** (lime, emerald, red, amber) restent
/// inchangees dans `AppColors` car elles doivent rester identiques
/// dans les 2 modes (signaux visuels universels : vert = succes,
/// rouge = echec, etc.).
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.cream,
    required this.creamSoft,
    required this.paper,
    required this.ink,
    required this.inkSoft,
    required this.inkLine,
    required this.divider,
    required this.text,
    required this.textMute,
    required this.textFaint,
  });

  final Color cream;
  final Color creamSoft;
  final Color paper;
  final Color ink;
  final Color inkSoft;
  final Color inkLine;
  final Color divider;
  final Color text;
  final Color textMute;
  final Color textFaint;

  /// Mode clair : meme palette que les anciennes constantes `AppColors`.
  static const light = AppPalette(
    cream: AppColors.cream,
    creamSoft: AppColors.creamSoft,
    paper: AppColors.paper,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    inkLine: AppColors.inkLine,
    divider: AppColors.divider,
    text: AppColors.text,
    textMute: AppColors.textMute,
    textFaint: AppColors.textFaint,
  );

  /// Mode sombre : inversion des roles. La surface principale devient
  /// l'ancien `ink` (#0E1410), les surfaces "blanc paper" deviennent
  /// `inkSoft` (#1A211C), et le texte passe en `cream` clair.
  static const dark = AppPalette(
    cream: AppColors.ink,
    creamSoft: AppColors.inkSoft,
    paper: AppColors.inkSoft,
    ink: AppColors.cream,
    inkSoft: AppColors.creamSoft,
    inkLine: Color(0x33F5F3EE), // cream 20%
    divider: Color(0x1AF5F3EE), // cream 10%
    text: AppColors.cream,
    textMute: Color(0xB3F5F3EE), // cream 70%
    textFaint: Color(0x80F5F3EE), // cream 50%
  );

  @override
  AppPalette copyWith({
    Color? cream,
    Color? creamSoft,
    Color? paper,
    Color? ink,
    Color? inkSoft,
    Color? inkLine,
    Color? divider,
    Color? text,
    Color? textMute,
    Color? textFaint,
  }) {
    return AppPalette(
      cream: cream ?? this.cream,
      creamSoft: creamSoft ?? this.creamSoft,
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkLine: inkLine ?? this.inkLine,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      textMute: textMute ?? this.textMute,
      textFaint: textFaint ?? this.textFaint,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      cream: Color.lerp(cream, other.cream, t)!,
      creamSoft: Color.lerp(creamSoft, other.creamSoft, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkLine: Color.lerp(inkLine, other.inkLine, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMute: Color.lerp(textMute, other.textMute, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
    );
  }
}

/// Helper ergonomique pour acceder a la palette depuis n'importe quel
/// `BuildContext` : `context.palette.cream`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette {
    return Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
  }
}

abstract final class AppShadows {
  /// Cartes "paper" (radius 16-22).
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x140E1410), // rgba(14,20,16,0.08)
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  /// Boutons flottants (FAB).
  static const fab = <BoxShadow>[
    BoxShadow(
      color: Color(0x240E1410), // rgba(14,20,16,0.14)
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  /// Bottom sheets : ombre vers le HAUT.
  static const sheet = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A0E1410), // rgba(14,20,16,0.10)
      blurRadius: 40,
      offset: Offset(0, -10),
    ),
  ];
}
