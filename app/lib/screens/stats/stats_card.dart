import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stats_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Card "Stats sur une fenetre" (7j / 30j / 365j).
/// ════════════════════════════════════════════════════════════════
///
/// Affiche pour une fenetre temporelle donnee :
///   - le nombre de colis livres en gros chiffre
///   - tournees terminees / totales
///   - arrets livres / echecs
///   - distance totale (km)
///   - duree totale
///   - taux de reussite (%)
///   - cout carburant estime cumule (si distance > 0)
///
/// Le watcher Riverpod sur `statsProvider(days)` recalcule
/// automatiquement quand une tournee est ajoutee/modifiee.
class StatsCard extends ConsumerWidget {
  const StatsCard({
    super.key,
    required this.label,
    required this.days,
  });

  /// Label en majuscule affiche au-dessus (ex: "7 DERNIERS JOURS").
  final String label;

  /// Fenetre temporelle en jours (7, 30, 365).
  final int days;

  /// Format FR pour les montants en EUR : virgule decimale, suffixe " EUR".
  static String formatEur(double v) {
    final cents = (v * 100).round();
    return '${cents ~/ 100},${(cents % 100).toString().padLeft(2, "0")} EUR';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    // Utilise le bundle aggregée (1 paire de queries Drift partagée
    // entre les 3 cards 7/30/365 jours) au lieu de statsProvider(days)
    // qui refait 2 queries par card.
    final async = ref.watch(statsFromBundleProvider(days));
    // Carte Trello #99 : fenetre precedente de meme duree pour
    // afficher les deltas (+12%, -5%, ...) sous chaque metric.
    // Si bundle pas encore charge ou aucune tournee S-1 : null = pas
    // d'affichage de delta (pas de regression visuelle).
    final prevAsync = ref.watch(statsPreviousWindowProvider(days));
    final coutAsync = ref.watch(coutCarburantCumuleProvider(days));
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
            label,
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          async.when(
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatsBody(
                  stats: stats,
                  // null si bundle pas pret OU si aucune tournee dans
                  // la fenetre precedente -> _StatsBody n'affiche pas
                  // de delta (pas de regression visuelle).
                  previousStats: prevAsync.asData?.value,
                ),
                // Ligne "Cout carburant estime" en bas de la card si la
                // distance > 0 ET si le calcul async est dispo.
                if (stats.distanceMeters > 0 &&
                    coutAsync.asData != null) ...[
                  const SizedBox(height: AppSpacing.x8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_gas_station_outlined,
                              size: 14, color: p.textMute),
                          const SizedBox(width: 4),
                          Text(
                            'Cout carburant estime',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textMute,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatEur(coutAsync.asData!.value),
                        style: appMonoStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.x18),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Corps de la card : big number "colis livres" + 4 small stats
/// (tournees, arrets, distance, duree, reussite). Vide si 0 tournee.
///
/// [previousStats] : stats de la fenetre precedente de meme duree.
/// Si non-null et non-vides, on affiche le delta (+12%, -5%) sous
/// chaque metric (carte Trello #99).
class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats, this.previousStats});

  final TourneeStats stats;
  final TourneeStats? previousStats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (stats.nbTournees == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x10),
        child: Text(
          'Aucune tournee dans cette periode.',
          style: TextStyle(color: p.textMute),
        ),
      );
    }
    final km = (stats.distanceMeters / 1000).toStringAsFixed(1);
    final dur = _formatDuration(stats.durationSeconds);
    final tauxPct = (stats.tauxReussite * 100).toStringAsFixed(0);
    // Si on a une fenetre precedente non vide, on calcule les deltas
    // pour chaque metric. Sinon, on passe null partout -> les chips
    // ne s'affichent pas (pas de regression visuelle).
    final prev = (previousStats != null && previousStats!.nbTournees > 0)
        ? previousStats
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BigNumber(
          value: '${stats.nbColisLivres}',
          label: 'colis livres',
          accent: AppColors.emerald,
          // Delta colis livres : higher = better.
          change: prev == null
              ? null
              : _ChangeChip.from(
                  current: stats.nbColisLivres,
                  previous: prev.nbColisLivres,
                  higherIsBetter: true,
                ),
        ),
        const SizedBox(height: AppSpacing.x12),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                label: 'Tournees',
                value: '${stats.nbTourneesTerminees}/${stats.nbTournees}',
                hint: stats.nbTourneesTerminees == stats.nbTournees
                    ? 'toutes terminees'
                    : '${stats.nbTournees - stats.nbTourneesTerminees} en cours / brouillon',
                change: prev == null
                    ? null
                    : _ChangeChip.from(
                        current: stats.nbTournees,
                        previous: prev.nbTournees,
                        higherIsBetter: true,
                      ),
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _SmallStat(
                label: 'Arrets',
                value: '${stats.nbArrets}',
                // Split livraisons / ramasses pour aller plus vite dans
                // la lecture metier. Si pas de ramasse sur la fenetre,
                // on garde l'ancien format compact pour ne pas charger.
                hint: stats.nbRamasses == 0
                    ? '${stats.nbLivraisons} livres · ${stats.nbEchecs} echecs'
                    : '${stats.nbLivraisons} livres · '
                        '${stats.nbRamasses} ramasses · '
                        '${stats.nbEchecs} echecs',
                change: prev == null
                    ? null
                    : _ChangeChip.from(
                        current: stats.nbArrets,
                        previous: prev.nbArrets,
                        higherIsBetter: true,
                      ),
              ),
            ),
          ],
        ),
        const Divider(height: AppSpacing.x18),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                label: 'Distance',
                value: km,
                unit: 'km',
                change: prev == null
                    ? null
                    : _ChangeChip.from(
                        current: stats.distanceMeters,
                        previous: prev.distanceMeters,
                        higherIsBetter: true,
                      ),
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _SmallStat(
                label: 'Duree',
                value: dur,
                change: prev == null
                    ? null
                    : _ChangeChip.from(
                        current: stats.durationSeconds,
                        previous: prev.durationSeconds,
                        higherIsBetter: true,
                      ),
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _SmallStat(
                label: 'Reussite',
                value: '$tauxPct%',
                hint:
                    '${stats.nbLivres} sur ${stats.nbLivres + stats.nbEchecs}',
                change: prev == null
                    ? null
                    // Taux de reussite : higher = better. On compare
                    // en points (pas en %) pour eviter le piege
                    // "passer de 98% a 99% = +1% relatif mais +1 pt".
                    : _ChangeChip.fromPoints(
                        current: stats.tauxReussite * 100,
                        previous: prev.tauxReussite * 100,
                        higherIsBetter: true,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Format compact d'une duree en secondes : "12min" / "1h35".
  /// Retourne " - " si 0 (aucune duree enregistree).
  static String _formatDuration(int totalSeconds) {
    if (totalSeconds == 0) return ' - ';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

/// Big number sur fond lime : la mise en valeur du chiffre principal.
/// Layout en row : valeur ENORME a gauche, label discret a droite,
/// chip de delta optionnel a l'extreme droite (carte #99).
class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.label,
    required this.accent,
    this.change,
  });

  final String value;
  final String label;
  // ignore: unused_field
  final Color accent;
  final Widget? change;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: appMonoStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
          ),
          if (change != null) ...[
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: change,
            ),
          ],
        ],
      ),
    );
  }
}

