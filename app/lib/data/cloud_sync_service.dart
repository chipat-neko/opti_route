import 'dart:io';
import 'dart:math' show Random;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path_provider/path_provider.dart';
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
    final isFirstPush = c.cloudId == null;
    final row = <String, dynamic>{
      'id': cloudId,
      // user_id : envoye SEULEMENT au 1er push (INSERT). Pour les UPDATE
      // ulterieurs, ne PAS le renvoyer — sinon un member d'une tournee
      // partagee qui re-push un row pourrait ecraser le user_id original
      // par le sien et voler la propriete. Cf fix bugs jalons 2.D-1c->3.A.
      if (isFirstPush) 'user_id': userId,
      'nom': c.nom,
      'color_tag': c.colorTag,
      'telephone': c.telephone,
      'actif': c.actif,
      'updated_at': c.updatedAt.toUtc().toIso8601String(),
    };
    try {
      if (isFirstPush) {
        await client.from('coequipiers').insert(row);
      } else {
        await client.from('coequipiers').update(row).eq('id', cloudId);
      }
    } on Object catch (e) {
      throw CloudSyncException('Echec push coequipier "${c.nom}" : $e');
    }
    if (isFirstPush) {
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
    final isFirstPush = t.cloudId == null;
    final row = <String, dynamic>{
      'id': cloudId,
      // user_id : envoye SEULEMENT au 1er push. Cf _pushCoequipier.
      if (isFirstPush) 'user_id': userId,
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
      // cree_le envoye seulement au 1er push (cote cloud DEFAULT now()
      // peut donner une date legerement differente sinon).
      if (isFirstPush) 'cree_le': t.creeLe.toIso8601String(),
      'updated_at': t.updatedAt.toUtc().toIso8601String(),
    };
    try {
      if (isFirstPush) {
        await client.from('tournees').insert(row);
      } else {
        await client.from('tournees').update(row).eq('id', cloudId);
      }
    } on Object catch (e) {
      throw CloudSyncException('Echec push tournee "${t.nom}" : $e');
    }
    if (isFirstPush) {
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
    // Sous-jalon 2.E : upload de la photo preuve vers Supabase Storage
    // AVANT l'upsert du row (pour pouvoir mettre le bucketPath dans la
    // colonne cloud_photo_path). Silencieux en cas d'echec : le push
    // du row reussit quand meme. Re-tenter au prochain push.
    final cloudPhotoPath = await _maybeUploadPhoto(
      client: client,
      s: s,
      userId: userId,
      stopCloudId: cloudId,
    );
    final isFirstPush = s.cloudId == null;
    final row = <String, dynamic>{
      'id': cloudId,
      // user_id : envoye SEULEMENT au 1er push. Cf _pushCoequipier.
      if (isFirstPush) 'user_id': userId,
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
      'cloud_photo_path': cloudPhotoPath ?? s.cloudPhotoPath,
      'coequipier_id': s.coequipierId == null
          ? null
          : coequipierCloudIds[s.coequipierId!],
      if (isFirstPush) 'cree_le': s.creeLe.toIso8601String(),
      'updated_at': s.updatedAt.toUtc().toIso8601String(),
    };
    try {
      if (isFirstPush) {
        await client.from('stops').insert(row);
      } else {
        await client.from('stops').update(row).eq('id', cloudId);
      }
    } on Object catch (e) {
      throw CloudSyncException(
        'Echec push stop "${s.adresseBrute}" : $e',
      );
    }
    // Persist en local : cloudId (1er push) et/ou cloudPhotoPath
    // (nouvel upload Storage reussi).
    final needsCloudId = isFirstPush;
    final needsCloudPhotoPath =
        cloudPhotoPath != null && cloudPhotoPath != s.cloudPhotoPath;
    if (needsCloudId || needsCloudPhotoPath) {
      final companion = StopsCompanion(
        cloudId: needsCloudId ? Value(cloudId) : const Value.absent(),
        cloudPhotoPath: needsCloudPhotoPath
            ? Value(cloudPhotoPath)
            : const Value.absent(),
      );
      await (_db.update(_db.stops)..where((row) => row.id.equals(s.id)))
          .write(companion);
    }
    return cloudId;
  }

  /// Upload la photo preuve d'un stop vers Supabase Storage (bucket
  /// `preuves`, chemin `<userId>/<stopCloudId>.jpg`). Retourne le
  /// bucketPath en cas de succes (a stocker dans `cloud_photo_path`
  /// du row cloud + local), ou null si rien a upload / web / echec.
  ///
  /// **Silencieux** : log via debugPrint mais ne throw pas — l'echec
  /// d'upload ne doit pas bloquer le push principal du row stop. Au
  /// prochain push, on re-tentera l'upload (idempotent grace a
  /// `upsert: true` dans FileOptions, qui remplace le fichier
  /// existant). Cas particuliers gardes silencieux :
  /// - Pas de photo locale (`preuvePhotoPath` null) : no-op
  /// - Web (kIsWeb true) : pas de filesystem -> no-op
  /// - Fichier introuvable (path obsolete, fichier supprime) : no-op
  /// - Bucket Supabase inexistant ou RLS deny : silent (Noah n'a
  ///   peut-etre pas encore execute le SQL bucket creation, cf
  ///   docs/supabase-schema.sql)
  Future<String?> _maybeUploadPhoto({
    required SupabaseClient client,
    required Stop s,
    required String userId,
    required String stopCloudId,
  }) async {
    final localPath = s.preuvePhotoPath;
    if (localPath == null) return null;
    if (kIsWeb) return null;
    final file = File(localPath);
    if (!await file.exists()) return null;

    final bucketPath = '$userId/$stopCloudId.jpg';
    try {
      await client.storage.from('preuves').upload(
            bucketPath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return bucketPath;
    } on Object catch (e) {
      debugPrint('[CloudSyncService] Upload photo preuve echec : $e');
      return null;
    }
  }

  /// Telecharge la photo preuve depuis Supabase Storage vers le
  /// filesystem local et renvoie le chemin local final a stocker dans
  /// `Stops.preuvePhotoPath`. Sous-jalon 2.E-2.
  ///
  /// Logique :
  /// - Si [existingLocalPath] existe et pointe vers un fichier present
  ///   -> on garde tel quel (no-op, jamais ecraser une photo locale par
  ///   la version cloud)
  /// - Si [cloudPhotoPath] est null -> rien a download, retourne
  ///   [existingLocalPath] (qui peut etre null)
  /// - Sinon -> download dans `app_documents/preuves/cloud_$stopCloudId.jpg`
  ///   et retourne ce chemin
  ///
  /// **Silencieux** en cas d'echec (web, RLS deny, fichier absent du
  /// bucket, I/O, etc) — retourne [existingLocalPath] (souvent null).
  /// Idempotent : si le fichier local existe deja (download precedent),
  /// retourne son chemin sans re-download. Au prochain pull, re-tente.
  Future<String?> _maybeDownloadPhoto({
    required SupabaseClient client,
    required String? cloudPhotoPath,
    required String? existingLocalPath,
    required String stopCloudId,
  }) async {
    if (cloudPhotoPath == null) return existingLocalPath;
    if (kIsWeb) return existingLocalPath;
    if (existingLocalPath != null && await File(existingLocalPath).exists()) {
      return existingLocalPath;
    }
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final preuvesDir = Directory('${baseDir.path}/preuves');
      if (!await preuvesDir.exists()) {
        await preuvesDir.create(recursive: true);
      }
      final localPath = '${preuvesDir.path}/cloud_$stopCloudId.jpg';
      final localFile = File(localPath);
      // Si on a deja telecharge precedemment (meme stop, run anterieur),
      // re-utiliser sans round-trip Storage (gain bandwidth + speed).
      if (await localFile.exists()) {
        return localPath;
      }
      final bytes = await client.storage.from('preuves').download(cloudPhotoPath);
      await localFile.writeAsBytes(bytes);
      return localPath;
    } on Object catch (e) {
      debugPrint('[CloudSyncService] Download photo preuve echec : $e');
      return existingLocalPath;
    }
  }

  // ─── Pull cloud → local (sous-jalon 2.D-1a) ─────────────────────

  /// Fetch toutes les donnees du user courant depuis Supabase et les
  /// merge en local. Sert au mode multi-appareils :
  /// - 1er install sur un 2e phone -> recupere toutes les tournees
  /// - Restauration apres perte/reset du telephone
  /// - "Resync depuis le cloud" manuel si l'utilisateur veut forcer
  ///
  /// **Strategie de merge (last-write-wins via updated_at, 2.D-1c)** :
  /// - Row local sans `cloud_id` matchant : INSERT.
  /// - Row local avec `cloud_id` matchant :
  ///   - Si `cloud.updated_at > local.updated_at` -> UPDATE (cloud ecrase
  ///     local, le timestamp source est preserve dans `updatedAt`).
  ///   - Sinon (cloud <= local) -> SKIP (local plus recent ou egal, on
  ///     conserve les modifs locales offline non encore push).
  ///
  /// Le `>` strict signifie qu'a egalite, on skip — evite les rewrites
  /// inutiles. Le trigger SQLite `AFTER UPDATE` n'est pas declenche
  /// lors du write au pull (on touche explicitement la colonne
  /// `updated_at` avec le timestamp cloud, donc NEW != OLD est faux
  /// uniquement quand `cloud.updated_at == local.updated_at`).
  ///
  /// **Ordre des fetch** : coequipiers d'abord (referenced par tournees
  /// et stops), puis tournees (referenced par stops), puis stops, puis
  /// saved_destinations (independant).
  ///
  /// **Idempotent** : re-pull = no-op si rien n'a change cote cloud.
  /// Pas de duplication grace au match par `cloud_id`.
  ///
  /// Throws [CloudSyncException] si pas configure, pas auth ou erreur
  /// reseau / RLS.
  Future<CloudPullResult> pullAllForCurrentUser() async {
    final client = _client();
    _requireUserId();
    // Pas besoin de filtrer par user_id dans les selects : la RLS
    // Supabase fait deja le filtrage (chaque select retourne uniquement
    // les rows ou user_id = auth.uid()).
    final coequipiers = await _pullCoequipiers(client);
    final tournees = await _pullTournees(client);
    final stops = await _pullStops(client);
    final savedDestinations = await _pullSavedDestinations(client);
    // Jalon 3.A : adhesions aux tournees partagees (qui voit quoi).
    // Apres les tournees pour que les rows membres aient bien une
    // tournee_cloud_id correspondant a un row tournees deja pulle.
    await _pullTourneeMembres(client);
    return CloudPullResult(
      coequipiers: coequipiers,
      tournees: tournees,
      stops: stops,
      savedDestinations: savedDestinations,
    );
  }

  // ─── Mode équipe live (jalon 3.A) ───────────────────────────────

  /// Crée une invitation à 6 chiffres pour la tournée locale donnée.
  /// La tournée doit déjà avoir un `cloudId` (= pushée au moins une
  /// fois). Retourne le code à afficher / partager à Lucas.
  ///
  /// Throws [CloudSyncException] si :
  /// - Tournée locale introuvable
  /// - Tournée jamais pushée au cloud (pas de cloudId)
  /// - User non auth
  /// - Code généré collisionne (rare : 1 chance sur 900_000 par essai,
  ///   on retry une seconde fois max)
  Future<String> createInvitation(int localTourneeId) async {
    final client = _client();
    final userId = _requireUserId();
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
      final code = _generateInvitationCode();
      try {
        await client.from('tournee_invitations').insert({
          'code': code,
          'tournee_id': cloudId,
          'created_by': userId,
        });
        return code;
      } on Object catch (e) {
        if (attempt == 1) {
          throw CloudSyncException('Echec creation invitation : $e');
        }
      }
    }
    throw const CloudSyncException('Echec creation invitation (collision).');
  }

  /// Lucas saisit le code à 6 chiffres → appel RPC `accept_invitation`
  /// qui valide + insère le row membre + marque le code utilisé.
  /// Retourne le cloud UUID de la tournée rejointe. Le caller doit
  /// ensuite déclencher un pull pour récupérer la tournée + stops en
  /// local.
  ///
  /// Throws [CloudSyncException] avec un message FR explicite si :
  /// - Code inconnu / mal formé
  /// - Code expiré (> 24h)
  /// - Code déjà utilisé par quelqu'un d'autre
  /// - User non auth
  Future<String> acceptInvitation(String code) async {
    final client = _client();
    _requireUserId();
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
      throw CloudSyncException(_invitationErrorToFr(e.message));
    } on Object catch (e) {
      throw CloudSyncException('Echec acceptation invitation : $e');
    }
  }

  /// Pull la table cloud `tournee_membres` et remplace intégralement le
  /// cache local (`replace-all` plutôt que merge : la liste est append-
  /// only côté cloud, et un DELETE cloud doit se refléter en local —
  /// le diff serait plus complexe que de tout réécrire).
  Future<void> _pullTourneeMembres(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('tournee_membres').select();
    } on Object catch (e) {
      throw CloudSyncException('Echec fetch tournee_membres : $e');
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

  static final _invitationRandom = Random.secure();

  String _generateInvitationCode() {
    // 6 chiffres aleatoires uniformes (000000-999999) via Random.secure
    // (CSPRNG). Le formatage garde les leading zeros : 47 -> "000047".
    //
    // Cf fix bugs jalons 2.D-1c->3.A : l'ancienne implementation basee
    // sur DateTime.now() XOR DateTime.now() renvoyait quasi-toujours 0
    // (les 2 timestamps sont presque identiques), et le retry collision
    // generait le meme code (microsecondes d'ecart).
    final n = _invitationRandom.nextInt(1000000);
    return n.toString().padLeft(6, '0');
  }

  String _invitationErrorToFr(String raw) {
    if (raw.contains('AUTH_REQUIRED')) {
      return 'Connecte-toi d\'abord (Parametres > Compte cloud).';
    }
    if (raw.contains('CODE_INTROUVABLE')) {
      return 'Ce code n\'existe pas. Verifie avec ton chef.';
    }
    if (raw.contains('CODE_EXPIRE')) {
      return 'Ce code a expire (plus de 24h). Demande un nouveau code.';
    }
    if (raw.contains('CODE_DEJA_UTILISE')) {
      return 'Ce code a deja ete utilise. Demande un nouveau code.';
    }
    return 'Echec acceptation invitation : $raw';
  }

  Future<CloudPullStats> _pullCoequipiers(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('coequipiers').select();
    } on Object catch (e) {
      throw CloudSyncException('Echec fetch coequipiers : $e');
    }
    int inserted = 0, updated = 0, skipped = 0;
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = _parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.coequipiers)
            ..where((c) => c.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !_cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
        skipped++;
        continue;
      }
      final companion = CoequipiersCompanion(
        nom: Value(row['nom'] as String),
        colorTag: Value(row['color_tag'] as String?),
        telephone: Value(row['telephone'] as String?),
        actif: Value(row['actif'] as bool? ?? true),
        cloudId: Value(cloudId),
        updatedAt: Value(cloudUpdatedAt),
      );
      if (localRow == null) {
        await _db.into(_db.coequipiers).insert(companion);
        inserted++;
      } else {
        await (_db.update(_db.coequipiers)
              ..where((c) => c.id.equals(localRow.id)))
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

  Future<CloudPullStats> _pullTournees(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('tournees').select();
    } on Object catch (e) {
      throw CloudSyncException('Echec fetch tournees : $e');
    }
    int inserted = 0, updated = 0, skipped = 0;
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = _parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.tournees)
            ..where((t) => t.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !_cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
        skipped++;
        continue;
      }
      final coequipierCloudId = row['coequipier_defaut_id'] as String?;
      // Resoud le coequipier_defaut_id cloud (UUID) -> id local (int).
      // Si pas trouve, on garde null (le coequipier referenced n'a
      // peut-etre pas encore ete pull, ce qui est anormal vu l'ordre,
      // ou il a ete supprime du cloud).
      final coequipierLocalId = coequipierCloudId == null
          ? null
          : await (_db.select(_db.coequipiers)
                ..where((c) => c.cloudId.equals(coequipierCloudId)))
              .map((c) => c.id)
              .getSingleOrNull();
      final companion = TourneesCompanion(
        nom: Value(row['nom'] as String),
        date: Value(DateTime.parse(row['date'] as String)),
        pointDepartLat: Value((row['point_depart_lat'] as num).toDouble()),
        pointDepartLng: Value((row['point_depart_lng'] as num).toDouble()),
        pointDepartLabel: Value(row['point_depart_label'] as String),
        vehiculeCapaciteColis:
            Value(row['vehicule_capacite_colis'] as int? ?? 0),
        statut: Value(row['statut'] as String? ?? 'brouillon'),
        distanceTotaleM: Value(row['distance_totale_m'] as int?),
        dureeTotaleS: Value(row['duree_totale_s'] as int?),
        optimiseeLe: Value(row['optimisee_le'] == null
            ? null
            : DateTime.parse(row['optimisee_le'] as String)),
        traceGeojson: Value(row['trace_geojson'] as String?),
        demareeLe: Value(row['demaree_le'] == null
            ? null
            : DateTime.parse(row['demaree_le'] as String)),
        isTemplate: Value(row['is_template'] as bool? ?? false),
        profilOrs: Value(row['profil_ors'] as String? ?? 'driving-car'),
        eviterPeages: Value(row['eviter_peages'] as bool? ?? false),
        rappelLe: Value(row['rappel_le'] == null
            ? null
            : DateTime.parse(row['rappel_le'] as String)),
        pauseeLe: Value(row['pausee_le'] == null
            ? null
            : DateTime.parse(row['pausee_le'] as String)),
        pauseeSeconds: Value(row['pausee_seconds'] as int? ?? 0),
        coequipierDefautId: Value(coequipierLocalId),
        creeLe: Value(DateTime.parse(row['cree_le'] as String)),
        cloudId: Value(cloudId),
        updatedAt: Value(cloudUpdatedAt),
      );
      if (localRow == null) {
        await _db.into(_db.tournees).insert(companion);
        inserted++;
      } else {
        await (_db.update(_db.tournees)
              ..where((t) => t.id.equals(localRow.id)))
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

  Future<CloudPullStats> _pullStops(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('stops').select();
    } on Object catch (e) {
      throw CloudSyncException('Echec fetch stops : $e');
    }
    int inserted = 0, updated = 0, skipped = 0;
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = _parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.stops)
            ..where((s) => s.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !_cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
        skipped++;
        continue;
      }
      final tourneeCloudId = row['tournee_id'] as String;
      final tourneeLocalId = await (_db.select(_db.tournees)
            ..where((t) => t.cloudId.equals(tourneeCloudId)))
          .map((t) => t.id)
          .getSingleOrNull();
      if (tourneeLocalId == null) {
        // Orphan : la tournee parent n'a pas ete trouvee localement.
        // On skip plutot que de crasher. Peut arriver si la tournee
        // a ete supprimee du cloud entre le fetch tournees et le
        // fetch stops, ou si la RLS la cache (ne devrait pas).
        continue;
      }
      final coequipierCloudId = row['coequipier_id'] as String?;
      final coequipierLocalId = coequipierCloudId == null
          ? null
          : await (_db.select(_db.coequipiers)
                ..where((c) => c.cloudId.equals(coequipierCloudId)))
              .map((c) => c.id)
              .getSingleOrNull();
      // Sous-jalon 2.E-2 : si le row cloud a une photo preuve uploadee
      // (cloud_photo_path != null) ET qu'on n'a pas deja un fichier
      // local pour ce stop, on telecharge depuis Storage. Sert au cas
      // multi-appareils : install sur un 2e telephone, sign-in, la photo
      // preuve d'une livraison faite sur l'autre device est restauree.
      final cloudPhotoPath = row['cloud_photo_path'] as String?;
      final existingLocalPath =
          localRow?.preuvePhotoPath ?? row['preuve_photo_path'] as String?;
      final resolvedLocalPath = await _maybeDownloadPhoto(
        client: client,
        cloudPhotoPath: cloudPhotoPath,
        existingLocalPath: existingLocalPath,
        stopCloudId: cloudId,
      );
      final companion = StopsCompanion(
        tourneeId: Value(tourneeLocalId),
        adresseBrute: Value(row['adresse_brute'] as String),
        adresseNormalisee: Value(row['adresse_normalisee'] as String?),
        lat: Value((row['lat'] as num?)?.toDouble()),
        lng: Value((row['lng'] as num?)?.toDouble()),
        nbColis: Value(row['nb_colis'] as int? ?? 1),
        priorite: Value(row['priorite'] as String? ?? 'flexible'),
        fenetreDebut: Value(row['fenetre_debut'] as String?),
        fenetreFin: Value(row['fenetre_fin'] as String?),
        dureeArretMin: Value(row['duree_arret_min'] as int? ?? 3),
        notes: Value(row['notes'] as String?),
        nomClient: Value(row['nom_client'] as String?),
        statutLivraison: Value(row['statut_livraison'] as String? ?? 'a_livrer'),
        raisonEchec: Value(row['raison_echec'] as String?),
        livreLat: Value((row['livre_lat'] as num?)?.toDouble()),
        livreLng: Value((row['livre_lng'] as num?)?.toDouble()),
        livreLe: Value(row['livre_le'] == null
            ? null
            : DateTime.parse(row['livre_le'] as String)),
        ordreOptimise: Value(row['ordre_optimise'] as int?),
        ordrePriorite: Value(row['ordre_priorite'] as int?),
        preuvePhotoPath: Value(resolvedLocalPath),
        cloudPhotoPath: Value(cloudPhotoPath),
        coequipierId: Value(coequipierLocalId),
        creeLe: Value(DateTime.parse(row['cree_le'] as String)),
        cloudId: Value(cloudId),
        updatedAt: Value(cloudUpdatedAt),
      );
      if (localRow == null) {
        await _db.into(_db.stops).insert(companion);
        inserted++;
      } else {
        await (_db.update(_db.stops)..where((s) => s.id.equals(localRow.id)))
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

  Future<CloudPullStats> _pullSavedDestinations(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('saved_destinations').select();
    } on Object catch (e) {
      throw CloudSyncException('Echec fetch carnet : $e');
    }
    int inserted = 0, updated = 0, skipped = 0;
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = _parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.savedDestinations)
            ..where((s) => s.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !_cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
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

  // ─── Helpers last-write-wins (sous-jalon 2.D-1c) ────────────────

  /// Parse le champ `updated_at` envoye par Postgres dans le format
  /// timestamptz ISO 8601 (ex: `2026-05-16T14:23:45.123+00:00`).
  ///
  /// Fallback `DateTime.fromMillisecondsSinceEpoch(0)` si le champ est
  /// null (cas anormal : un push 2.D-1c+ doit toujours envoyer
  /// updated_at, mais le schema cloud autorise NULL pour retro-compat
  /// avec d'eventuels rows pushes par une vieille version de l'app).
  /// Un row sans updated_at est traite comme "infiniment ancien" et
  /// sera ecrase par n'importe quel local non-NULL.
  DateTime _parseCloudUpdatedAt(Object? raw) {
    if (raw is String) {
      return DateTime.parse(raw).toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// True si la version cloud est strictement plus recente que la
  /// version locale (donc on doit ecraser local). False sinon (egalite
  /// ou local plus recent -> skip pour preserver les modifs locales).
  ///
  /// Tolerance de 1 seconde sur l'egalite : Postgres stocke en
  /// microsecondes, SQLite Drift stocke en secondes (truncate). Sans
  /// tolerance, un push immediatement suivi d'un pull verrait
  /// `cloud.updated_at = floor(local.updated_at) <= local.updated_at`
  /// et skip — c'est OK ici puisqu'on push avec le timestamp local
  /// brut, mais si Postgres re-touchait la valeur (trigger serveur
  /// futur), l'arrondi pourrait creer un faux "cloud plus ancien".
  bool _cloudIsNewer(DateTime cloud, DateTime local) {
    return cloud.isAfter(local.add(const Duration(seconds: 1)));
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

/// Resume du resultat d'un pull cloud → local. Affiche par l'UI dans
/// une SnackBar : "12 elements synchronises (3 tournees, 8 arrets, 1
/// coequipier)".
class CloudPullResult {
  const CloudPullResult({
    required this.coequipiers,
    required this.tournees,
    required this.stops,
    required this.savedDestinations,
  });

  final CloudPullStats coequipiers;
  final CloudPullStats tournees;
  final CloudPullStats stops;
  final CloudPullStats savedDestinations;

  int get totalChanged =>
      coequipiers.total + tournees.total + stops.total + savedDestinations.total;

  /// Nombre total de rows ignorees par le last-write-wins (cloud plus
  /// ancien ou egal au local). Sous-jalon 2.D-1c.
  int get totalSkipped =>
      coequipiers.skipped +
      tournees.skipped +
      stops.skipped +
      savedDestinations.skipped;

  /// Phrase courte pour SnackBar / dialog de fin de pull.
  String get summary {
    if (totalChanged == 0) {
      if (totalSkipped > 0) {
        return 'Tout etait deja a jour ($totalSkipped element(s) cloud '
            'plus ancien(s) que la version locale).';
      }
      return 'Tout etait deja a jour. Rien a synchroniser.';
    }
    final parts = <String>[];
    if (tournees.total > 0) parts.add('${tournees.total} tournee(s)');
    if (stops.total > 0) parts.add('${stops.total} arret(s)');
    if (coequipiers.total > 0) parts.add('${coequipiers.total} coequipier(s)');
    if (savedDestinations.total > 0) {
      parts.add('${savedDestinations.total} entree(s) carnet');
    }
    final suffix = totalSkipped > 0 ? ' ($totalSkipped ignore(s))' : '';
    return '$totalChanged element(s) synchronise(s) : '
        '${parts.join(', ')}$suffix';
  }
}

/// Compteur interne (inserted + updated + skipped) pour une table donnee.
/// `skipped` = rows cloud ignorees par le last-write-wins (sous-jalon
/// 2.D-1c) car la version locale est plus recente ou egale. `total`
/// reste le nombre de changements appliques (insert + update), pas le
/// nombre de rows lues du cloud.
class CloudPullStats {
  const CloudPullStats({
    required this.inserted,
    required this.updated,
    this.skipped = 0,
  });
  final int inserted;
  final int updated;
  final int skipped;
  int get total => inserted + updated;
}
