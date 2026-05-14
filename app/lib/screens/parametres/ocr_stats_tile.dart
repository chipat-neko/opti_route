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
    final countAsync = ref.watch(ocrStatsCountProvider);
    final count = countAsync.asData?.value ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bar_chart_outlined),
      title: const Text('Stats OCR'),
      subtitle: Text(
        count == 0
            ? 'Aucun scan enregistre - les stats remontent automatiquement '
                'a chaque scan de bordereau'
            : '$count scan${count > 1 ? "s" : ""} enregistre${count > 1 ? "s" : ""} - '
                'export CSV ou reset',
        style: const TextStyle(fontSize: 12),
      ),
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
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Stats OCR effacees')),
    );
  }
}
