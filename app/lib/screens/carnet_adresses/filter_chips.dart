import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Chips de filtrage de la liste du carnet.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `carnet_adresses_screen.dart` (704 lignes initiales) :
/// - [ColorFilterChip] : chip de filtre par couleur d'etiquette
///                       (ink/lime/amber/emerald + "Tous")
/// - [TagFilterChip]   : chip de filtre par tag libre (style
///                       monochrome pour se distinguer des couleurs)
///
/// Pattern visuel commun : InkWell + Container colore + Text. Mais les
/// 2 widgets divergent sur le code couleur (accent fond vs ink fond)
/// donc 2 widgets distincts plutot qu'un parametre booleen.

/// Chip de filtre par couleur d'etiquette. Quand non selectionne :
/// fond creamSoft, texte ink. Quand selectionne : fond = la couleur
/// d'etiquette (ou ink si "Tous"), texte ink ou paper selon contraste.
class ColorFilterChip extends StatelessWidget {
  const ColorFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = selected ? (color ?? p.ink) : p.creamSoft;
    // Texte : noir sur fond clair / accent, blanc sur fond ink quand
    // selectionne sans couleur (cas "Tous").
    final fg = selected
        ? (color == null ? p.paper : AppColors.ink)
        : p.ink;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r22),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r22),
          border: Border.all(
            color: selected ? Colors.transparent : p.inkLine,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Chip de filtre par tag libre. Style monochrome (pas de couleur
/// d'accent) pour distinguer visuellement des filtres couleur.
class TagFilterChip extends StatelessWidget {
  const TagFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r22),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected ? p.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.r22),
          border: Border.all(
            color: selected ? Colors.transparent : p.inkLine,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? p.paper : p.ink,
          ),
        ),
      ),
    );
  }
}
