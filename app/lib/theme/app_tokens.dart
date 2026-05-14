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

  // ─── Palette OCEAN (bleus apaisants) ──────────────────────────────
  /// Ocean clair : surfaces bleu pale, texte bleu marine.
  static const oceanLight = AppPalette(
    cream: Color(0xFFEEF4F7),
    creamSoft: Color(0xFFDDE9EE),
    paper: Color(0xFFFAFCFD),
    ink: Color(0xFF0E2A3A),
    inkSoft: Color(0xFF1A3849),
    inkLine: Color(0xFFC4D8E5),
    divider: Color(0x140E2A3A),
    text: Color(0xFF0E2A3A),
    textMute: Color(0xFF5C7080),
    textFaint: Color(0xFF8AA0B0),
  );

  /// Ocean sombre : marine profond avec accents bleu pale.
  static const oceanDark = AppPalette(
    cream: Color(0xFF0E2A3A),
    creamSoft: Color(0xFF1A3849),
    paper: Color(0xFF1A3849),
    ink: Color(0xFFEEF4F7),
    inkSoft: Color(0xFFDDE9EE),
    inkLine: Color(0x33EEF4F7),
    divider: Color(0x1AEEF4F7),
    text: Color(0xFFEEF4F7),
    textMute: Color(0xB3EEF4F7),
    textFaint: Color(0x80EEF4F7),
  );

  // ─── Palette TERRACOTTA (chauds, terre cuite) ─────────────────────
  /// Terracotta clair : surfaces sable, texte chocolat.
  static const terracottaLight = AppPalette(
    cream: Color(0xFFF6EDDF),
    creamSoft: Color(0xFFEBDFCC),
    paper: Color(0xFFFFFAF1),
    ink: Color(0xFF2D1B0E),
    inkSoft: Color(0xFF3D2818),
    inkLine: Color(0xFFE0D0B8),
    divider: Color(0x142D1B0E),
    text: Color(0xFF2D1B0E),
    textMute: Color(0xFF6E5240),
    textFaint: Color(0xFF9A8268),
  );

  /// Terracotta sombre : brun chocolat profond, textes beige.
  static const terracottaDark = AppPalette(
    cream: Color(0xFF1F1410),
    creamSoft: Color(0xFF2D2014),
    paper: Color(0xFF2D2014),
    ink: Color(0xFFF6EDDF),
    inkSoft: Color(0xFFEBDFCC),
    inkLine: Color(0x33F6EDDF),
    divider: Color(0x1AF6EDDF),
    text: Color(0xFFF6EDDF),
    textMute: Color(0xB3F6EDDF),
    textFaint: Color(0x80F6EDDF),
  );

  // ─── Palette MONO (epuree, noir et blanc) ─────────────────────────
  /// Mono clair : blanc pur, noir profond. Maximum de contraste.
  static const monoLight = AppPalette(
    cream: Color(0xFFFAFAFA),
    creamSoft: Color(0xFFF0F0F0),
    paper: Color(0xFFFFFFFF),
    ink: Color(0xFF111111),
    inkSoft: Color(0xFF1F1F1F),
    inkLine: Color(0xFFE0E0E0),
    divider: Color(0x14111111),
    text: Color(0xFF111111),
    textMute: Color(0xFF555555),
    textFaint: Color(0xFF8A8A8A),
  );

  /// Mono sombre : noir pur, blanc casse. Style OLED.
  static const monoDark = AppPalette(
    cream: Color(0xFF0A0A0A),
    creamSoft: Color(0xFF1A1A1A),
    paper: Color(0xFF1A1A1A),
    ink: Color(0xFFFAFAFA),
    inkSoft: Color(0xFFF0F0F0),
    inkLine: Color(0x33FAFAFA),
    divider: Color(0x1AFAFAFA),
    text: Color(0xFFFAFAFA),
    textMute: Color(0xB3FAFAFA),
    textFaint: Color(0x80FAFAFA),
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

/// Un theme complet (clair + sombre) avec une couleur d'accent
/// principale. Permet a l'utilisateur de choisir entre plusieurs
/// ambiances dans Parametres.
///
/// Les couleurs de signalisation (lime=succes, rouge=echec, amber=warning,
/// emerald=action) restent identiques sur tous les presets pour preserver
/// la coherence des indicateurs metier. Seules les **surfaces** (cream/
/// ink/paper/...) et la **couleur d'accent primaire** changent.
class AppThemePreset {
  const AppThemePreset({
    required this.name,
    required this.displayName,
    required this.description,
    required this.light,
    required this.dark,
    required this.previewColor,
  });

  /// Identifiant stocke en base (`theme_preset` dans parametres).
  final String name;

  /// Nom affiche dans le selecteur UI ("Lime (defaut)", "Ocean", etc.).
  final String displayName;

  /// Texte explicatif court affiche sous le nom dans le selecteur.
  final String description;

  final AppPalette light;
  final AppPalette dark;

  /// Couleur dominante du preset (utilisee comme aperçu rond dans le
  /// selecteur). Generalement la couleur la plus visible/iconique.
  final Color previewColor;

  static const lime = AppThemePreset(
    name: 'lime',
    displayName: 'Lime',
    description: 'Vert lime sur cream — defaut',
    light: AppPalette.light,
    dark: AppPalette.dark,
    previewColor: AppColors.lime,
  );

  static const ocean = AppThemePreset(
    name: 'ocean',
    displayName: 'Ocean',
    description: 'Bleus apaisants — conduite zen',
    light: AppPalette.oceanLight,
    dark: AppPalette.oceanDark,
    previewColor: Color(0xFF2196F3),
  );

  static const terracotta = AppThemePreset(
    name: 'terracotta',
    displayName: 'Terracotta',
    description: 'Tons chauds — fin de journee',
    light: AppPalette.terracottaLight,
    dark: AppPalette.terracottaDark,
    previewColor: Color(0xFFE67E22),
  );

  static const mono = AppThemePreset(
    name: 'mono',
    displayName: 'Mono',
    description: 'Noir et blanc — maximum lisibilite',
    light: AppPalette.monoLight,
    dark: AppPalette.monoDark,
    previewColor: Color(0xFF111111),
  );

  /// Liste de tous les presets dans l'ordre d'affichage dans Parametres.
  static const all = <AppThemePreset>[lime, ocean, terracotta, mono];

  /// Retourne le preset correspondant a `name`, fallback sur lime si
  /// le nom est inconnu (cas d'une valeur orpheline en base apres
  /// retrait d'un theme).
  static AppThemePreset fromName(String? name) {
    return all.firstWhere(
      (p) => p.name == name,
      orElse: () => lime,
    );
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
