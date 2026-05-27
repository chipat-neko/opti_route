import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';

/// Confirme la suppression d'un [Stop] via AlertDialog, puis si
/// confirme : delegue au CloudSyncService (propagation cloud best-effort),
/// invalide l'optim de la tournee et relance le local reorder.
///
/// Retourne true si la suppression a reussi (l'appelant peut alors
/// pop l'ecran), false sinon (annulation ou erreur deja flashee
/// dans une SnackBar).
///
/// Extrait de `ajout_arret_screen.dart` (carte Trello #165).
Future<bool> confirmAndDeleteStop(
  BuildContext context,
  WidgetRef ref, {
  required Stop stop,
  required int tourneeId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Supprimer cet arret ?'),
      content: Text(
        stop.nomClient != null && stop.nomClient!.isNotEmpty
            ? '${stop.nomClient} - ${stop.adresseBrute}'
            : stop.adresseBrute,
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
  if (confirmed != true || !context.mounted) return false;

  try {
    // Jalon 2.F : propagation cloud (best-effort) + local.
    await ref
        .read(cloudSyncServiceProvider)
        .deleteStopWithCloudCleanup(stop.id);
    await ref
        .read(tourneesRepositoryProvider)
        .invalidateOptimization(tourneeId);
    // Auto-reorder local (nearest-neighbor, sans appel ORS) :
    // maintient l'ordre des arrets pre-trie a chaque modif.
    await ref
        .read(localReorderServiceProvider)
        .reorder(tourneeId);
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Erreur lors de la suppression : ${humanizeAnyError(e)}'),
      ),
    );
    return false;
  }
}