/// Petite stat : label en haut, valeur (avec unite optionnelle), hint
/// optionnel en bas, chip de delta optionnel a droite du label
/// (carte #99). Utilise pour les sous-stats dans la grille 2x3.
class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
    this.unit,
    this.hint,
    this.change,
  });

  final String label;
  final String value;
  final String? unit;
  final String? hint;
  final Widget? change;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: appMonoStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: p.textMute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: appMonoStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.ink,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMute,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 10,
                color: p.textMute,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (change != null) ...[
            const SizedBox(height: 4),
            change!,
          ],
        ],
      ),
    );
  }
}

/// Trait vertical fin servant de separateur entre 2 _SmallStat.
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: context.palette.divider);
}

/// Petit chip de variation vs fenetre precedente (carte Trello #99).
/// Format : `+12%` (emerald si higherIsBetter=true et delta > 0,
/// red si delta < 0). Affiche `=` neutre si delta == 0 +/- 1 %.
/// Retourne `SizedBox.shrink()` si previous == 0 (calcul impossible).
class _ChangeChip extends StatelessWidget {
  const _ChangeChip._({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  /// Construit un chip pour un ratio (`(curr - prev) / prev * 100`).
  /// Retourne `null` si `previous == 0` (division impossible).
  /// Le caller fait `change: prev == null ? null : _ChangeChip.from(...)`.
  static _ChangeChip? from({
    required num current,
    required num previous,
    required bool higherIsBetter,
  }) {
    if (previous == 0) {
      // Pas de comparaison possible : on retourne null pour cacher
      // l'affichage plutot que de mentir avec "+inf%".
      return null;
    }
    final pct = ((current - previous) / previous) * 100;
    return _build(pct.round(), higherIsBetter, isPoints: false);
  }

  /// Variante en points absolus (ex : taux de reussite 96 % -> 98 %
  /// = +2 pt, pas +2 %). Pour les metrics deja exprimes en pourcent.
  static _ChangeChip? fromPoints({
    required num current,
    required num previous,
    required bool higherIsBetter,
  }) {
    final diff = (current - previous).round();
    // Pas de seuil "neutre" sur les points : 0 pt = vraiment stable.
    return _build(diff, higherIsBetter, isPoints: true);
  }

  static _ChangeChip _build(int value, bool higherIsBetter,
      {required bool isPoints}) {
    // Bande neutre +/- 1 sur les pourcentages (le bruit n'est pas
    // significatif). Sur les points, 0 est strictement stable.
    final neutralBand = isPoints ? 0 : 1;
    final String sign;
    final Color color;
    final Color bg;
    if (value.abs() <= neutralBand) {
      sign = isPoints && value == 0 ? '=' : '~';
      color = const Color(0xFF6B7280); // slate-500
      bg = const Color(0x1F6B7280);
    } else {
      final positive = value > 0;
      // Higher is better : positif = vert, negatif = rouge.
      // Lower is better (inverse) : positif = rouge, negatif = vert.
      final good = higherIsBetter ? positive : !positive;
      color = good ? AppColors.emerald : AppColors.red;
      bg = good
          ? const Color(0x1F10B981) // emerald light
          : const Color(0x1FDC2626); // red light
      sign = positive ? '+$value' : '$value';
    }
    final suffix = isPoints ? ' pt' : ' %';
    return _ChangeChip._(
      label: sign == '=' || sign == '~' ? sign : '$sign$suffix',
      color: color,
      background: bg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: appMonoStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
