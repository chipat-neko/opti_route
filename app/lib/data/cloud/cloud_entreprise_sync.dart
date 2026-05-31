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
  Future<String> createEntreprise(
    SupabaseClient client,
    String userId, {
    required String nom,
    String? siret,
  }) async {
    final id = _uuid.v4();
    final cleanNom = nom.trim();
    final cleanSiret =
        (siret == null || siret.trim().isEmpty) ? null : siret.trim();
    final row = <String, dynamic>{
      'cloud_id': id,
      'nom': cleanNom,
      'created_by': userId,
    };
    if (cleanSiret != null) row['siret'] = cleanSiret;
    try {
      await client.from('entreprises').insert(row);
    } on Object catch (e) {
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
  /// miroir local. Autorisé pour `admin_entreprise` ou `chef_entrepot`
  /// (policy `ins_entrepots`). Retourne le `cloud_id` créé.
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
    final row = <String, dynamic>{
      'cloud_id': id,
      'entreprise_id': entrepriseId,
      'nom': cleanNom,
    };
    if (cleanAdresse != null) row['adresse'] = cleanAdresse;
    if (lat != null) row['lat'] = lat;
    if (lng != null) row['lng'] = lng;
    try {
      await client.from('entrepots').insert(row);
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
