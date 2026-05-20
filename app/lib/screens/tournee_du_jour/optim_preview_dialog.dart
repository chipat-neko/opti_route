import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/geo_utils.dart';
import '../../theme/app_tokens.dart';

/// Dialog "preview optim" qui montre la distance AVANT (ordre actuel)
/// vs APRES (nouvel ordre propose), avant d'appliquer.
///
/// Inspire de Spoke route planner : tu vois le gain potentiel et tu
/// decides si tu acceptes. Evite les "j'ai optim et c'est pire" qui
/// peuvent arriver avec VROOM quand il optimise la boucle complete
/// au lieu du chemin simple.
///
/// Retourne `true` si l'utilisateur tap 'Appliquer', `false` ou null
/// sinon (annulation).
class OptimPreviewDialog {
  OptimPreviewDialog._();

  /// Affiche le dialog comparatif. Calcule la distance totale
  /// haversine AVANT et APRES sur les memes stops (juste l'ordre
  /// change).
  static Future<bool?> show({
    required BuildContext context,
    required Tournee tournee,
    required List<Stop> stops,
    required List<int> proposedOrder,
    required String title,
  }) {
    final distBefore = _totalHaversine(
      depotLat: tournee.pointDepartLat,
      depotLng: tournee.pointDepartLng,
      stops: stops,
    );
    // Recree la liste reorganisee dans le meme ordre.
    final byId = {for (final s in stops) s.id: s};
    final reordered = [
      for (final id in proposedOrder)
        if (byId[id] != null) byId[id]!,
    ];
    final distAfter = _totalHaversine(
      depotLat: tournee.pointDepartLat,
      depotLng: tournee.pointDepartLng,
      stops: reordered,
    );
    final delta = distBefore - distAfter;
    final pctGain = distBefore == 0
        ? 0
        : (delta / distBefore * 100);
    final improved = delta > 100; // au moins 100 m de gain

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DistanceLine(
              label: 'Avant (ordre actuel)',
              meters: distBefore,
              color: AppColors.textMute,
            ),
            const SizedBox(height: AppSpacing.x6),
            _DistanceLine(
              label: 'Apres (nouveau tri)',
              meters: distAfter,
              color: improved ? AppColors.emerald : AppColors.amber,
            ),
            const SizedBox(height: AppSpacing.x10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x10,
                vertical: AppSpacing.x8,
              ),
              decoration: BoxDecoration(
                color: (improved ? AppColors.emerald : AppColors.amber)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: Row(
                children: [
                  Icon(
                    improved
                        ? Icons.trending_down
                        : Icons.trending_flat,
                    color: improved ? AppColors.emerald : AppColors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      improved
                          ? 'Economie ${_kmLabel(delta)} '
                              '(${pctGain.toStringAsFixed(0)} %) '
                              'en vol d\'oiseau'
                          : 'Pas d\'amelioration notable. L\'ordre '
                              'actuel est deja proche du meilleur.',
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            const Text(
              'Calcul base sur distance vol d\'oiseau. '
              'La distance reelle (routes) peut differer.',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: AppColors.textMute,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: improved ? AppColors.emerald : null,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  /// Somme haversine du parcours depot -> stop1 -> stop2 -> ... -> stopN.
  /// Skip les stops sans coords (un trou geocodage ne fausse pas le
  /// total, on continue depuis le dernier stop avec coords).
  static double _totalHaversine({
    required double depotLat,
    required double depotLng,
    required List<Stop> stops,
  }) {
    var total = 0.0;
    var prevLat = depotLat;
    var prevLng = depotLng;
    for (final s in stops) {
      if (s.lat == null || s.lng == null) continue;
      total += GeoUtils.haversineMeters(
        lat1: prevLat,
        lon1: prevLng,
        lat2: s.lat!,
        lon2: s.lng!,
      );
      prevLat = s.lat!;
      prevLng = s.lng!;
    }
    return total;
  }

  static String _kmLabel(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _DistanceLine extends StatelessWidget {
  const _DistanceLine({
    required this.label,
    required this.meters,
    required this.color,
  });

  final String label;
  final double meters;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          OptimPreviewDialog._kmLabel(meters),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
