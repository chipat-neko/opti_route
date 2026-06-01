import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../cloud_error_humanizer.dart';
import '../cloud_sync_types.dart';
import '../database.dart';

/// ════════════════════════════════════════════════════════════════
/// Sync multi-tenant (entreprises + entrepôts) vers/depuis Supabase.
/// ════════════════════════════════════════════════════════════════
///
/// Carte Trello #364 (épopée multi-tenant #361, jalon 3/6).
///
/// **Source de vérité = Supabase** (RLS strict, cf
/// `docs/supabase-schema-multi-tenant.sql`). Ces méthodes écrivent
/// d'abord côté cloud, puis font un miroir local Drift pour
/// l'affichage offline et les FK locales `saved_destinations`.
///
/// L'`cloud_id` (UUID v4) est généré côté client et fourni à l'INSERT :
/// la colonne a un `default gen_random_uuid()` mais on impose notre
/// UUID pour garder 1 seul ID partout (pas de mapping), cohérent avec
/// le carnet ([CloudCarnetSync]) et les tournées.
///
/// Le [SupabaseClient] + `userId` sont fournis par le caller
/// ([CloudSyncService]) via ses guards `_client()` / `_requireUserId()`.
///
/// **Rôle admin** : à la création, le trigger SQL `on_entreprise_created`
/// inscrit automatiquement le créateur comme `admin_entreprise`. Côté
/// app, on déduit « je suis admin » via `entreprise.createdBy == userId`.
/// Le miroir local des memberships (chef_entrepot / employé) viendra
/// avec la gestion des employés (carte #366).
class CloudEntrepriseSync {
  CloudEntrepriseSync(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // ─── Création ───────────────────────────────────────────────────

  /// Crée une entreprise côté cloud (+ admin auto via trigger SQL) puis
  /// en miroir local. Retourne le `cloud_id` de l'entreprise créée.
  ///
  /// **Via RPC `create_entreprise` (SECURITY DEFINER)** et non un INSERT
  /// direct : la création est bridée par un **code maître** vérifié côté
  /// serveur (garde-fou #374). Le super admin en est dispensé (la RPC le
  /// détecte via `is_super_admin()`), donc [code] peut être null pour lui.
  /// La policy `ins_entreprises` est fermée → l'INSERT direct ne passe plus.
  Future<String> createEntreprise(
    SupabaseClient client,
    String userId, {
    required String nom,
    String? siret,
    String? code,
  }) async {
    final id = _uuid.v4();
    final cleanNom = nom.trim();
    final cleanSiret =
        (siret == null || siret.trim().isEmpty) ? null : siret.trim();
    final cleanCode =
        (code == null || code.trim().isEmpty) ? null : code.trim();
    try {
      await client.rpc('create_entreprise', params: {
        'p_cloud_id': id,
        'p_nom': cleanNom,
        'p_siret': cleanSiret,
        'p_code': cleanCode,
      });
    } on Object catch (e) {
      // Code maître refusé par la RPC : message clair plutôt que brut SQL.
      if (e.toString().contains('INVALID_MASTER_CODE')) {
        throw CloudSyncException(
            'Code d\'activation invalide. Demande le code au responsable.');
      }
      throw CloudSyncException(
          'Echec creation entreprise : ${humanizeCloudError(e)}');
    }
    await _db.into(_db.entreprises).insertOnConflictUpdate(
          EntreprisesCompanion.insert(
            cloudId: id,
            nom: cleanNom,
            siret: Value(cleanSiret),
            createdBy: userId,
          ),
        );
    return id;
  }

  /// Crée un entrepôt rattaché à [entrepriseId] côté cloud puis en
  /// miroir local. Autorisé pour `admin_entreprise` ou chef d'un entrepôt
  /// de l'entreprise. Retourne le `cloud_id` créé.
  ///
  /// **Via RPC `create_entrepot` (SECURITY DEFINER)** et NON un INSERT
  /// direct : l'INSERT PostgREST évalue les policies RLS de `entrepots`
  /// (ins + sel pour le RETURNING), qui appellent des helpers relisant
  /// `entreprise_users` dont les policies se relisent → récursion RLS
  /// (Postgres 42P17), même pour un admin. La RPC s'exécute hors RLS et
  /// vérifie les droits elle-même → plus de récursion. Cf bug terrain
  /// 2026-05-31. Même pattern que `accept_entreprise_invitation`.
  Future<String> createEntrepot(
    SupabaseClient client, {
    required String entrepriseId,
    required String nom,
    String? adresse,
    double? lat,
    double? lng,
  }) async {
    final id = _uuid.v4();
    final cleanNom = nom.trim();
    final cleanAdresse =
        (adresse == null || adresse.trim().isEmpty) ? null : adresse.trim();
    try {
      await client.rpc('create_entrepot', params: {
        'p_cloud_id': id,
        'p_entreprise_id': entrepriseId,
        'p_nom': cleanNom,
        'p_adresse': cleanAdresse,
        'p_lat': lat,
        'p_lng': lng,
      });
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec creation entrepot : ${humanizeCloudError(e)}');
    }
    await _db.into(_db.entrepots).insertOnConflictUpdate(
          EntrepotsCompanion.insert(
            cloudId: id,
            entrepriseId: entrepriseId,
            nom: cleanNom,
            adresse: Value(cleanAdresse),
            lat: Value(lat),
            lng: Value(lng),
          ),
        );
    return id;
  }

  // ─── Quitter / Supprimer (carte sortie entreprise, #361) ─────────

  /// L'utilisateur courant **quitte** [entrepriseId] (employé/membre).
  /// RPC `leave_entreprise` (SECURITY DEFINER). L'admin/créateur ne peut
  /// pas quitter (le serveur lève OWNER_CANNOT_LEAVE) → il doit
  /// [deleteEntreprise]. Nettoie aussi le miroir local.
  Future<void> leaveEntreprise(
      SupabaseClient client, String entrepriseId) async {
    try {
      await client.rpc('leave_entreprise',
          params: {'p_entreprise_id': entrepriseId});
    } on Object catch (e) {
      if (e.toString().contains('OWNER_CANNOT_LEAVE')) {
        throw const CloudSyncException(
            'Tu es l\'administrateur : tu ne peux pas quitter ton entreprise, '
            'tu peux seulement la supprimer.');
      }
      throw CloudSyncException(
          'Echec quitter entreprise : ${humanizeCloudError(e)}');
    }
    await _purgeEntrepriseLocale(entrepriseId);
  }

  /// L'admin/créateur **supprime** [entrepriseId] (cascade entrepôts +
  /// adhésions + invitations côté cloud). RPC `delete_entreprise`.
  /// Nettoie aussi le miroir local.
  Future<void> deleteEntreprise(
      SupabaseClient client, String entrepriseId) async {
    try {
      await client.rpc('delete_entreprise',
          params: {'p_entreprise_id': entrepriseId});
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec suppression entreprise : ${humanizeCloudError(e)}');
    }
    await _purgeEntrepriseLocale(entrepriseId);
  }

  /// Retire du miroir local Drift l'entreprise + ses entrepôts (après une
  /// sortie/suppression cloud). Les saved_destinations rattachées ont
  /// `entreprise_id`/`entrepot_id` en `on delete set null` côté cloud ;
  /// en local on remet juste les FK à null pour ne pas perdre l'adresse.
  Future<void> _purgeEntrepriseLocale(String entrepriseId) async {
    await (_db.delete(_db.entrepots)
          ..where((e) => e.entrepriseId.equals(entrepriseId)))
        .go();
    await (_db.delete(_db.entreprises)
          ..where((e) => e.cloudId.equals(entrepriseId)))
        .go();
  }

  // ─── Pull (miroir local des données visibles) ───────────────────

  /// Pull des entreprises + entrepôts visibles par l'utilisateur (la
  /// RLS filtre déjà côté serveur). Sert au cross-device (entreprise
  /// créée sur PC, consultée sur mobile) et à l'employé invité (#367)
  /// qui découvre l'entreprise après acceptation.
  ///
  /// Cloud = source de vérité : on écrase le miroir local (pas de
  /// last-write-wins car #364 n'a pas encore d'édition locale).
  Future<void> pullMine(SupabaseClient client) async {
    await _pullEntreprises(client);
    await _pullEntrepots(client);
  }

  Future<void> _pullEntreprises(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('entreprises').select();
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec fetch entreprises : ${humanizeCloudError(e)}');
    }
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      await _db.into(_db.entreprises).insertOnConflictUpdate(
            EntreprisesCompanion.insert(
              cloudId: row['cloud_id'] as String,
              nom: row['nom'] as String,
              siret: Value(row['siret'] as String?),
              createdBy: row['created_by'] as String,
              creeLe: Value(_parseTs(row['cree_le'])),
              updatedAt: Value(_parseTs(row['updated_at'])),
            ),
          );
    }
  }

  Future<void> _pullEntrepots(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('entrepots').select();
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec fetch entrepots : ${humanizeCloudError(e)}');
    }
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      await _db.into(_db.entrepots).insertOnConflictUpdate(
            EntrepotsCompanion.insert(
              cloudId: row['cloud_id'] as String,
              entrepriseId: row['entreprise_id'] as String,
              nom: row['nom'] as String,
              adresse: Value(row['adresse'] as String?),
              lat: Value((row['lat'] as num?)?.toDouble()),
              lng: Value((row['lng'] as num?)?.toDouble()),
              creeLe: Value(_parseTs(row['cree_le'])),
              updatedAt: Value(_parseTs(row['updated_at'])),
            ),
          );
    }
  }

  /// Parse un timestamp cloud (ISO 8601) en [DateTime] UTC. Tolère le
  /// null (retombe sur maintenant) même si la colonne est `not null`
  /// côté serveur — robustesse défensive au parsing.
  DateTime _parseTs(Object? v) =>
      v == null ? DateTime.now().toUtc() : DateTime.parse(v as String).toUtc();
}
