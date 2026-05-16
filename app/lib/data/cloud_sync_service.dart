import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'supabase_service.dart';

/// ════════════════════════════════════════════════════════════════
/// Service de sync local → cloud (Phase 2 backend, sous-jalon 2.B).
/// ════════════════════════════════════════════════════════════════
///
/// **Granularite** : push d'une tournee a la fois, avec ses dependances
/// (coequipiers references + stops). Pas de push global "tout d'un
/// coup" — opaque, lent, dur a debugger. Une UI ulterieure (2.C) pourra
/// itererer sur la liste si besoin.
///
/// **Idempotence** : chaque entite locale a une colonne `cloud_id`
/// nullable. Null = jamais sync ; set = UUID v4 cote cloud.
/// L'algorithme du push :
///   - si `cloud_id` est null  → genere UUID, INSERT cote Supabase,
///                                persiste l'UUID en local.
///   - si `cloud_id` est set   → UPDATE (upsert sur la PK) cote
///                                Supabase. Pas de re-ecriture du
///                                local.
/// Ca rend les retries safes : un retry partiel ne casse rien et
/// rattrape ce qui n'a pas encore ete sync.
///
/// **Strategie de conflit** : pour ce sous-jalon, c'est last-write-wins
/// implicite (le client ecrase ce que le serveur a). Pas de detection
/// de modif concurrente : on assume qu'un seul appareil pousse a la
/// fois (Noah perso). Le sous-jalon 2.D introduira un mecanisme de
/// pull + merge plus robuste pour le mode multi-appareils.
///
/// **Pas de transaction reseau** : on enchaine N appels HTTP. Si l'un
/// echoue a mi-chemin, certaines entites ont un cloud_id, d'autres non.
/// C'est OK : un retry rattrapera. Les writes locaux (persist du
/// cloud_id) sont eux fait apres reussite Supabase, donc on ne se
/// retrouve jamais avec un cloud_id local sans avoir reussi le push
/// correspondant.
///
/// **Erreurs** : toutes les methodes publiques throw [CloudSyncException]
/// avec un message FR explicite. L'UI affiche ca dans une SnackBar.
///
/// **Tests** : passer un `SupabaseClient` explicite au constructeur
/// pour pouvoir mocker. En prod, [client] est `Supabase.instance.client`.
class CloudSyncService {
  CloudSyncService(
    this._db,
    this._supabase, {
    SupabaseClient? client,
  }) : _explicitClient = client;

  final AppDatabase _db;
  final SupabaseService _supabase;
  final SupabaseClient? _explicitClient;

  static const _uuid = Uuid();

