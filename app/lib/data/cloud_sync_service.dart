import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'cloud/cloud_carnet_sync.dart';
import 'cloud/cloud_admin_sync.dart';
import 'cloud/cloud_entreprise_sync.dart';
import 'cloud/cloud_membres_entreprise_sync.dart';
import 'cloud/cloud_membres_sync.dart';
import 'cloud/cloud_notes_perso_sync.dart';
import 'cloud/cloud_sync_helpers.dart';
import 'cloud_error_humanizer.dart';
import 'cloud_sync_types.dart';
import 'database.dart';
import 'supabase_service.dart';

// Re-export pour conserver la compat des callers qui font
// `import 'cloud_sync_service.dart';` et utilisent CloudSyncException,
// CloudPullResult, CloudPullStats, TourneeMembreInfo (cf split refactor
// 2026-05-18). Le `_PhotoDownloadTask` reste private dans ce fichier.
export 'cloud_sync_types.dart';
// Re-export du modele membre pour les providers / UI (#366).
export 'cloud/cloud_membres_entreprise_sync.dart' show EntrepriseMembreInfo;

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
  })  : _explicitClient = client,
        _carnet = CloudCarnetSync(_db),
        _membres = CloudMembresSync(_db),
        _entreprise = CloudEntrepriseSync(_db);

  final AppDatabase _db;
  final SupabaseService _supabase;
  final SupabaseClient? _explicitClient;

  /// Sous-service de sync du carnet (saved_destinations). Carte #167
  /// etape 2. CloudSyncService lui delegue push/pull et lui fournit le
  /// client + userId via ses guards.
  final CloudCarnetSync _carnet;

  /// Sous-service des tournees partagees : invitations + adhesions
  /// (jalon 3.A/B). Carte #167 etape 3.
  final CloudMembresSync _membres;

  /// Sous-service multi-tenant : creation/pull entreprises + entrepots
  /// (carte #364). Delegue avec le client + userId resolus par les guards.
  final CloudEntrepriseSync _entreprise;

  /// Sous-service gestion employes : invitation (code/mail), liste,
  /// revocation (carte #366). Stateless (pas de _db).
  final CloudMembresEntrepriseSync _membresEnt =
      const CloudMembresEntrepriseSync();

  /// Sous-service notes perso employe sur un client partage (carte #367).
  /// Stateless : RLS user_id = auth.uid() cote cloud.
  final CloudNotesPersoSync _notesPerso = const CloudNotesPersoSync();

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
      throw CloudSyncException(
          'Echec push coequipier "${c.nom}" : ${humanizeCloudError(e)}');
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
      throw CloudSyncException(
          'Echec push tournee "${t.nom}" : ${humanizeCloudError(e)}');
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
      'type': s.type,
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
        'Echec push stop "${s.adresseBrute}" : ${humanizeCloudError(e)}',
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
    final userId = _requireUserId();
    // Pas besoin de filtrer par user_id dans les selects : la RLS
    // Supabase fait deja le filtrage (chaque select retourne uniquement
    // les rows ou user_id = auth.uid()).
    final coequipiers = await _pullCoequipiers(client);
    final tournees = await _pullTournees(client);
    final stops = await _pullStops(client);
    final savedDestinations = await _carnet.pull(client);
    // Jalon 3.A : adhesions aux tournees partagees (qui voit quoi).
    // Apres les tournees pour que les rows membres aient bien une
    // tournee_cloud_id correspondant a un row tournees deja pulle.
    await _membres.pullMembres(client);
    // Bug Trello #68 : avant ce fix, le carnet avait un pull mais pas
    // de push -> table Supabase vide pour tout le monde, donc le pull
    // renvoyait toujours 0. On push maintenant les entrees locales du
    // carnet apres le pull pour amorcer la sync (sign-in initial sur
    // un device avec un carnet existant -> push retroactif). Silent :
    // un echec ne casse pas le pull global, on re-tentera plus tard.
    try {
      await _carnet.pushAll(client, userId);
    } on Object catch (e) {
      debugPrint('[CloudSyncService] Push carnet apres pull echec : $e');
    }
    return CloudPullResult(
      coequipiers: coequipiers,
      tournees: tournees,
      stops: stops,
      savedDestinations: savedDestinations,
    );
  }

  /// Pousse un code de suivi colis (carte #81) vers la table cloud
  /// `tracking_codes` pour que l'Edge Function `track` puisse le
  /// resoudre. Best-effort : no-op si le stop n'a pas encore de cloudId
  /// (il faut le pousser au cloud d'abord). Idempotent : upsert sur le
  /// code (PK) -> re-generer le meme lien ne cree pas de doublon.
  ///
  /// Throws [CloudSyncException] uniquement sur erreur de config / auth.
  Future<void> pushTrackingCode(String code, int localStopId) async {
    final client = _client();
    _requireUserId();
    final stop = await (_db.select(_db.stops)
          ..where((s) => s.id.equals(localStopId)))
        .getSingleOrNull();
    final stopCloudId = stop?.cloudId;
    if (stopCloudId == null) {
      // Stop jamais sync : impossible de lier le code. Le caller doit
      // pousser la tournee/stop au cloud avant. No-op silencieux.
      return;
    }
    await client.from('tracking_codes').upsert({
      'code': code,
      'stop_id': stopCloudId,
    });
  }

  // ─── Mode équipe live (jalon 3.A) ───────────────────────────────

  /// Crée une invitation à 6 chiffres pour la tournée locale donnée.
  /// La tournée doit déjà avoir un `cloudId` (= pushée au moins une
  /// fois). Retourne le code à afficher / partager. Delegue a
  /// [CloudMembresSync] (carte #167 etape 3).
  Future<String> createInvitation(int localTourneeId) {
    return _membres.createInvitation(
        _client(), _requireUserId(), localTourneeId);
  }

  /// Le coequipier saisit le code à 6 chiffres → RPC `accept_invitation`.
  /// Retourne le cloud UUID de la tournée rejointe (le caller declenche
  /// ensuite un pull). Delegue a [CloudMembresSync].
  Future<String> acceptInvitation(String code) {
    final client = _client();
    _requireUserId();
    return _membres.acceptInvitation(client, code);
  }

  /// Liste les membres d'une tournee partagee via RPC SECURITY DEFINER
  /// (sous-jalon 3.B). Delegue a [CloudMembresSync].
  // `async` IMPORTANT : sans ca, `_client()` / `_requireUserId()` lancent
  // leur CloudSyncException de maniere SYNCHRONE a l'appel. Or cette
  // methode est appelee dans `CoequipiersSection.initState` -> un throw
  // sync y casse le build de l'ecran tournee (carre gris) quand on n'est
  // pas connecte au cloud. En async, le throw devient une erreur de
  // Future, rattrapee par le FutureBuilder (snapshot.hasError).
  Future<List<TourneeMembreInfo>> listTourneeMembers(int localTourneeId) async {
    final client = _client();
    _requireUserId();
    return _membres.listMembers(client, localTourneeId);
  }

  /// Quitte une tournee partagee. L'owner ne peut PAS quitter (doit
  /// supprimer). Nettoie la tournee + stops en local. Delegue a
  /// [CloudMembresSync].
  Future<void> leaveTournee(int localTourneeId) {
    return _membres.leaveTournee(
        _client(), _requireUserId(), localTourneeId);
  }

  /// Sous-jalon 2.F : supprime une tournee EN PROPAGEANT la suppression
  /// au cloud (row tournees + cascade stops + photos Storage). Suit
  /// par le DELETE Drift local.
  ///
  /// **Best-effort cloud** : si pas configure / pas auth / network down /
  /// pas de cloudId, on continue le delete local quand meme (le user
  /// doit pouvoir supprimer offline). Erreurs cloud loguees mais non
  /// throw — sinon Noah ne pourrait pas delete en mode avion.
  ///
  /// **Pas de tombstone** : on assume que le user qui delete a la
  /// possibilite de re-sign-in plus tard et fera un pull qui ne
  /// retrouvera plus le row (parce qu'il est DELETE cloud aussi). Si
  /// un autre device a une copie locale, elle restera tant qu'il ne
  /// re-pull pas. C'est acceptable pour le MVP (vs tombstone qui
  /// demanderait une table `deletions` + cron de cleanup).
  Future<void> deleteTourneeWithCloudCleanup(int localTourneeId) async {
    final tournee = await (_db.select(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .getSingleOrNull();
    final stops = await (_db.select(_db.stops)
          ..where((s) => s.tourneeId.equals(localTourneeId)))
        .get();
    final cloudId = tournee?.cloudId;
    if (cloudId != null && _supabase.isConfigured &&
        _supabase.currentUser != null) {
      final client = _client();
      // 1. Cleanup photos Storage (batch remove pour gain perf)
      final photoPaths = <String>[
        for (final s in stops)
          if (s.cloudPhotoPath != null) s.cloudPhotoPath!,
      ];
      if (photoPaths.isNotEmpty) {
        try {
          await client.storage.from('preuves').remove(photoPaths);
        } on Object catch (e) {
          debugPrint('[CloudSync] cleanup photos Storage fail : $e');
        }
      }
      // 2. DELETE row tournee cloud (CASCADE supprime stops + invits)
      try {
        await client.from('tournees').delete().eq('id', cloudId);
      } on Object catch (e) {
        debugPrint('[CloudSync] cleanup row tournee cloud fail : $e');
      }
    }
    // 3. Delete local (Drift CASCADE via FK supprime les stops aussi)
    await (_db.delete(_db.tournees)
          ..where((t) => t.id.equals(localTourneeId)))
        .go();
  }

  /// Sous-jalon 2.F : equivalent pour un stop individuel.
  Future<void> deleteStopWithCloudCleanup(int localStopId) async {
    final stop = await (_db.select(_db.stops)
          ..where((s) => s.id.equals(localStopId)))
        .getSingleOrNull();
    final cloudId = stop?.cloudId;
    if (cloudId != null && _supabase.isConfigured &&
        _supabase.currentUser != null) {
      final client = _client();
      // 1. Cleanup photo Storage (1 seul fichier si present)
      final cloudPhotoPath = stop?.cloudPhotoPath;
      if (cloudPhotoPath != null) {
        try {
          await client.storage.from('preuves').remove([cloudPhotoPath]);
        } on Object catch (e) {
          debugPrint('[CloudSync] cleanup photo Storage fail : $e');
        }
      }
      // 2. DELETE row stop cloud
      try {
        await client.from('stops').delete().eq('id', cloudId);
      } on Object catch (e) {
        debugPrint('[CloudSync] cleanup row stop cloud fail : $e');
      }
    }
    // 3. Delete local
    await (_db.delete(_db.stops)..where((s) => s.id.equals(localStopId)))
        .go();
  }

  /// L'owner ejecte un membre d'une tournee partagee. Delegue a
  /// [CloudMembresSync] (carte #167 etape 3).
  Future<void> kickMember(int localTourneeId, String memberUserCloudId) {
    return _membres.kickMember(
        _client(), _requireUserId(), localTourneeId, memberUserCloudId);
  }

  // createInvitation / acceptInvitation / listTourneeMembers /
  // leaveTournee / kickMember + _pullTourneeMembres extraits dans
  // `cloud/cloud_membres_sync.dart` (carte #167 etape 3).
  // generateInvitationCode + invitationErrorToFr dans
  // `cloud/cloud_sync_helpers.dart` (etape 1).

  Future<CloudPullStats> _pullCoequipiers(SupabaseClient client) async {
    final List<dynamic> rows;
    try {
      rows = await client.from('coequipiers').select();
    } on Object catch (e) {
      throw CloudSyncException('Echec fetch coequipiers : ${humanizeCloudError(e)}');
    }
    int inserted = 0, updated = 0, skipped = 0;
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.coequipiers)
            ..where((c) => c.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
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
      throw CloudSyncException('Echec fetch tournees : ${humanizeCloudError(e)}');
    }
    int inserted = 0, updated = 0, skipped = 0;
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.tournees)
            ..where((t) => t.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
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
      throw CloudSyncException('Echec fetch stops : ${humanizeCloudError(e)}');
    }
    int inserted = 0, updated = 0, skipped = 0;
    // Phase 1 : INSERT/UPDATE tous les rows AVEC le path local existant
    // (sans download). Collecte les downloads a faire dans une liste
    // pour les paralleliser ensuite.
    final pendingDownloads = <_PhotoDownloadTask>[];
    for (final r in rows) {
      final row = r as Map<String, dynamic>;
      final cloudId = row['id'] as String;
      final cloudUpdatedAt = parseCloudUpdatedAt(row['updated_at']);
      final localRow = await (_db.select(_db.stops)
            ..where((s) => s.cloudId.equals(cloudId)))
          .getSingleOrNull();
      if (localRow != null &&
          !cloudIsNewer(cloudUpdatedAt, localRow.updatedAt)) {
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
        continue;
      }
      final coequipierCloudId = row['coequipier_id'] as String?;
      final coequipierLocalId = coequipierCloudId == null
          ? null
          : await (_db.select(_db.coequipiers)
                ..where((c) => c.cloudId.equals(coequipierCloudId)))
              .map((c) => c.id)
              .getSingleOrNull();
      // 2.E-2 + perf parallel : on garde l'existing path pour ne pas
      // ecraser une photo locale, et on schedule le download a faire
      // dans la phase 2 (parallele). Si pas de cloud_photo_path ou
      // fichier local deja la, _resolveDownloadTask renvoie null.
      final cloudPhotoPath = row['cloud_photo_path'] as String?;
      final existingLocalPath =
          localRow?.preuvePhotoPath ?? row['preuve_photo_path'] as String?;
      final companion = StopsCompanion(
        tourneeId: Value(tourneeLocalId),
        adresseBrute: Value(row['adresse_brute'] as String),
        adresseNormalisee: Value(row['adresse_normalisee'] as String?),
        lat: Value((row['lat'] as num?)?.toDouble()),
        lng: Value((row['lng'] as num?)?.toDouble()),
        nbColis: Value(row['nb_colis'] as int? ?? 1),
        priorite: Value(row['priorite'] as String? ?? 'flexible'),
        // Default 'livraison' au pull pour les rows pre-feature-ramasses
        // (colonne cloud potentiellement NULL si push d'une vieille app).
        type: Value(row['type'] as String? ?? 'livraison'),
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
        // Pour la phase 1 : on garde le path existant (peut etre null).
        // Si download succede en phase 2, on UPDATE plus tard.
        preuvePhotoPath: Value(existingLocalPath),
        cloudPhotoPath: Value(cloudPhotoPath),
        coequipierId: Value(coequipierLocalId),
        creeLe: Value(DateTime.parse(row['cree_le'] as String)),
        cloudId: Value(cloudId),
        updatedAt: Value(cloudUpdatedAt),
      );
      int stopLocalId;
      if (localRow == null) {
        stopLocalId = await _db.into(_db.stops).insert(companion);
        inserted++;
      } else {
        stopLocalId = localRow.id;
        await (_db.update(_db.stops)..where((s) => s.id.equals(localRow.id)))
            .write(companion);
        updated++;
      }
      // Schedule le download photo si pertinent.
      if (cloudPhotoPath != null &&
          !await _isLocalFilePresent(existingLocalPath)) {
        pendingDownloads.add(_PhotoDownloadTask(
          stopLocalId: stopLocalId,
          cloudPhotoPath: cloudPhotoPath,
          stopCloudId: cloudId,
        ));
      }
    }
    // Phase 2 : parallelise les downloads par batchs de 5 (compromise
    // entre rapidite et eviter de surcharger le reseau/Storage). Avant
    // refactor : ~500ms/photo sequentiel. Apres : ~5 photos en paralele,
    // gain d'environ 5x sur les pulls multi-photos.
    await _processDownloadBatch(client, pendingDownloads, batchSize: 5);
    return CloudPullStats(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }

  Future<bool> _isLocalFilePresent(String? path) async {
    if (path == null || kIsWeb) return false;
    return File(path).exists();
  }

  /// Telecharge en parallele un batch de photos preuves et UPDATE le
  /// preuvePhotoPath du stop Drift correspondant. Best-effort par
  /// download : un echec isole ne bloque pas les autres.
  Future<void> _processDownloadBatch(
    SupabaseClient client,
    List<_PhotoDownloadTask> tasks, {
    required int batchSize,
  }) async {
    for (var i = 0; i < tasks.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, tasks.length);
      await Future.wait(
        tasks.sublist(i, end).map((t) => _executeDownload(client, t)),
      );
    }
  }

  Future<void> _executeDownload(
    SupabaseClient client,
    _PhotoDownloadTask task,
  ) async {
    final resolved = await _maybeDownloadPhoto(
      client: client,
      cloudPhotoPath: task.cloudPhotoPath,
      existingLocalPath: null,
      stopCloudId: task.stopCloudId,
    );
    if (resolved == null) return;
    // UPDATE le row Drift avec le path local final. On utilise une
    // Value.absent() partout sauf preuvePhotoPath pour eviter de
    // toucher le trigger updated_at (ne tirera pas car NEW = OLD sur
    // tout sauf cette colonne, mais le trigger compare updated_at
    // specifiquement). Le trigger NE tirera donc QUE si on change
    // updated_at, ce qu'on ne fait pas ici.
    await (_db.update(_db.stops)
          ..where((s) => s.id.equals(task.stopLocalId)))
        .write(StopsCompanion(preuvePhotoPath: Value(resolved)));
  }

  /// Push public d'une seule entree du carnet identifiee par son id
  /// local. Sert au carnet partage entre coequipiers (carte Trello #57) :
  /// quand un livreur ajoute / edite un client, on push immediatement
  /// pour que les autres devices de l'equipe voient l'entree au prochain
  /// pull. Best-effort : silencieux si offline ou row introuvable, throw
  /// [CloudSyncException] uniquement sur erreur de configuration.
  ///
  /// Delegue a [CloudCarnetSync] (carte #167 etape 2).
  Future<void> pushSavedDestination(int localId) async {
    final client = _client();
    final userId = _requireUserId();
    await _carnet.pushOne(client, userId, localId);
  }

  // _pushAllSavedDestinations + _pushSavedDestinationRow +
  // _pullSavedDestinations + helpers last-write-wins extraits dans
  // `cloud/cloud_carnet_sync.dart` + `cloud/cloud_sync_helpers.dart`
  // (carte #167 etapes 1-2).

  // ── Multi-tenant entreprise / entrepot (carte #364) ──

  /// Cree une entreprise cote cloud (+ admin auto via trigger SQL
  /// `on_entreprise_created`) puis en miroir local. Retourne le cloud_id.
  Future<String> createEntreprise(
      {required String nom, String? siret, String? code}) {
    return _entreprise.createEntreprise(_client(), _requireUserId(),
        nom: nom, siret: siret, code: code);
  }

  // ════════════════════════════════════════════════════════════════
  // Super admin (#372) + garde-fou code maître (#374)
  // ════════════════════════════════════════════════════════════════

  CloudAdminSync get _admin => const CloudAdminSync();

  /// Le compte connecté est-il super admin ? (révèle le panel admin).
  Future<bool> isSuperAdmin() => _admin.isSuperAdmin(_client());

  /// Code maître courant (réservé au super admin).
  Future<String> getMasterCode() => _admin.getMasterCode(_client());

  /// Régénère le code maître et retourne le nouveau (super admin).
  Future<String> regenerateMasterCode() =>
      _admin.regenerateMasterCode(_client());

  /// Liste toutes les entreprises (vue globale super admin).
  Future<List<AdminEntrepriseInfo>> adminListEntreprises() =>
      _admin.listAllEntreprises(_client());

  /// Cree un entrepot rattache a [entrepriseId] (admin ou chef_entrepot)
  /// cote cloud puis en miroir local. Retourne le cloud_id.
  Future<String> createEntrepot({
    required String entrepriseId,
    required String nom,
    String? adresse,
    double? lat,
    double? lng,
  }) {
    _requireUserId();
    return _entreprise.createEntrepot(_client(),
        entrepriseId: entrepriseId,
        nom: nom,
        adresse: adresse,
        lat: lat,
        lng: lng);
  }

  /// Pull les entreprises + entrepots visibles (RLS) en miroir local.
  /// Sert au cross-device et a l'employe invite (#367).
  Future<void> pullMesEntreprises() async {
    final client = _client();
    _requireUserId();
    await _entreprise.pullMine(client);
  }

  // ── Gestion employes (carte #366) ──

  /// Invite un employe par MAIL (Edge Function invite_employee).
  Future<({String code, bool emailSent, String? emailError})>
      inviteEmployeByMail({
    required String entrepriseId,
    String? entrepotId,
    required String email,
    required String roleTarget,
  }) {
    _requireUserId();
    return _membresEnt.inviteByMail(_client(),
        entrepriseId: entrepriseId,
        entrepotId: entrepotId,
        email: email,
        roleTarget: roleTarget);
  }

  /// Invite un employe par CODE a 6 chiffres. Retourne le code.
  Future<String> inviteEmployeByCode({
    required String entrepriseId,
    String? entrepotId,
    required String roleTarget,
    int validityHours = 72,
  }) {
    return _membresEnt.inviteByCode(_client(), _requireUserId(),
        entrepriseId: entrepriseId,
        entrepotId: entrepotId,
        roleTarget: roleTarget,
        validityHours: validityHours);
  }

  /// Liste les membres d'une entreprise (RPC SECURITY DEFINER).
  Future<List<EntrepriseMembreInfo>> listEntrepriseMembers(
      String entrepriseId) {
    _requireUserId();
    return _membresEnt.listMembers(_client(), entrepriseId);
  }

  /// Revoque un membre (statut revoque + J+30 cron).
  Future<void> revokeEntrepriseMember({
    required String entrepriseId,
    required String userId,
    String? entrepotId,
  }) {
    _requireUserId();
    return _membresEnt.revokeMember(_client(),
        entrepriseId: entrepriseId, userId: userId, entrepotId: entrepotId);
  }

  /// Reactive un membre revoque avant la fin du J+30.
  Future<void> reactivateEntrepriseMember({
    required String entrepriseId,
    required String userId,
    String? entrepotId,
  }) {
    _requireUserId();
    return _membresEnt.reactivateMember(_client(),
        entrepriseId: entrepriseId, userId: userId, entrepotId: entrepotId);
  }

  /// Cote employe : accepte une invitation par code (#373).
  Future<String> acceptEntrepriseInvitationByCode(String code) {
    final client = _client();
    _requireUserId();
    return _membresEnt.acceptByCode(client, code);
  }

  // ── Notes perso employe sur un client partage (carte #367) ──

  /// Lit la note perso (privee) de l'utilisateur courant sur la fiche
  /// carnet [savedDestinationCloudId]. Null si aucune note.
  Future<String?> getNotePerso(String savedDestinationCloudId) {
    _requireUserId();
    return _notesPerso.getNote(_client(), savedDestinationCloudId);
  }

  /// Upsert la note perso (suppression si [notes] vide).
  Future<void> saveNotePerso({
    required String savedDestinationCloudId,
    required String notes,
  }) {
    return _notesPerso.upsertNote(_client(), _requireUserId(),
        savedDestinationCloudId: savedDestinationCloudId, notes: notes);
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

/// Task de download photo en attente (perf parallel pull 2.E-2 v2).
/// Cree en phase 1 de [CloudSyncService._pullStops] et execute en
/// parallele par batch en phase 2.
///
/// Private a ce fichier (sert uniquement au pull interne). Pas extrait
/// dans cloud_sync_types.dart contrairement aux autres types data qui
/// sont consommes par les screens.
class _PhotoDownloadTask {
  const _PhotoDownloadTask({
    required this.stopLocalId,
    required this.cloudPhotoPath,
    required this.stopCloudId,
  });

  final int stopLocalId;
  final String cloudPhotoPath;
  final String stopCloudId;
}
