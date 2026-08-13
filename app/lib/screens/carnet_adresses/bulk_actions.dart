import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Actions en masse du mode selection du carnet (carte #104).
/// ════════════════════════════════════════════════════════════════
///
/// Extraites de `carnet_adresses_screen.dart` (refactor F27) : etaient
/// les methodes `_bulkFavori` / `_bulkColorTag` / `_bulkDelete`.
///
/// Chaque action recoit les [ids] cochees et un callback [onDone]
/// appele juste apres l'ecriture en base : l'ecran s'en sert pour
/// sortir du mode selection (il est le seul a connaitre cet etat).
class CarnetBulkActions {
  CarnetBulkActions._();

  /// Marque toutes les fiches cochees comme favorites.
  static Future<void> marquerFavori({
    required BuildContext context,
    required WidgetRef ref,
    required List<int> ids,
    required VoidCallback onDone,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(savedDestinationsRepositoryProvider)
        .setFavoriBulk(ids, true);
    onDone();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${ids.length} fiche(s) marquees favori'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  /// Bottom sheet de choix d'etiquette couleur, applique a toutes les
  /// fiches cochees. "Retirer l'etiquette" remet `colorTag` a null.
  static Future<void> choisirColorTag({
    required BuildContext context,
    required WidgetRef ref,
    required List<int> ids,
    required VoidCallback onDone,
  }) async {
    final p = context.palette;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.r22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Etiquette couleur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              Wrap(
                spacing: AppSpacing.x10,
                runSpacing: AppSpacing.x10,
                children: [
                  for (final (tag, color) in colorTagOptions)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(tag),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x14),
              TextButton(
                onPressed: () => Navigator.of(context).pop('__none__'),
                child: const Text('Retirer l\'etiquette'),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return; // sheet ferme sans choix
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(savedDestinationsRepositoryProvider)
        .setColorTagBulk(ids, picked == '__none__' ? null : picked);
    onDone();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${ids.length} fiche(s) mises a jour'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  /// Confirmation puis suppression definitive des fiches cochees.
  static Future<void> confirmerSuppression({
    required BuildContext context,
    required WidgetRef ref,
    required List<int> ids,
    required VoidCallback onDone,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ${ids.length} fiche(s) ?'),
        content: const Text(
          'Les fiches selectionnees seront supprimees du carnet local. '
          'Action irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red.withValues(alpha: 0.15),
              foregroundColor: AppColors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(savedDestinationsRepositoryProvider)
        .deleteBulk(ids);
    onDone();
    messenger.showSnackBar(
      SnackBar(content: Text('${ids.length} fiche(s) supprimees')),
    );
  }
}
