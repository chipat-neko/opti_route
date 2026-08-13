import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/carnet_backfill_service.dart';
import '../../data/carnet_import_service.dart';
import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../providers/geocoding_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Handlers du menu "Importer / peupler" du carnet d'adresses.
/// ════════════════════════════════════════════════════════════════
///
/// Extraits de `carnet_adresses_screen.dart` (refactor F27) : etaient
/// les methodes `_onImportPressed` / `_onImportGeocodePressed` /
/// `_onImportVcardPressed` / `_onBackfillPressed`, ~280 lignes de
/// file picker + dialog de confirmation + SnackBar de resume qui
/// noyaient le `build` de l'ecran.
///
/// Meme squelette pour les 3 imports fichier : pick -> confirmation ->
/// service -> resume "N ajoutee(s) · N fusionnee(s) · N rejetee(s)".
class CarnetImportActions {
  CarnetImportActions._();

  /// Import CSV complet : le fichier contient deja lat/lng (typiquement
  /// un export precedent de l'app). Aucun geocodage.
  static Future<void> importCsv({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fichier illisible')),
      );
      return;
    }
    if (!context.mounted) return;
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importer ce CSV ?'),
        content: Text(
          'Les entrees du fichier vont s\'ajouter a ton carnet existant. '
          'Les doublons (meme nom client ou meme position GPS) seront '
          'fusionnes, pas dupliques.\n\n${picked.files.first.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (shouldImport != true || !context.mounted) return;

    try {
      final service = CarnetImportService(
        ref.read(savedDestinationsRepositoryProvider),
      );
      final result = await service.importFromFile(File(path));
      if (!context.mounted) return;
      final summary = [
        if (result.created > 0) '${result.created} ajoutee(s)',
        if (result.merged > 0) '${result.merged} fusionnee(s)',
        if (result.rejected > 0) '${result.rejected} rejetee(s)',
      ].join(' · ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary.isEmpty ? 'Aucune entree' : summary),
          backgroundColor:
              result.rejected > 0 ? AppColors.amber : AppColors.emerald,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'import : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Import CSV simplifie : accepte un CSV minimal (nom_client, rue,
  /// code_postal, ville) sans lat/lng et geocode automatiquement via
  /// BAN. Idem que [importCsv] mais le constructeur du service recoit
  /// un geocoder.
  static Future<void> importCsvGeocode({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fichier illisible')),
      );
      return;
    }
    if (!context.mounted) return;
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import simplifie ?'),
        content: Text(
          'Le CSV doit avoir au moins les colonnes nom_client, rue, '
          'code_postal, ville. L\'app geocode chaque ligne via BAN '
          '(France) -- compte ~1 seconde par client.\n\n'
          'Les doublons (meme nom ou meme position) seront fusionnes.\n\n'
          '${picked.files.first.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (shouldImport != true || !context.mounted) return;

    // Spinner non-bloquant pendant le geocodage (peut prendre 1-2 min
    // pour 100 lignes).
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Geocodage en cours, patiente...'),
        duration: Duration(seconds: 120),
      ),
    );
    try {
      final service = CarnetImportService(
        ref.read(savedDestinationsRepositoryProvider),
        geocoder: ref.read(geocodingServiceProvider),
      );
      final result = await service.importFromFile(File(path));
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      final summary = [
        if (result.created > 0) '${result.created} ajoutee(s)',
        if (result.merged > 0) '${result.merged} fusionnee(s)',
        if (result.rejected > 0) '${result.rejected} non geocodee(s)',
      ].join(' · ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary.isEmpty ? 'Aucune entree' : summary),
          backgroundColor:
              result.rejected > 0 ? AppColors.amber : AppColors.emerald,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'import : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Import vCard (.vcf) depuis Google Contacts (carte #102). Geocode
  /// les contacts sans coords GEO via BAN. Les contacts sans adresse
  /// exploitable sont ignores (le carnet = adresses de livraison).
  static Future<void> importVcard({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['vcf'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fichier illisible')),
      );
      return;
    }
    if (!context.mounted) return;
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importer ce vCard ?'),
        content: Text(
          'Les contacts du fichier (export Google Contacts / Contacts '
          'Android) seront ajoutes au carnet. L\'app geocode via BAN les '
          'adresses sans coordonnees. Les contacts sans adresse sont '
          'ignores. Doublons (meme nom / position) fusionnes.\n\n'
          '${picked.files.first.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (shouldImport != true || !context.mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Import + geocodage en cours, patiente...'),
        duration: Duration(seconds: 120),
      ),
    );
    try {
      final service = CarnetImportService(
        ref.read(savedDestinationsRepositoryProvider),
        geocoder: ref.read(geocodingServiceProvider),
      );
      final result = await service.importVcardFromFile(File(path));
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      final summary = [
        if (result.created > 0) '${result.created} ajoute(s)',
        if (result.merged > 0) '${result.merged} fusionne(s)',
        if (result.rejected > 0) '${result.rejected} sans adresse',
      ].join(' · ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary.isEmpty ? 'Aucun contact' : summary),
          backgroundColor:
              result.rejected > 0 ? AppColors.amber : AppColors.emerald,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'import : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Backfill du carnet depuis l'historique des arrets deja faits dans
  /// toutes les tournees (cf [CarnetBackfillService]). Idempotent.
  static Future<void> backfillDepuisHistorique({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldRun = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Peupler depuis l\'historique ?'),
        content: const Text(
          'L\'app va scanner toutes les tournees deja faites et ajouter '
          'chaque adresse au carnet. Les doublons sont fusionnes (pas '
          'de duplication).\n\n'
          'Operation locale, instantanee, idempotente (rejouable).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lancer'),
          ),
        ],
      ),
    );
    if (shouldRun != true || !context.mounted) return;
    try {
      final service = CarnetBackfillService(
        ref.read(appDatabaseProvider),
        ref.read(savedDestinationsRepositoryProvider),
      );
      final result = await service.backfillFromStops();
      if (!context.mounted) return;
      final summary = [
        '${result.totalStops} arret(s) scanne(s)',
        if (result.created > 0) '${result.created} ajoutee(s)',
        if (result.merged > 0) '${result.merged} fusionnee(s)',
        if (result.skipped > 0) '${result.skipped} skipped',
      ].join(' · ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary),
          backgroundColor:
              result.created > 0 ? AppColors.emerald : AppColors.amber,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur backfill : ${humanizeAnyError(e)}')),
      );
    }
  }
}
