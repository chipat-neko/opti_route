import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/recap_depot.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Bandeau "Recap depot" - carte #275.
/// ════════════════════════════════════════════════════════════════
///
/// S'affiche dans la tournee du jour quand le statut est 'terminee'
/// ET qu'il y a au moins un colis a rapporter au depot :
/// - echecs (livraisons ratees -> colis encore dans le camion)
/// - ramasses recuperees (colis collectes a deposer au depot)
///
/// Evite le retour au depot pour un colis oublie. Affiche les details
/// (adresse, nom client, raison echec, nb colis, photo si dispo) pour
/// que Noah puisse cocher mentalement au dechargement.
///
/// Pas de persistance "marque decharge" pour le MVP : juste un affichage
/// informatif. Une iteration v2 pourra ajouter une colonne en base + des
/// checkboxes.
class RecapDepotCard extends StatelessWidget {
  const RecapDepotCard({super.key, required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    final r = RecapDepot.compute(stops);
    if (!r.aQuelqueChose) return const SizedBox.shrink();
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.move_to_inbox, color: AppColors.amber, size: 20),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  'A rapporter au depot : ${r.totalColis} colis',
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (r.echecsARendre.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Echecs (${r.echecsARendre.length})',
              style: TextStyle(
                color: p.textMute,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            for (final s in r.echecsARendre)
              _RecapRow(stop: s, isEchec: true),
          ],
          if (r.ramassesRecuperees.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Ramasses (${r.ramassesRecuperees.length})',
              style: TextStyle(
                color: p.textMute,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            for (final s in r.ramassesRecuperees)
              _RecapRow(stop: s, isEchec: false),
          ],
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({required this.stop, required this.isEchec});

  final Stop stop;
  final bool isEchec;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasPhoto = (stop.preuvePhotoPath ?? '').isNotEmpty;
    final raison = (stop.raisonEchec ?? '').trim();
    final title = (stop.nomClient ?? '').trim().isEmpty
        ? stop.adresseBrute
        : stop.nomClient!;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isEchec ? Icons.cancel_outlined : Icons.inventory_2_outlined,
            size: 14,
            color: isEchec ? AppColors.red : AppColors.emerald,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: p.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    '${stop.nbColis} colis',
                    if (isEchec && raison.isNotEmpty) raison,
                    if (hasPhoto) 'photo',
                  ].join(' · '),
                  style: appMonoStyle(
                    fontSize: 10.5,
                    color: p.textMute,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
