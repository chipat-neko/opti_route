import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/carnet_export_service.dart';
import '../../data/carnet_vcard_export_service.dart';
import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Handlers du menu "Exporter" du carnet d'adresses.
/// ════════════════════════════════════════════════════════════════
///
/// Extraits de `carnet_adresses_screen.dart` (refactor F27) : etaient
/// les methodes `_onExportPressed` / `_onExportVcardPressed`. Les deux
/// delegent tout le travail au service correspondant et ne gardent
/// que le SnackBar de resultat.
class CarnetExportActions {
  CarnetExportActions._();

  /// Export CSV du carnet complet, partage via le share sheet systeme.
  static Future<void> exportCsv({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = CarnetExportService(
        ref.read(savedDestinationsRepositoryProvider),
      );
      final count = await service.exportAndShare();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? '$count entree(s) exportee(s) en CSV'
              : 'Carnet vide, rien a exporter'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Export vCard (.vcf) du carnet complet : import direct dans
  /// l'app Contacts du telephone.
  static Future<void> exportVcard({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = CarnetVcardExportService(
        ref.read(savedDestinationsRepositoryProvider),
      );
      final count = await service.exportAndShare();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? '$count fiche(s) vCard generee(s)'
              : 'Carnet vide, rien a exporter'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content:
                Text('Erreur a l\'export vCard : ${humanizeAnyError(e)}')),
      );
    }
  }
}
