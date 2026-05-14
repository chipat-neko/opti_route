import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Carte "Pourquoi tes echecs" — Top 5 raisons sur 30 jours.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche un mini classement des raisons d'echec les plus
/// frequentes sur les 30 derniers jours, sous forme de barres
/// proportionnelles a la raison majoritaire (qui sera donc a 100%).
///
/// Cachee si aucun echec sur la periode (pas la peine d'afficher
/// une card vide quand tout va bien).
///
/// Suivi d'un petit conseil pratique pour faire baisser certains
/// types d'echecs (absent -> pre-appeler, adresse fausse -> verifier
/// dans le carnet, etc.).
class TopRaisonsEchecCard extends ConsumerWidget {
  const TopRaisonsEchecCard({super.key});

  static const _days = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(topRaisonsEchecProvider(_days));
    final list = async.asData?.value ?? const [];
    // Aucun echec sur la periode -> on cache la card.
    if (list.isEmpty) return const SizedBox.shrink();

    // La 1ere raison (la plus frequente) sert de reference 100% pour
    // calibrer la longueur des barres.
    final max = list.first.n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_outlined,
                  color: AppColors.red, size: 18),
              const SizedBox(width: AppSpacing.x8),
              Text(
                'POURQUOI TES ECHECS - 30 DERNIERS JOURS',
                style: appMonoStyle(
                  fontSize: 10.5,
                  color: p.textMute,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          for (final entry in list)
            _RaisonBar(
              raison: _humanRaison(entry.raison),
              n: entry.n,
              max: max,
            ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Tu peux limiter les "absent" en pre-appelant les clients '
            'la veille. Pour "adresse fausse", verifie le GPS dans le '
            'carnet d\'abord.',
            style: TextStyle(
              fontSize: 11.5,
              color: p.textMute,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Traduction des codes raison vers du francais lisible.
  static String _humanRaison(String r) {
    return switch (r) {
      'absent' => 'Client absent',
      'refuse' => 'Refuse',
      'adresse_fausse' => 'Adresse fausse',
      'autre' => 'Autre',
      _ => r,
    };
  }
}

/// Une ligne de barre proportionnelle : label a gauche (largeur 110),
/// LinearProgressIndicator rouge au milieu, compteur en mono red a droite.
class _RaisonBar extends StatelessWidget {
  const _RaisonBar({
    required this.raison,
    required this.n,
    required this.max,
  });

  final String raison;
  final int n;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = max == 0 ? 0.0 : n / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              raison,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: p.creamSoft,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.red),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          SizedBox(
            width: 32,
            child: Text(
              '$n',
              textAlign: TextAlign.right,
              style: appMonoStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
