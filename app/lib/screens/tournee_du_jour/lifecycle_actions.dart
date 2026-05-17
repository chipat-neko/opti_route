import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/location_service.dart';
import '../../data/notifications_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Handlers lifecycle (demarrer/pause/arreter) extraits de
/// [TourneeDuJourScreen] (refactor jalon 2026-05-17 phase 4).
/// ════════════════════════════════════════════════════════════════
class LifecycleTourneeActions {
  LifecycleTourneeActions._();

  /// Demarre la tournee : demande permission GPS, bascule statut a
  /// 'en_cours', pose timestamp `demareeLe` si pas deja set (reprise
  /// apres pause = on garde le premier).
  static Future<void> demarrer({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await LocationService.ensurePermission();
      if (!ok) return;
    } on LocationPermissionDenied catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    await ref.read(tourneesRepositoryProvider).update(
          tournee.id,
          TourneesCompanion(
            statut: const Value('en_cours'),
            demareeLe: tournee.demareeLe == null
                ? Value(DateTime.now())
                : const Value.absent(),
          ),
        );
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Tournee demarree. Bonne route !'),
        backgroundColor: AppColors.emerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Pause "courte" (pause dejeuner par ex) sans changer le statut de
  /// la tournee. Toggle entre pause / reprendre selon que `pauseeLe`
  /// est deja set ou non.
  static Future<void> pauseShort({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(tourneesRepositoryProvider);
    final t = await repo.getById(tournee.id);
    if (t == null || !context.mounted) return;
    if (t.pauseeLe == null) {
      await repo.pauseTournee(t.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournee en pause. Tap "Reprendre" quand tu repars.'),
          backgroundColor: AppColors.amber,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      await repo.reprendreTournee(t.id);
      if (!context.mounted) return;
      final pauseDuree = DateTime.now().difference(t.pauseeLe!);
      final mins = pauseDuree.inMinutes;
      messenger.showSnackBar(
        SnackBar(
          content: Text('C\'est reparti. Pause de ${mins}min comptee.'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Arrete la tournee (passe en 'optimisee'). Si des stops restent
  /// `a_livrer`, push une notif rappel "arrets oublies".
  static Future<void> arreter({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mettre la tournee en pause ?'),
        content: const Text(
          'La tournee repasse en mode "optimisee". Tu pourras la '
          'relancer plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mettre en pause'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(tourneesRepositoryProvider).update(
          tournee.id,
          const TourneesCompanion(statut: Value('optimisee')),
        );
    // Alerte "arrets oublies" : si la tournee est mise en pause avec
    // des stops a_livrer restants, on push une notif rappel.
    final stops = await ref
        .read(stopsRepositoryProvider)
        .getByTournee(tournee.id);
    final pending =
        stops.where((s) => s.statutLivraison == 'a_livrer').length;
    if (pending > 0) {
      unawaited(
        NotificationsService.instance.showPendingStopsAlert(
          tourneeId: tournee.id,
          nomTournee: tournee.nom,
          nbPending: pending,
        ),
      );
    }
  }
}
