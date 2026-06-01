import 'package:supabase_flutter/supabase_flutter.dart';

import '../cloud_error_humanizer.dart';
import '../cloud_sync_types.dart';
import 'cloud_sync_helpers.dart';

/// ════════════════════════════════════════════════════════════════
/// Gestion des employés d'une entreprise (carte #366, épopée #361).
/// ════════════════════════════════════════════════════════════════
///
/// Côté CHEF : inviter (code OU mail, décision #372), lister les membres,
/// révoquer. Côté EMPLOYÉ (saisie du code) : [acceptByCode], consommée
/// par l'écran « Qui es-tu ? » (#373).
///
/// Pas de [AppDatabase] : tout passe par le cloud (source de vérité).
/// Les membres ne sont PAS mirroir local (emails dans auth.users, lisibles
/// seulement via RPC SECURITY DEFINER). Le [SupabaseClient] + userId sont
/// fournis par le caller ([CloudSyncService]) via ses guards.
class CloudMembresEntrepriseSync {
  const CloudMembresEntrepriseSync();

  /// Invite par MAIL via l'Edge Function `invite_employee` (#363, déjà
  /// déployée). Le serveur vérifie les droits du caller. [roleTarget] =
  /// 'chef_entrepot' | 'employe'.
  /// Retourne le code généré (à afficher au chef comme filet de sécurité)
  /// + si le mail Brevo est bien parti. Option B (#60) : l'Edge Function
  /// génère un code à 6 chiffres et l'envoie par mail ; l'employé le
  /// saisit dans « Rejoindre une équipe ».
  Future<({String code, bool emailSent, String? emailError})> inviteByMail(
    SupabaseClient client, {
    required String entrepriseId,
    String? entrepotId,
    required String email,
    required String roleTarget,
  }) async {
    try {
      final res = await client.functions.invoke(
        'invite_employee',
        body: {
          'email': email.trim().toLowerCase(),
          'entreprise_id': entrepriseId,
          'entrepot_id': entrepotId,
          'role': roleTarget,
        },
      );
      // L'Edge Function renvoie 201 en succès (cf index.ts).
      if (res.status != 200 && res.status != 201) {
        final data = res.data;
        final msg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'statut ${res.status}';
        throw CloudSyncException('Echec invitation mail : $msg');
      }
      final data = res.data;
      if (data is! Map || data['code'] == null) {
        throw CloudSyncException(
            'Echec invitation mail : réponse serveur inattendue');
      }
      return (
        code: data['code'].toString(),
        emailSent: data['email_sent'] == true,
        emailError: data['email_error']?.toString(),
      );
    } on CloudSyncException {
      rethrow;
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec invitation mail : ${humanizeCloudError(e)}');
    }
  }

  /// Invite par CODE : génère un code à 6 chiffres + INSERT dans
  /// `entreprise_invitations` (RLS `ins_inv` autorise admin/chef).
  /// Retourne le code à afficher / partager. [validityHours] : durée de
  /// validité (décision #372 : 24 à 72h, défaut 72).
  Future<String> inviteByCode(
    SupabaseClient client,
    String userId, {
    required String entrepriseId,
    String? entrepotId,
    required String roleTarget,
    int validityHours = 72,
  }) async {
    final expires =
        DateTime.now().toUtc().add(Duration(hours: validityHours));
    for (var attempt = 0; attempt < 2; attempt++) {
      final code = generateInvitationCode();
      try {
        await client.from('entreprise_invitations').insert({
          'entreprise_id': entrepriseId,
          'entrepot_id': entrepotId,
          // email null = invitation par code (colonne rendue nullable
          // côté SQL section 8).
          'role_target': roleTarget,
          'invited_by': userId,
          'statut': 'pending',
          'code': code,
          'expires_at': expires.toIso8601String(),
        });
        return code;
      } on Object catch (e) {
        if (attempt == 1) {
          throw CloudSyncException(
              'Echec creation code : ${humanizeCloudError(e)}');
        }
      }
    }
    throw const CloudSyncException('Echec creation code (collision).');
  }

  /// Liste les membres d'une entreprise via RPC `list_entreprise_members`.
  Future<List<EntrepriseMembreInfo>> listMembers(
    SupabaseClient client,
    String entrepriseId,
  ) async {
    try {
      final res = await client.rpc(
        'list_entreprise_members',
        params: {'p_entreprise_id': entrepriseId},
      );
      if (res is! List) {
        throw const CloudSyncException(
          'Reponse cloud invalide (list_entreprise_members).',
        );
      }
      return res.map((r) {
        final row = r as Map<String, dynamic>;
        return EntrepriseMembreInfo(
          userId: row['user_id'] as String,
          email: row['email'] as String? ?? '?',
          role: row['role'] as String,
          statut: row['statut'] as String? ?? 'actif',
          revokedAt: row['revoked_at'] == null
              ? null
              : DateTime.parse(row['revoked_at'] as String).toLocal(),
          entrepotId: row['entrepot_id'] as String?,
          entrepotNom: row['entrepot_nom'] as String?,
        );
      }).toList();
    } on PostgrestException catch (e) {
      if (e.message.contains('NOT_A_MEMBER')) {
        throw const CloudSyncException(
            'Tu n\'as pas acces a cette entreprise.');
      }
      throw CloudSyncException('Echec liste membres : ${e.message}');
    } on CloudSyncException {
      rethrow;
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec liste membres : ${humanizeCloudError(e)}');
    }
  }

