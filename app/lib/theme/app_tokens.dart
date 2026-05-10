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
