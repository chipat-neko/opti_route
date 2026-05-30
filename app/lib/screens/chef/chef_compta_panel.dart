import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/kilometric_log.dart';
import '../../data/weekly_report.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Panneau "Compta" du logiciel chef. Agrège les modules compta :
/// - Cumul km URSSAF (#291) -> montant déductible bareme 5CV
/// - Total COD encaissé (#296)
/// - Rapport hebdo donneur d'ordre (#321)
/// - FEC export (#320) -> bouton (export PDF/CSV à wire ensuite)
class ChefComptaPanel extends ConsumerWidget {
  const ChefComptaPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tourneesAsync = ref.watch(tourneesStreamProvider);
    final tournees = tourneesAsync.asData?.value ?? const <Tournee>[];
    final totalMeters = tournees.fold<int>(
      0,
      (sum, t) => sum + (t.distanceTotaleM ?? 0),
    );
    final totalKm = totalMeters / 1000;
    final urssafAmount = KilometricLog.computeAnnual5cv2024(totalKm);

    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.euro, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Text('Compta',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.ink)),
            ],
          ),
          const Divider(height: AppSpacing.x22),
          _SectionTile(
            icon: Icons.straighten,
            label: 'Km cumulés',
            value: '${totalKm.toStringAsFixed(0)} km',
          ),
          _SectionTile(
            icon: Icons.account_balance_outlined,
            label: 'URSSAF déductible (5 CV 2024)',
            value: '${urssafAmount.toStringAsFixed(0)} €',
          ),
          const SizedBox(height: AppSpacing.x12),
          _ActionButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Rapport hebdo donneur d\'ordre',
            onPressed: () => _previewWeeklyReport(context, ref, tournees),
          ),
          const SizedBox(height: AppSpacing.x6),
          _ActionButton(
            icon: Icons.file_download_outlined,
            label: 'Export FEC (CSV)',
            onPressed: () => _showFecPlaceholder(context),
          ),
        ],
      ),
    );
  }

  Future<void> _previewWeeklyReport(
    BuildContext context,
    WidgetRef ref,
    List<Tournee> tournees,
  ) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDay =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final stopsRepo = ref.read(stopsRepositoryProvider);
    final allStops = <Stop>[];
    for (final t in tournees) {
      allStops.addAll(await stopsRepo.getByTournee(t.id));
    }
    if (!context.mounted) return;
    final body =
        WeeklyReport.compose(weekStart: weekStartDay, tournees: tournees, allStops: allStops);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rapport hebdo'),
        content: SingleChildScrollView(
          child: SelectableText(body,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showFecPlaceholder(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export FEC'),
        content: const Text(
            'Le FEC est généré depuis FecExport.toCsv. UI export fichier '
            'à wire dans une future PR (share_plus + write file)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: p.textMute),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: p.textMute))),
          Text(value,
              style: appMonoStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44)),
    );
  }
}
