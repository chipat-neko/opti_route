import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Overlays UI de la carte (positionnes au-dessus du FlutterMap).
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `carte_screen.dart` :
/// - [EmptyOverlay]   : message "Aucun arret avec coords" en bas
/// - [InfoChip]       : chip compact icon + label (km / duree)
/// - [MapFilterChip]  : chip de filtre statut (livre/echec/a livrer)

/// Overlay affiche en bas de la carte quand aucun stop n'a de
/// coordonnees a afficher. Card sur fond paper, signale l'etat vide
/// sans cacher la carte (le fond OSM reste visible).
class EmptyOverlay extends StatelessWidget {
  const EmptyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Positioned(
      left: AppSpacing.x16,
      right: AppSpacing.x16,
      bottom: AppSpacing.x18,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: p.textMute),
            SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                'Aucun arret avec coordonnees a afficher.',
                style: TextStyle(fontSize: 13, color: p.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip compact icone + label, fond creamSoft, utilise dans la barre
/// d'info de la tournee (distance, duree). Option `mono` pour utiliser
/// la police monospace (chiffres alignes).
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x10,
        vertical: AppSpacing.x6,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: p.ink),
          const SizedBox(width: AppSpacing.x6),
          Text(
            label,
            style: mono
                ? appMonoStyle(fontSize: 12, fontWeight: FontWeight.w700)
                : TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Chip de filtre statut sur la carte. Tap = toggle. Le fond utilise
/// la couleur du statut (lime/emerald/red), avec un cran d'opacite
/// quand le filtre est desactive (visuel "cache").
class MapFilterChip extends StatelessWidget {
  const MapFilterChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected ? color : p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r22),
          border: Border.all(
            color: selected ? Colors.transparent : color.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!selected)
              Icon(Icons.visibility_off_outlined, size: 14, color: color)
            else
              const Icon(Icons.check, size: 14, color: AppColors.ink),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.ink : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
