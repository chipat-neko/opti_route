import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/stats_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Carte "Mon equipe - 30 derniers jours"
/// ════════════════════════════════════════════════════════════════
///
/// Affiche un mini tableau par coequipier : avatar (couleur custom),
/// nom, "X livres / Y echecs - Z colis", taux de reussite. Noah est
/// toujours en premier (cle null dans la map).
///
/// Cachee si aucun coequipier n'a ete affecte sur la periode (chez
/// un livreur solo, on ne pollue pas l'UI avec une seule ligne "Moi").
class CoequipiersStatsCard extends ConsumerWidget {
  const CoequipiersStatsCard({super.key});

  static const _days = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final statsAsync = ref.watch(statsParCoequipierProvider(_days));
    final coequipiers = ref.watch(coequipiersAllProvider).asData?.value ??
        const <Coequipier>[];
    final stats = statsAsync.asData?.value ?? const <int?, CoequipierStats>{};

    // Si aucune affectation : on cache la card pour eviter le bruit.
    final hasAssignments = stats.keys.any((k) => k != null);
    if (!hasAssignments) return const SizedBox.shrink();

    // Index id -> Coequipier pour resolution rapide.
    final byId = {for (final c in coequipiers) c.id: c};
    // Tri : Noah (cle null) en haut, puis coequipiers par colis livres
    // descendant pour mettre en avant ceux qui produisent le plus.
    final entries = stats.entries.toList()
      ..sort((a, b) {
        if (a.key == null) return -1;
        if (b.key == null) return 1;
        return b.value.colisLivres.compareTo(a.value.colisLivres);
      });

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
          Text(
            'MON EQUIPE - 30 DERNIERS JOURS',
            style: appMonoStyle(
              fontSize: 11,
              color: p.textMute,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          for (final entry in entries)
            _CoequipierRow(
              coequipier: entry.key == null ? null : byId[entry.key],
              isNoah: entry.key == null,
              stats: entry.value,
            ),
        ],
      ),
    );
  }
}

/// Une ligne du tableau : avatar (couleur custom + initiales), nom,
/// "X livres / Y echecs - Z colis", badge taux de reussite color
/// selon seuil (emerald >=90 %, amber >=70 %, red sinon).
class _CoequipierRow extends StatelessWidget {
  const _CoequipierRow({
    required this.coequipier,
    required this.isNoah,
    required this.stats,
  });

  /// Null si c'est Noah (pas de coequipier en base) OU si le coequipier
  /// a ete supprime du carnet (cas rare : on affiche "Coequipier
  /// supprime #N" pour preserver l'historique).
  final Coequipier? coequipier;
  final bool isNoah;
  final CoequipierStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final nom = isNoah
        ? 'Moi'
        : (coequipier?.nom ?? 'Coequipier supprime #${stats.coequipierId}');
    final color = isNoah
        ? AppColors.lime
        : colorFromTag(coequipier?.colorTag, defaultColor: AppColors.creamSoft);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.ink.withValues(alpha: 0.15),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(nom),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.nbLivres} livres / '
                  '${stats.nbEchecs} echec${stats.nbEchecs > 1 ? "s" : ""} - '
                  '${stats.colisLivres} colis',
                  style: TextStyle(fontSize: 11, color: p.textMute),
                ),
              ],
            ),
          ),
          Text(
            '${(stats.tauxReussite * 100).round()}%',
            style: appMonoStyle(
              fontSize: 13,
              color: stats.tauxReussite >= 0.9
                  ? AppColors.emerald
                  : stats.tauxReussite >= 0.7
                      ? AppColors.amber
                      : AppColors.red,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Extrait les initiales (max 2 lettres en majuscule) du nom pour
  /// l'avatar. "Lucas" -> "L", "Lucas Dupont" -> "LD".
  static String _initials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