  /// Révoque un membre : statut='revoque' + revoked_at=now (RLS `upd_eu`
  /// autorise l'admin). Le cron J+30 (#363) coupe définitivement après
  /// 30 jours. [entrepotId] non-null : révoque aussi l'adhésion entrepôt.
  Future<void> revokeMember(
    SupabaseClient client, {
    required String entrepriseId,
    required String userId,
    String? entrepotId,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await client
          .from('entreprise_users')
          .update({'statut': 'revoque', 'revoked_at': now})
          .eq('entreprise_id', entrepriseId)
          .eq('user_id', userId);
      if (entrepotId != null) {
        await client
            .from('entrepot_users')
            .update({'statut': 'revoque', 'revoked_at': now})
            .eq('entrepot_id', entrepotId)
            .eq('user_id', userId);
      }
    } on Object catch (e) {
      throw CloudSyncException('Echec revocation : ${humanizeCloudError(e)}');
    }
  }

  /// Réactive un membre révoqué (statut='actif', revoked_at=null) avant
  /// la fin du J+30. RLS `upd_eu` (admin).
  Future<void> reactivateMember(
    SupabaseClient client, {
    required String entrepriseId,
    required String userId,
    String? entrepotId,
  }) async {
    try {
      await client
          .from('entreprise_users')
          .update({'statut': 'actif', 'revoked_at': null})
          .eq('entreprise_id', entrepriseId)
          .eq('user_id', userId);
      if (entrepotId != null) {
        await client
            .from('entrepot_users')
            .update({'statut': 'actif', 'revoked_at': null})
            .eq('entrepot_id', entrepotId)
            .eq('user_id', userId);
      }
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec reactivation : ${humanizeCloudError(e)}');
    }
  }

  /// Mute un employé : le place dans [entrepotId] avec le rôle [role]
  /// ('chef_entrepot' | 'employe'). Couvre promouvoir/rétrograder ET
  /// déplacer d'entrepôt (RPC `set_employe_entrepot`, admin only).
  Future<void> setEmployeEntrepot(
    SupabaseClient client, {
    required String entrepriseId,
    required String userId,
    required String entrepotId,
    required String role,
  }) async {
    try {
      await client.rpc('set_employe_entrepot', params: {
        'p_entreprise_id': entrepriseId,
        'p_user_id': userId,
        'p_entrepot_id': entrepotId,
        'p_role': role,
      });
    } on Object catch (e) {
      throw CloudSyncException('Echec mutation : ${humanizeCloudError(e)}');
    }
  }

  /// Révoque un employé de l'entreprise + tous ses entrepôts (RPC
  /// `revoke_employe`, admin only). Le cron J+30 coupe définitivement.
  Future<void> revokeEmploye(
    SupabaseClient client, {
    required String entrepriseId,
    required String userId,
  }) async {
    try {
      await client.rpc('revoke_employe', params: {
        'p_entreprise_id': entrepriseId,
        'p_user_id': userId,
      });
    } on Object catch (e) {
      throw CloudSyncException('Echec revocation : ${humanizeCloudError(e)}');
    }
  }

  /// Côté EMPLOYÉ : saisit un code d'invitation → RPC
  /// `accept_entreprise_invitation`. Retourne l'entreprise_id rejointe.
  /// Sera consommée par l'écran « Qui es-tu ? » (#373).
  Future<String> acceptByCode(SupabaseClient client, String code) async {
    final trimmed = code.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(trimmed)) {
      throw const CloudSyncException(
          'Le code doit faire 6 chiffres (ex: 123456).');
    }
    try {
      final res = await client.rpc(
        'accept_entreprise_invitation',
        params: {'p_code': trimmed},
      );
      if (res is String) return res;
      throw const CloudSyncException('Reponse cloud invalide a l\'invitation.');
    } on PostgrestException catch (e) {
      throw CloudSyncException(invitationErrorToFr(e.message));
    } on CloudSyncException {
      rethrow;
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec acceptation invitation : ${humanizeCloudError(e)}');
    }
  }
}

/// Info d'un membre d'entreprise renvoyée par `list_entreprise_members`.
/// `entrepotId`/`entrepotNom` non-null = adhésion au niveau d'un entrepôt
/// précis ; null = adhésion au niveau entreprise.
class EntrepriseMembreInfo {
  const EntrepriseMembreInfo({
    required this.userId,
    required this.email,
    required this.role,
    required this.statut,
    this.revokedAt,
    this.entrepotId,
    this.entrepotNom,
  });

  final String userId;
  final String email;
  final String role;
  final String statut; // 'actif' | 'revoque' | 'expire'
  final DateTime? revokedAt;
  final String? entrepotId;
  final String? entrepotNom;

  /// Jours restants avant le lockout J+30 (cron #363). Null si pas
  /// révoqué. 0 si déjà dépassé (le cron passera bientôt en 'expire').
  int? get joursAvantExpiration {
    if (statut != 'revoque' || revokedAt == null) return null;
    final deadline = revokedAt!.add(const Duration(days: 30));
    final r = deadline.difference(DateTime.now()).inDays;
    return r < 0 ? 0 : r;
  }
}
