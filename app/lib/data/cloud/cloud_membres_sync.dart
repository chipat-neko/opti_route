import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cloud_error_humanizer.dart';
import '../cloud_sync_types.dart';
import '../database.dart';
import 'cloud_sync_helpers.dart';

/// ════════════════════════════════════════════════════════════════
/// Sync des tournees partagees : invitations + adhesions (jalon 3.A/B).
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `cloud_sync_service.dart` (carte Trello #167, etape 3).
/// Gere le cycle de vie d'une equipe sur une tournee : creation de code
/// d'invitation, acceptation (RPC), liste des membres (RPC SECURITY
/// DEFINER), depart volontaire, ejection par l'owner.
///
/// Le [SupabaseClient] et le `userId` sont fournis par le caller
/// ([CloudSyncService]) via ses guards. Les operations de cleanup local
/// (supprimer une tournee quittee) passent par [_db].
class CloudMembresSync {
  CloudMembresSync(this._db);

  final AppDatabase _db;

  /// Crée une invitation à 6 chiffres pour la tournée locale donnée.
  /// La tournée doit déjà avoir un `cloudId` (= pushée au moins une
  /// fois). Retourne le code à afficher / partager.
  Future<String> createInvitation(
    SupabaseClient client,
    String userId,
    int localTourneeId,
  ) async {
    final tournee = await (_db.select(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .getSingleOrNull();
    if (tournee == null) {
      throw CloudSyncException(
        'Tournee introuvable en local (id=$localTourneeId).',
      );
    }
    final cloudId = tournee.cloudId;
    if (cloudId == null) {
      throw const CloudSyncException(
        'Pousse d\'abord cette tournee au cloud (menu Plus > "Pousser '
        'au cloud") avant d\'inviter un coequipier.',
      );
    }
    // 2 tentatives max pour gérer une (très rare) collision PK.
    for (var attempt = 0; attempt < 2; attempt++) {
      final code = generateInvitationCode();
      try {
        await client.from('tournee_invitations').insert({
          'code': code,
          'tournee_id': cloudId,
          'created_by': userId,
        });
        return code;
      } on Object catch (e) {
        if (attempt == 1) {
          throw CloudSyncException(
              'Echec creation invitation : ${humanizeCloudError(e)}');
        }
      }
    }
    throw const CloudSyncException('Echec creation invitation (collision).');
  }

  /// Le coequipier saisit le code à 6 chiffres → RPC `accept_invitation`
  /// qui valide + insère le row membre + marque le code utilisé. Retourne
  /// le cloud UUID de la tournée rejointe. Le caller declenche ensuite
  /// un pull pour recuperer la tournee + stops en local.
  Future<String> acceptInvitation(SupabaseClient client, String code) async {
    final trimmed = code.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(trimmed)) {
      throw const CloudSyncException(
        'Le code doit faire 6 chiffres (ex: 123456).',
      );
    }
    try {
      final res = await client.rpc(
        'accept_invitation',
        params: {'p_code': trimmed},
      );
      if (res is String) return res;
      throw const CloudSyncException(
        'Reponse cloud invalide a l\'invitation.',
      );
    } on PostgrestException catch (e) {
      throw CloudSyncException(invitationErrorToFr(e.message));
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec acceptation invitation : ${humanizeCloudError(e)}');
    }
  }

  /// Pull la table cloud `tournee_membres` et remplace intégralement le
  /// cache local (`replace-all` plutôt que merge : la liste est append-
  /// only côté cloud, et un DELETE cloud doit se refléter en local).
  Future<void> pullMembres(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('tournee_membres').select();
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec fetch tournee_membres : ${humanizeCloudError(e)}');
    }
    await _db.transaction(() async {
      await _db.delete(_db.tourneeMembres).go();
      for (final r in rows) {
        final row = r as Map<String, dynamic>;
        await _db.into(_db.tourneeMembres).insert(
              TourneeMembresCompanion.insert(
                tourneeCloudId: row['tournee_id'] as String,
                userCloudId: row['user_id'] as String,
                role: row['role'] as String,
                joinedAt: Value(
                  DateTime.parse(row['joined_at'] as String).toLocal(),
                ),
              ),
            );
      }
    });
  }

  /// Liste les membres d'une tournee partagee via RPC SECURITY DEFINER
  /// (sous-jalon 3.B). Throws [CloudSyncException] si pas membre,
  /// tournee jamais push au cloud, ou erreur reseau.
  Future<List<TourneeMembreInfo>> listMembers(
    SupabaseClient client,
    int localTourneeId,
  ) async {
    final tournee = await (_db.select(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .getSingleOrNull();
    if (tournee == null) {
      throw CloudSyncException(
        'Tournee introuvable en local (id=$localTourneeId).',
      );
    }
    final cloudId = tournee.cloudId;
    if (cloudId == null) {
      throw const CloudSyncException(
        'Tournee jamais sync — aucun coequipier possible.',
      );
    }
    try {
      final res = await client.rpc(
        'list_tournee_members',
        params: {'p_tournee_id': cloudId},
      );
      if (res is! List) {
        throw const CloudSyncException(
          'Reponse cloud invalide (list_tournee_members).',
        );
      }
      return res.map((r) {
        final row = r as Map<String, dynamic>;
        return TourneeMembreInfo(
          userCloudId: row['user_id'] as String,
          email: row['email'] as String? ?? '?',
          role: row['role'] as String,
          joinedAt: DateTime.parse(row['joined_at'] as String).toLocal(),
        );
      }).toList();
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_A_MEMBER')) {
        throw const CloudSyncException(
          'Tu n\'es plus membre de cette tournee.',
        );
      }
      throw CloudSyncException('Echec list membres : ${e.message}');
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec list membres : ${humanizeCloudError(e)}');
    }
  }

  /// Quitte une tournee partagee (DELETE row tournee_membres pour le
  /// user courant). L'owner ne peut PAS quitter — il doit supprimer la
  /// tournee a la place. Nettoie la tournee + stops en local apres.
  Future<void> leaveTournee(
    SupabaseClient client,
    String userId,
    int localTourneeId,
  ) async {
    final tournee = await (_db.select(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .getSingleOrNull();
    if (tournee?.cloudId == null) {
      throw const CloudSyncException('Tournee jamais sync au cloud.');
    }
    // Refuser si owner : la RLS DELETE accepte mais l'UX est mauvaise
    // (l'owner perd l'acces a sa propre tournee).
    final members = await listMembers(client, localTourneeId);
    TourneeMembreInfo? me;
    for (final m in members) {
      if (m.userCloudId == userId) {
        me = m;
        break;
      }
    }
    if (me == null) {
      throw const CloudSyncException('Tu n\'es pas membre de cette tournee.');
    }
    if (me.role == 'owner') {
      throw const CloudSyncException(
        'Tu es le chef de cette tournee. Pour la liberer, supprime-la '
        'plutot.',
      );
    }
    try {
      await client.from('tournee_membres').delete()
          .eq('tournee_id', tournee!.cloudId!)
          .eq('user_id', userId);
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec quitter tournee : ${humanizeCloudError(e)}');
    }
    // Nettoyage local : supprime la tournee + ses stops (on n'y a plus
    // acces cote cloud, donc inutile de les garder localement).
    await (_db.delete(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .go();
  }

  /// L'owner ejecte un membre d'une tournee partagee. Throws si pas
  /// owner / target n'est pas membre / pas auth.
  Future<void> kickMember(
    SupabaseClient client,
    String userId,
    int localTourneeId,
    String memberUserCloudId,
  ) async {
    final tournee = await (_db.select(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .getSingleOrNull();
    if (tournee?.cloudId == null) {
      throw const CloudSyncException('Tournee jamais sync au cloud.');
    }
    if (memberUserCloudId == userId) {
      throw const CloudSyncException(
        'Pour quitter ta propre tournee, utilise "Quitter".',
      );
    }
    final List<dynamic> deleted;
    try {
      // .select() pour recuperer les rows supprimees et detecter si la
      // RLS DELETE a silencieusement bloque (auquel cas .delete() retourne
      // success sans erreur mais 0 rows affectees). Bug Trello #70.
      deleted = await client.from('tournee_membres').delete()
          .eq('tournee_id', tournee!.cloudId!)
          .eq('user_id', memberUserCloudId)
          .select();
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec ejecter coequipier : ${humanizeCloudError(e)}');
    }
    if (deleted.isEmpty) {
      throw const CloudSyncException(
        'Aucun coequipier ejecte. Verifie que tu es bien le chef de cette '
        'tournee (la policy RLS DELETE n\'autorise que l\'owner a kick).',
      );
    }
  }
}
