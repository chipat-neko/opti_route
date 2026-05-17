import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/cloud_sync_service.dart';
import '../../data/database.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import '../cloud/invitation_code_dialog.dart';

/// ════════════════════════════════════════════════════════════════
/// Handlers cloud extraits de [TourneeDuJourScreen] (refactor jalon
/// 2026-05-17 — sortir les actions de l'ecran pour reduire sa taille
/// de 1409 a ~1250 lignes).
/// ════════════════════════════════════════════════════════════════
///
/// Toutes les methodes sont statiques et prennent en parametre :
/// - `BuildContext context` : pour les SnackBar / dialogs / Navigator
/// - `WidgetRef ref` : pour acceder aux providers Riverpod
/// - `Tournee tournee` : tournee courante
///
/// Conventions :
/// - Erreurs cote service -> SnackBar rouge avec le message FR de
///   [CloudSyncException]
/// - Succes -> SnackBar emerald
/// - `mountedCheck` : optional pour les ecrans qui doivent re-tester
///   apres un await (le caller passe `() => mounted` comme closure)
class CloudTourneeActions {
  CloudTourneeActions._();

  /// Push la tournee complete vers Supabase (idempotent : INSERT si
  /// cloudId null, UPDATE sinon).
  static Future<void> push({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(cloudSyncServiceProvider);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sync en cours...'),
        duration: Duration(seconds: 10),
      ),
    );
    try {
      await service.pushTournee(tournee.id);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournee synchronisee au cloud'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } on CloudSyncException catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  /// Jalon 3.A : genere un code 6 chiffres + dialog Copier / Partager.
  static Future<void> invite({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(cloudSyncServiceProvider);
    String? code;
    try {
      code = await service.createInvitation(tournee.id);
    } on CloudSyncException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => InvitationCodeDialog(code: code!),
    );
  }

  /// Jalon 3.B : quitter une tournee partagee (refuse si owner).
  /// `onSuccess` est appele apres le succes (typiquement
  /// `() => Navigator.of(ctx).pop()` pour fermer l'ecran).
  static Future<void> leave({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
    required VoidCallback onSuccess,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter cette tournee ?'),
        content: const Text(
          'Tu n\'auras plus acces a cette tournee ni a ses arrets. '
          'Le chef pourra te re-inviter via un nouveau code si besoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amber.withValues(alpha: 0.18),
              foregroundColor: AppColors.amber,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(cloudSyncServiceProvider).leaveTournee(tournee.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournee quittee'),
          backgroundColor: AppColors.emerald,
        ),
      );
      onSuccess();
    } on CloudSyncException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  /// Confirme + delete une tournee (propage cloud + Storage + local
  /// via [CloudSyncService.deleteTourneeWithCloudCleanup]). Retourne
  /// `true` si delete confirme et reussi (le caller peut pop l'ecran),
  /// `false` si annule ou erreur.
  static Future<bool> confirmAndDelete({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette tournee ?'),
        content: Text(
          '"${tournee.nom}" et tous ses arrets seront supprimes '
          'definitivement.',
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(cloudSyncServiceProvider)
          .deleteTourneeWithCloudCleanup(tournee.id);
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      messenger.showSnackBar(
        SnackBar(
            content:
                Text('Erreur lors de la suppression : ${humanizeAnyError(e)}')),
      );
      return false;
    }
  }
}
