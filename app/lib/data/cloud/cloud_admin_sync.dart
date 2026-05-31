import 'package:supabase_flutter/supabase_flutter.dart';

import '../cloud_error_humanizer.dart';
import '../cloud_sync_types.dart';

/// ════════════════════════════════════════════════════════════════
/// Couche super admin (#372) + garde-fou code maître (#374).
/// ════════════════════════════════════════════════════════════════
///
/// Tout passe par des RPC SECURITY DEFINER qui revérifient
/// `is_super_admin()` côté serveur (cf `docs/supabase-schema-multi-tenant.sql`
/// section 10). Aucun secret n'est embarqué dans l'app : décompiler l'APK
/// ne révèle rien, le serveur reste seul juge. Le [SupabaseClient] est
/// fourni par [CloudSyncService] via son guard `_client()`.
class CloudAdminSync {
  const CloudAdminSync();

  /// Le compte connecté est-il super admin ? Sert à révéler (ou non) le
  /// panel admin après les 5 taps sur le numéro de version.
  Future<bool> isSuperAdmin(SupabaseClient client) async {
    try {
      final res = await client.rpc('is_super_admin');
      return res == true;
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec verification admin : ${humanizeCloudError(e)}');
    }
  }

  /// Code maître courant (créé au 1er accès côté serveur). Réservé au
  /// super admin (la RPC lève FORBIDDEN sinon).
  Future<String> getMasterCode(SupabaseClient client) async {
    try {
      final res = await client.rpc('admin_get_master_code');
      return res as String;
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec lecture code maître : ${humanizeCloudError(e)}');
    }
  }

  /// Régénère le code maître (l'ancien cesse de fonctionner). Retourne le
  /// nouveau code. Réservé au super admin.
  Future<String> regenerateMasterCode(SupabaseClient client) async {
    try {
      final res = await client.rpc('admin_regenerate_master_code');
      return res as String;
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec régénération code maître : ${humanizeCloudError(e)}');
    }
  }

  /// Liste toutes les entreprises (vue globale super admin). Réservé au
  /// super admin.
  Future<List<AdminEntrepriseInfo>> listAllEntreprises(
      SupabaseClient client) async {
    try {
      final rows = await client.rpc('admin_list_entreprises') as List<dynamic>;
      return rows
          .map((r) => AdminEntrepriseInfo.fromRow(r as Map<String, dynamic>))
          .toList();
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec liste entreprises : ${humanizeCloudError(e)}');
    }
  }
}

/// Une entreprise vue par le super admin (lecture seule, panel admin).
class AdminEntrepriseInfo {
  const AdminEntrepriseInfo({
    required this.cloudId,
    required this.nom,
    required this.siret,
    required this.createdBy,
    required this.creeLe,
  });

  final String cloudId;
  final String nom;
  final String? siret;
  final String createdBy;
  final DateTime? creeLe;

  factory AdminEntrepriseInfo.fromRow(Map<String, dynamic> row) {
    final ts = row['cree_le'];
    return AdminEntrepriseInfo(
      cloudId: row['cloud_id'] as String,
      nom: row['nom'] as String,
      siret: row['siret'] as String?,
      createdBy: row['created_by'] as String,
      creeLe: ts == null ? null : DateTime.tryParse(ts as String),
    );
  }
}
