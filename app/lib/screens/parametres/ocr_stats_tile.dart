import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ocr_stats_log.dart';
import '../../theme/app_tokens.dart';

/// Provider du nombre d'entrees actuellement dans `<docs>/ocr_stats.csv`.
/// FutureProvider plutot que StreamProvider car les writes du log sont
/// best-effort cote service et ne notifient pas. On invalide
/// manuellement apres un export/reset depuis l'UI.
final ocrStatsCountProvider = FutureProvider<int>((ref) {
  return OcrStatsLog.instance.count();
});

/// Provider du breakdown carte verte/orange/rouge calcule par parse
/// CSV. Memoise par Riverpod (re-eval seulement sur invalidate).
final ocrBaselineProvider = FutureProvider<OcrBaselineStats>((ref) {
  return OcrStatsLog.instance.computeBaseline();
});

/// ════════════════════════════════════════════════════════════════
/// Tile "Stats OCR" de la section Donnees des Parametres.
/// ════════════════════════════════════════════════════════════════
///
/// Permet a Noah d'exporter en CSV les stats accumulees (timestamp,
/// parser utilise, confidence, rotation, validation BAN, duree) pour
/// analyser la baseline avant de demarrer la Phase B OCR (cf
/// `project-ocr-85pct-target` en memoire).
///
/// 3 sous-actions :
/// - **Exporter CSV** : share natif du fichier (Drive / mail).
/// - **Reset**        : supprime le fichier (recommence a zero).
/// - Compteur live "N scans enregistres" pour donner du feedback.
class OcrStatsTile extends ConsumerWidget {
  const OcrStatsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baselineAsync = ref.watch(ocrBaselineProvider);
    final stats = baselineAsync.asData?.value ?? const OcrBaselineStats.empty();
    final count = stats.total;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bar_chart_outlined),
      title: const Text('Stats OCR'),
      subtitle: count == 0
          ? const Text(
              'Aucun scan enregistre - les stats remontent automatiquement '
              'a chaque scan de bordereau',
              style: TextStyle(fontSize: 12),
            )
          : _BaselineSubtitle(stats: stats),
      trailing: count == 0
          ? null
          : PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                if (v == 'export') {
                  await _onExport(context);
                } else if (v == 'reset') {
                  await _onReset(context, ref);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.ios_share),
                    title: Text('Exporter en CSV'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppColors.red),
                    title: Text('Reset (effacer toutes les stats)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _onExport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final shared = await OcrStatsLog.instance.exportShare();
      if (!context.mounted) return;
      if (!shared) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Aucune stat a exporter')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur export : $e')),
      );
    }
  }

  Future<void> _onReset(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset les stats OCR ?'),
        content: const Text(
          'Toutes les stats accumulees seront effacees definitivement. '
          'Le compteur repart de zero au prochain scan. Cette action est '
          'irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await OcrStatsLog.instance.clear();
    ref.invalidate(ocrStatsCountProvider);
    ref.invalidate(ocrBaselineProvider);
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Stats OCR effacees')),
    );
  }
}

/// Subtitle inline du tile OCR Stats quand au moins 1 scan est
/// enregistre : montre les 3 taux carte verte/orange/rouge en gros
/// pourcentages + total. Le but est que Noah voie d'un coup d'oeil
/// son taux carte verte sans devoir exporter le CSV.
///
/// Objectif baseline : >= 85% (cf memory `project-ocr-85pct-target`).
/// Couleur du taux carte verte : emerald si >= 85%, amber si entre
/// 60-85%, red si < 60% (signal visuel pour decider si Phase B-2
/// vaut le coup ou si on est deja OK).
class _BaselineSubtitle extends StatelessWidget {
  const _BaselineSubtitle({required this.stats});
  final OcrBaselineStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final greenPct = (stats.greenRate * 100).toStringAsFixed(0);
    final orangePct = (stats.orangeRate * 100).toStringAsFixed(0);
    final redPct = (stats.redRate * 100).toStringAsFixed(0);
    final greenColor = stats.greenRate >= 0.85
        ? AppColors.emerald
        : stats.greenRate >= 0.60
            ? AppColors.amber
            : AppColors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Text(
            '${stats.total} scan${stats.total > 1 ? "s" : ""} - export CSV ou reset',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Row(
          children: [
            _Pct(label: 'verte', pct: greenPct, color: greenColor),
            const SizedBox(width: 10),
            _Pct(label: 'orange', pct: orangePct, color: AppColors.amber),
            const SizedBox(width: 10),
            _Pct(label: 'rouge', pct: redPct, color: AppColors.red),
          ],
        ),
        if (stats.greenRate < 0.85)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Objectif : 85% carte verte. Exporte le CSV pour analyser '
              'les echecs.',
              style: TextStyle(fontSize: 11, color: p.textMute),
            ),
          ),
      ],
    );
  }
}

class _Pct extends StatelessWidget {
  const _Pct({required this.label, required this.pct, required this.color});
  final String label;
  final String pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$pct% $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