  /// Pousse une tournee + ses stops + les coequipiers references vers
  /// le cloud Supabase. Idempotent (re-jouable sans casse).
  ///
  /// Throws [CloudSyncException] si :
  /// - Cloud non configure (build sans `--dart-define=SUPABASE_URL`)
  /// - Pas connecte (pas de session Supabase active)
  /// - Tournee locale introuvable
  /// - Erreur reseau ou rejet RLS Postgres
  Future<void> pushTournee(int localTourneeId) async {
    final client = _client();
    final userId = _requireUserId();

    // 1. Charger l'etat local complet.
    final tournee = await (_db.select(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .getSingleOrNull();
    if (tournee == null) {
      throw CloudSyncException(
        'Tournee introuvable en local (id=$localTourneeId).',
      );
    }
    final stops = await (_db.select(_db.stops)
          ..where((s) => s.tourneeId.equals(localTourneeId)))
        .get();

    // Les coequipiers references = celui par defaut de la tournee +
    // ceux affectes a chaque stop. On dedup via un Set<int>.
    final coequipierLocalIds = <int>{
      if (tournee.coequipierDefautId != null) tournee.coequipierDefautId!,
      for (final s in stops)
        if (s.coequipierId != null) s.coequipierId!,
    };
    final coequipiers = coequipierLocalIds.isEmpty
        ? <Coequipier>[]
        : await (_db.select(_db.coequipiers)
              ..where((c) => c.id.isIn(coequipierLocalIds)))
            .get();

    // 2. Push les coequipiers et collecter local_id → cloud_uuid pour
    // pouvoir resoudre les FK lors du push de la tournee/stops.
    final coequipierCloudIds = <int, String>{};
    for (final c in coequipiers) {
      final cloudId = await _pushCoequipier(client, c, userId);
      coequipierCloudIds[c.id] = cloudId;
    }

    // 3. Push la tournee elle-meme.
    final tourneeCloudId =
        await _pushTournee(client, tournee, userId, coequipierCloudIds);

    // 4. Push les stops un a un (avec FK resolves vers tournee + coeq).
    for (final s in stops) {
      await _pushStop(client, s, userId, tourneeCloudId, coequipierCloudIds);
    }
  }

  // ─── Push d'une entite individuelle ─────────────────────────────

  Future<String> _pushCoequipier(
    SupabaseClient client,
    Coequipier c,
    String userId,
  ) async {
    final cloudId = c.cloudId ?? _uuid.v4();
    final row = <String, dynamic>{
      'id': cloudId,
      'user_id': userId,
      'nom': c.nom,
      'color_tag': c.colorTag,
      'telephone': c.telephone,
      'actif': c.actif,
      // Pas de `cree_le` cote cloud pour les coequipiers : la table
      // Postgres n'a que `created_at` (gere auto par defaut). Volontaire.
    };
    try {
      await client.from('coequipiers').upsert(row);
    } on Object catch (e) {
      throw CloudSyncException('Echec push coequipier "${c.nom}" : $e');
    }
    if (c.cloudId == null) {
      await (_db.update(_db.coequipiers)..where((row) => row.id.equals(c.id)))
          .write(CoequipiersCompanion(cloudId: Value(cloudId)));
    }
    return cloudId;
  }

  Future<String> _pushTournee(
    SupabaseClient client,
    Tournee t,
    String userId,
    Map<int, String> coequipierCloudIds,
  ) async {
    final cloudId = t.cloudId ?? _uuid.v4();
    final row = <String, dynamic>{
      'id': cloudId,
      'user_id': userId,
      'nom': t.nom,
      'date': t.date.toIso8601String(),
      'point_depart_lat': t.pointDepartLat,
      'point_depart_lng': t.pointDepartLng,
      'point_depart_label': t.pointDepartLabel,
      'vehicule_capacite_colis': t.vehiculeCapaciteColis,
      'statut': t.statut,
      'distance_totale_m': t.distanceTotaleM,
      'duree_totale_s': t.dureeTotaleS,
      'optimisee_le': t.optimiseeLe?.toIso8601String(),
      'trace_geojson': t.traceGeojson,
      'demaree_le': t.demareeLe?.toIso8601String(),
      'is_template': t.isTemplate,
      'profil_ors': t.profilOrs,
      'eviter_peages': t.eviterPeages,
      'rappel_le': t.rappelLe?.toIso8601String(),
      'pausee_le': t.pauseeLe?.toIso8601String(),
      'pausee_seconds': t.pauseeSeconds,
      'coequipier_defaut_id': t.coequipierDefautId == null
          ? null
          : coequipierCloudIds[t.coequipierDefautId!],
      'cree_le': t.creeLe.toIso8601String(),
    };
    try {
      await client.from('tournees').upsert(row);
    } on Object catch (e) {
      throw CloudSyncException('Echec push tournee "${t.nom}" : $e');
    }
    if (t.cloudId == null) {
      await (_db.update(_db.tournees)..where((row) => row.id.equals(t.id)))
          .write(TourneesCompanion(cloudId: Value(cloudId)));
    }
    return cloudId;
  }

  Future<String> _pushStop(
    SupabaseClient client,
    Stop s,
    String userId,
    String tourneeCloudId,
    Map<int, String> coequipierCloudIds,
  ) async {
    final cloudId = s.cloudId ?? _uuid.v4();
    final row = <String, dynamic>{
      'id': cloudId,
      'user_id': userId,
      'tournee_id': tourneeCloudId,
      'adresse_brute': s.adresseBrute,
      'adresse_normalisee': s.adresseNormalisee,
      'lat': s.lat,
      'lng': s.lng,
      'nb_colis': s.nbColis,
      'priorite': s.priorite,
      'fenetre_debut': s.fenetreDebut,
      'fenetre_fin': s.fenetreFin,
      'duree_arret_min': s.dureeArretMin,
      'notes': s.notes,
      'nom_client': s.nomClient,
      'statut_livraison': s.statutLivraison,
      'raison_echec': s.raisonEchec,
      'livre_lat': s.livreLat,
      'livre_lng': s.livreLng,
      'livre_le': s.livreLe?.toIso8601String(),
      'ordre_optimise': s.ordreOptimise,
      'ordre_priorite': s.ordrePriorite,
      'preuve_photo_path': s.preuvePhotoPath,
      'coequipier_id': s.coequipierId == null
          ? null
          : coequipierCloudIds[s.coequipierId!],
      'cree_le': s.creeLe.toIso8601String(),
    };
    try {
      await client.from('stops').upsert(row);
    } on Object catch (e) {
      throw CloudSyncException(
        'Echec push stop "${s.adresseBrute}" : $e',
      );
    }
    if (s.cloudId == null) {
      await (_db.update(_db.stops)..where((row) => row.id.equals(s.id)))
          .write(StopsCompanion(cloudId: Value(cloudId)));
    }
    return cloudId;
  }

  // ─── Guards ─────────────────────────────────────────────────────

  SupabaseClient _client() {
    final explicit = _explicitClient;
    if (explicit != null) return explicit;
    if (!_supabase.isConfigured) {
      throw const CloudSyncException(
        'Cloud non disponible sur cette build de l\'app.',
      );
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw const CloudSyncException(
        'Service cloud non initialise (relance l\'app).',
      );
    }
  }

  String _requireUserId() {
    final user = _supabase.currentUser;
    if (user == null) {
      throw const CloudSyncException(
        'Connecte ton compte cloud d\'abord '
        '(Parametres → Compte cloud).',
      );
    }
    return user.id;
  }
}

/// Exception type-safe pour les erreurs de sync. Le message est FR et
/// destine a l'affichage utilisateur (SnackBar).
class CloudSyncException implements Exception {
  const CloudSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}
