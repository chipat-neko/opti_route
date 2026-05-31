import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import '../../data/fec_export.dart';
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
            onPressed: () => _exportFec(context, ref, tournees),
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

  /// MVP export FEC : genere 1 entree par tournee terminee
  /// (vente services 706 + contrepartie banque 512), ecrit dans un
  /// fichier `.csv` avec BOM UTF-8 (Excel FR lit les accents), partage
  /// via share_plus.
  ///
  /// Sortie audit chef PC (#338) : avant, ce bouton ouvrait un
  /// AlertDialog "a wire dans une future PR". Maintenant produit un
  /// vrai fichier importable Sage/Pennylane/expert-comptable.
  Future<void> _exportFec(
    BuildContext context,
    WidgetRef ref,
    List<Tournee> tournees,
  ) async {
    final stopsRepo = ref.read(stopsRepositoryProvider);
    final entries = <FecEntry>[];
    var num = 1;
    for (final t in tournees.where((t) => t.statut == 'terminee')) {
      final stops = await stopsRepo.getByTournee(t.id);
      final codTotal = stops
          .where((s) => s.codPaye && s.montantCod != null)
          .fold<double>(0, (sum, s) => sum + s.montantCod!);
      if (codTotal <= 0) continue;
      final date = t.demareeLe ?? t.creeLe;
      // Ecriture debit 512 (banque) / credit 706 (services) -- double
      // ecriture equilibree. NB : compte 706 = prestations de services.
      entries.add(FecEntry(
        journalCode: 'VE',
        journalLib: 'Ventes',
        ecritureNum: 'T${t.id}',
        ecritureDate: date,
        compteNum: '512000',
        compteLib: 'Banque',
        pieceRef: 'TOURNEE-${t.id}',
        pieceDate: date,
        libelle: 'COD tournee ${t.nom}',
        debit: codTotal,
      ));
      entries.add(FecEntry(
        journalCode: 'VE',
        journalLib: 'Ventes',
        ecritureNum: 'T${t.id}',
        ecritureDate: date,
        compteNum: '706000',
        compteLib: 'Prestations services',
        pieceRef: 'TOURNEE-${t.id}',
        pieceDate: date,
        libelle: 'COD tournee ${t.nom}',
        credit: codTotal,
      ));
      num++;
    }

    if (entries.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucun COD encaisse a exporter dans le FEC.')),
      );
      return;
    }

    // BOM UTF-8 (﻿) pour qu'Excel FR lise correctement les accents
    final csv = '﻿${FecExport.toCsv(entries)}';
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final filename =
        'fec_${now.year}${now.month.toString().padLeft(2, '0')}.csv';
    final file = File('${tempDir.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(csv);

    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'FEC opti_route',
        text:
            'Export FEC ($num ecritures, ${entries.length} lignes). '
            'Importable Sage / Pennylane / expert-comptable.',
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
