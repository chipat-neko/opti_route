import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../cloud_error_humanizer.dart';
import '../cloud_sync_types.dart';
import '../database.dart';
import 'cloud_sync_helpers.dart';

/// ════════════════════════════════════════════════════════════════
/// Sync du carnet d'adresses (saved_destinations) vers/depuis Supabase.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `cloud_sync_service.dart` (carte Trello #167, etape 2).
/// Le carnet est le domaine de sync le plus INDEPENDANT : pas de FK
/// cross-tables (contrairement a stops -> tournees -> coequipiers),
/// donc extractable sans toucher a l'ordre des operations du pull
/// global.
///
/// Le [SupabaseClient] et le `userId` sont passes en parametre par le
/// caller ([CloudSyncService]) qui possede les guards `_client()` +
/// `_requireUserId()`. Ca evite de dupliquer la logique d'auth ici.
///
/// Pattern idempotent (identique au push tournee) : cloud_id null ->
/// generer UUID + INSERT + persister localement ; cloud_id set ->
/// UPDATE. Last-write-wins au pull via [cloudIsNewer].
class CloudCarnetSync {
  CloudCarnetSync(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Push toutes les entrees locales du carnet vers Supabase (bug
  /// Trello #68 : avant ce fix, seul le pull existait).
  ///
  /// Best-effort par row : si une row echoue (RLS, conflit, etc.),
  /// on log et on continue avec les suivantes plutot que de tout
  /// arreter.
  Future<void> pushAll(SupabaseClient client, String userId) async {
    final locals = await _db.select(_db.savedDestinations).get();
    for (final s in locals) {
      try {
        await _pushRow(client, s, userId);
      } on Object catch (e) {
        // PII (nom/adresse client) : debug uniquement, pas en release (#178).
        if (kDebugMode) {
          debugPrint(
            '[CloudCarnetSync] Push "${s.nomClient ?? s.adresseDisplay}" '
            'echec : $e',
          );
        }
        // Continue avec les autres rows.
      }
    }
  }

  /// Push d'une seule entree identifiee par son id local. Sert au
  /// carnet partage entre coequipiers (carte Trello #57). No-op si la
  /// row n'existe pas (deja supprimee).
  Future<void> pushOne(
    SupabaseClient client,
    String userId,
    int localId,
  ) async {
    final row = await (_db.select(_db.savedDestinations)
          ..where((d) => d.id.equals(localId)))
        .getSingleOrNull();
    if (row == null) return;
    await _pushRow(client, row, userId);
  }

  /// User_id envoye uniquement au 1er push (cf pattern coequipier).
  /// Pas de push de la colonne `photo_path` (chemin local du device
  /// source, pas valide ailleurs).
  Future<void> _pushRow(
    SupabaseClient client,
    SavedDestination s,
    String userId,
  ) async {
    final cloudId = s.cloudId ?? _uuid.v4();
    final isFirstPush = s.cloudId == null;
    final row = <String, dynamic>{
      'id': cloudId,
      if (isFirstPush) 'user_id': userId,
      'nom_client': s.nomClient,
      'adresse_display': s.adresseDisplay,
      'lat': s.lat,
      'lng': s.lng,
      'rue': s.rue,
      'code_postal': s.codePostal,
      'ville': s.ville,
      'use_count': s.useCount,
      'last_used_at': s.lastUsedAt.toIso8601String(),
      if (isFirstPush) 'cree_le': s.creeLe.toIso8601String(),
      'is_favori': s.isFavori,
      'color_tag': s.colorTag,
      'notes_carnet': s.notesCarnet,
      'tags_json': s.tagsJson,
      // photo_path : volontairement non push (chemin local du device).
      'code_acces': s.codeAcces,
      'etage_batiment': s.etageBatiment,
      // Portee carnet partage (carte #365) : null/null = adresse perso ;
      // entreprise_id seul = mutualise entreprise ; +entrepot_id = carnet
      // entrepot. La RLS cote cloud filtre la visibilite au pull.
      'entreprise_id': s.entrepriseId,
      'entrepot_id': s.entrepotId,
      'updated_at': s.updatedAt.toUtc().toIso8601String(),
    };
    if (isFirstPush) {
      await client.from('saved_destinations').insert(row);
      await (_db.update(_db.savedDestinations)
            ..where((r) => r.id.equals(s.id)))
          .write(SavedDestinationsCompanion(cloudId: Value(cloudId)));
    } else {
      await client.from('saved_destinations').update(row).eq('id', cloudId);
    }
  }

  /// Pull last-write-wins depuis Supabase. La RLS filtre deja les rows
  /// visibles par l'utilisateur (pas besoin de filtrer cote client).
  Future<CloudPullStats> pull(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('saved_destinations').select();
    } on Object catch (e) {
      throw CloudSyncException(
          'Echec fetch carnet : ${humanizeCloudError(e)}');
    }
    int inserted = 0, updated = 0, skipped = 0;
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.savedDestinations)
            ..where((s) => s.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
        skipped++;
        continue;
      }
      final companion = SavedDestinationsCompanion(
        nomClient: Value(row['nom_client'] as String?),
        adresseDisplay: Value(row['adresse_display'] as String),
        lat: Value((row['lat'] as num).toDouble()),
        lng: Value((row['lng'] as num).toDouble()),
        rue: Value(row['rue'] as String?),
        codePostal: Value(row['code_postal'] as String?),
        ville: Value(row['ville'] as String?),
        useCount: Value(row['use_count'] as int? ?? 1),
        lastUsedAt: Value(DateTime.parse(row['last_used_at'] as String)),
        creeLe: Value(DateTime.parse(row['cree_le'] as String)),
        isFavori: Value(row['is_favori'] as bool? ?? false),
        colorTag: Value(row['color_tag'] as String?),
        notesCarnet: Value(row['notes_carnet'] as String?),
        tagsJson: Value(row['tags_json'] as String?),
        photoPath: Value(row['photo_path'] as String?),
        codeAcces: Value(row['code_acces'] as String?),
        etageBatiment: Value(row['etage_batiment'] as String?),
        // Portee carnet partage (carte #365). Cloud = source de verite.
        entrepriseId: Value(row['entreprise_id'] as String?),
        entrepotId: Value(row['entrepot_id'] as String?),
        cloudId: Value(cloudId),
        updatedAt: Value(cloudUpdatedAt),
      );
      if (localRow == null) {
        await _db.into(_db.savedDestinations).insert(companion);
        inserted++;
      } else {
        await (_db.update(_db.savedDestinations)
              ..where((s) => s.id.equals(localRow.id)))
            .write(companion);
        updated++;
      }
    }
    return CloudPullStats(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }
}
