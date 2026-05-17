import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/location_service.dart';
import '../../data/notifications_service.dart';
import '../../providers/database_providers.dart';
import '../../providers/geocoding_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Handlers d'actions en masse sur les stops, extraits de
/// [TourneeDuJourScreen] (refactor jalon 2026-05-17 phase 3).
/// ════════════════════════════════════════════════════════════════
class StopsBulkActions {
  StopsBulkActions._();

  /// "Tout marquer livre" : valide d'un coup tous les arrets restants
  /// en statut 'a_livrer'. Capture GPS one-shot pour tout le batch.
  /// Bascule auto la tournee en 'terminee' si tous les arrets sont
  /// valides apres l'action.
  static Future<void> batchLivre({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final stopsRepo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);
    final all = await stopsRepo.getByTournee(tournee.id);
    final pending =
        all.where((s) => s.statutLivraison == 'a_livrer').toList();
    if (!context.mounted) return;
    if (pending.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Aucun arret en attente de livraison'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tout marquer livre ?'),
        content: Text(
          '${pending.length} arret(s) en attente vont etre marques comme '
          'livres. Tu pourras revenir en arriere arret par arret depuis la '
          'bottom sheet si besoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: context.palette.paper,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tout livrer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Capture GPS une fois pour tout le batch (best-effort).
    ({double lat, double lng})? pos;
    try {
      final ok = await LocationService.ensurePermission();
      if (ok) {
        final p = await LocationService.currentPosition()
            .timeout(const Duration(seconds: 4));
        pos = (lat: p.latitude, lng: p.longitude);
      }
    } catch (_) {/* best-effort GPS */}

    for (final s in pending) {
      await stopsRepo.markLivre(s.id, position: pos);
    }
    // Bascule auto en 'terminee' (tous les arrets valides maintenant).
    final refreshed = await stopsRepo.getByTournee(tournee.id);
    final tousValides = refreshed.every(
      (s) => s.statutLivraison == 'livre' || s.statutLivraison == 'echec',
    );
    if (tousValides) {
      await tourneesRepo.update(
        tournee.id,
        const TourneesCompanion(statut: Value('terminee')),
      );
      await NotificationsService.instance.cancelTourneeRappel(tournee.id);
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${pending.length} arret(s) marques livres'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  /// Annule le dernier statut (livre ou echec) pose dans cette tournee.
  /// Retrouve le stop via `getLastTransitionedStop` puis le repasse en
  /// 'a_livrer'.
  static Future<void> undoLastStatus({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(stopsRepositoryProvider);
      final last = await repo.getLastTransitionedStop(tournee.id);
      if (!context.mounted) return;
      if (last == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Aucun statut a annuler dans cette tournee.'),
          ),
        );
        return;
      }
      await repo.revertStatus(last.id);
      if (!context.mounted) return;
      final label = last.nomClient?.trim().isNotEmpty == true
          ? last.nomClient!.trim()
          : last.adresseBrute.split(',').first.trim();
      messenger.showSnackBar(
        SnackBar(
          content: Text('"$label" est repasse en "A livrer"'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  /// Lance le re-geocodage des arrets sans coords (mode hors-ligne).
  /// Affiche un dialog de progression simple, puis un bilan en
  /// snackbar. Si succes, invalide l'optim + reorder local.
  static Future<void> retryGeocode({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    // Dialog "loading" non dismissible
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.x14),
            Expanded(child: Text('Geolocalisation en cours...')),
          ],
        ),
      ),
    );
    try {
      final svc = ref.read(stopsGeocodeRetryServiceProvider);
      final res = await svc.retryFor(tournee.id);
      navigator.pop(); // ferme le loader
      if (!context.mounted) return;
      if (res.totalCandidats == 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Aucun arret sans GPS a geolocaliser.'),
          ),
        );
        return;
      }
      // Si on a resolu au moins 1 stop, l'optim est invalidee : le
      // bouton "Optimiser" redevient cliquable.
      if (res.resolved.isNotEmpty) {
        await ref
            .read(tourneesRepositoryProvider)
            .invalidateOptimization(tournee.id);
        await ref.read(localReorderServiceProvider).reorder(tournee.id);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.unresolved.isEmpty
                ? '${res.resolved.length} arret(s) geolocalise(s)'
                : '${res.resolved.length} resolu(s), '
                    '${res.unresolved.length} echec(s) - '
                    'verifie l\'adresse manuellement',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      navigator.pop();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  /// Affectation en masse : tous les stops non encore affectes (Moi)
  /// passent au coequipier choisi.
  static Future<void> assignRest({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.palette;
    final coequipiers =
        await ref.read(coequipiersRepositoryProvider).getAllActifs();
    if (!context.mounted) return;
    if (coequipiers.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun coequipier. Ajoute-en dans Parametres > Mon equipe.',
          ),
        ),
      );
      return;
    }
    final stops = await ref
        .read(stopsRepositoryProvider)
        .getByTournee(tournee.id);
    final reste =
        stops.where((s) => s.coequipierId == null).toList(growable: false);
    if (reste.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tous les arrets ont deja un coequipier affecte.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final picked = await showModalBottomSheet<Coequipier>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x18,
            vertical: AppSpacing.x14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Affecter ${reste.length} arret${reste.length > 1 ? "s" : ""} non affecte${reste.length > 1 ? "s" : ""} a',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              for (final c in coequipiers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorFromTag(
                      c.colorTag,
                      defaultColor: AppColors.creamSoft,
                    ),
                    child: Text(
                      _coequipierInitials(c.nom),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  title: Text(c.nom),
                  onTap: () => Navigator.of(context).pop(c),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await ref
        .read(stopsRepositoryProvider)
        .setCoequipierForUnassigned(tournee.id, picked.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${reste.length} arret${reste.length > 1 ? "s" : ""} affecte${reste.length > 1 ? "s" : ""} a ${picked.nom}',
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  static String _coequipierInitials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
