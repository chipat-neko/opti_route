import 'package:supabase_flutter/supabase_flutter.dart';

import '../cloud_error_humanizer.dart';
import '../cloud_sync_types.dart';

/// ════════════════════════════════════════════════════════════════
/// Sync des notes perso employé sur un client partagé (carte #367).
/// ════════════════════════════════════════════════════════════════
///
/// Épopée multi-tenant #361, jalon 6/6. Chaque employé peut écrire des
/// notes **privées** sur une fiche du carnet partagé (entreprise /
/// entrepôt) — invisibles aux autres (RLS stricte `user_id = auth.uid()`
/// côté Supabase, table `saved_destination_notes_perso`).
///
/// Clé d'unicité cloud : (saved_destination_id, user_id). On identifie
/// la fiche par son `cloud_id` (l'UUID partagé du carnet). Une fiche
/// jamais synchronisée (cloudId null) ne peut pas porter de note perso.
///
/// Stateless : le [SupabaseClient] + userId sont fournis par le caller
/// ([CloudSyncService]) via ses guards.
class CloudNotesPersoSync {
  const CloudNotesPersoSync();

  /// Lit la note perso de l'utilisateur courant pour la fiche
  /// [savedDestinationCloudId]. Retourne null si aucune note. La RLS
  /// filtre déjà sur `user_id = auth.uid()`.
  Future<String?> getNote(
    SupabaseClient client,
    String savedDestinationCloudId,
  ) async {
    try {
      final rows = await client
          .from('saved_destination_notes_perso')
          .select('notes')
          .eq('saved_destination_id', savedDestinationCloudId)
          .limit(1);
      if (rows.isEmpty) return null;
      return rows.first['notes'] as String?;
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec lecture note perso : ${humanizeCloudError(e)}');
    }
  }

  /// Upsert la note perso (clé unique saved_destination_id + user_id).
  /// [notes] vide -> on supprime la ligne (pas de note vide qui traîne).
  Future<void> upsertNote(
    SupabaseClient client,
    String userId, {
    required String savedDestinationCloudId,
    required String notes,
  }) async {
    final clean = notes.trim();
    try {
      if (clean.isEmpty) {
        await client
            .from('saved_destination_notes_perso')
            .delete()
            .eq('saved_destination_id', savedDestinationCloudId)
            .eq('user_id', userId);
        return;
      }
      await client.from('saved_destination_notes_perso').upsert(
        {
          'saved_destination_id': savedDestinationCloudId,
          'user_id': userId,
          'notes': clean,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'saved_destination_id,user_id',
      );
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec enregistrement note perso : ${humanizeCloudError(e)}');
    }
  }
}
