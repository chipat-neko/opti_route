import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../facturation_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Carte "Exporter en CSV"
/// ════════════════════════════════════════════════════════════════
///
/// Genere un fichier CSV des 365 derniers jours de tournees et
/// declenche le share natif Android (Drive, mail, Whatsapp, etc.).
/// Le fichier est ecrit dans le repertoire temp avec un timestamp
/// pour eviter les collisions.
///
/// Format compatible Excel / Google Sheets (separateur virgule,
/// encoding UTF-8 BOM ajoute par stats_service).
class ExportCsvCard extends ConsumerWidget {
  const ExportCsvCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
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
            'EXPORTER LES STATS',
            style: appMonoStyle(
              fontSize: 11,
              color: p.textMute,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'CSV des 365 derniers jours (compatible Excel / Google Sheets).',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          FilledButton.icon(
            onPressed: () => _exportAndShare(context, ref),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Exporter en CSV'),
          ),
        ],
      ),
    );
  }

  /// Genere le CSV via `StatsService.exportCsvTournees`, l'ecrit dans
  /// le dossier temp, puis declenche le share natif Android. En cas
  /// d'erreur (espace disque, share annule), affiche un snackbar.
  Future<void> _exportAndShare(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final since = DateTime.now().subtract(const Duration(days: 365));
      final csv =
          await ref.read(statsServiceProvider).exportCsvTournees(since: since);
      final dir = await getTemporaryDirectory();
      // Timestamp ISO sans secondes ni ms pour un nom de fichier
      // lisible et compatible (les `:` sont remplaces par `-`).
      final ts = DateTime.now().toIso8601String().split('.').first
          .replaceAll(':', '-');
      final file = File('${dir.path}/stats-opti-route-$ts.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Stats opti_route',
          text: 'Export des tournees opti_route (365 derniers jours).',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur export : ${humanizeAnyError(e)}')),
      );
    }
  }
}

/// ════════════════════════════════════════════════════════════════
/// Carte "Facturation mensuelle" (CTA emerald)
/// ════════════════════════════════════════════════════════════════
///
/// Card cliquable qui ouvre l'ecran [FacturationScreen]. Visuel
/// emerald distinctif (gradient sombre) pour la distinguer de la
/// card motivation lime au-dessus.
class FacturationCard extends ConsumerWidget {
  const FacturationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald, AppColors.emeraldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FacturationScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.ink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FACTURATION MENSUELLE',
                        style: appMonoStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Calculer ton recap facturable',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: p.cream,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EUR par arret / colis / km + marge brute',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.cream.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: p.cream),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
