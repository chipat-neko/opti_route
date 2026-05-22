import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// CRUD pour les arrets (`Stop`) d'une tournee.
class StopsRepository {
  StopsRepository(this._db);

  final AppDatabase _db;

  /// Stream de tous les arrets d'une tournee, ordonne par
  /// `ordre_optimise` (si optimisee) puis par id.
  Stream<List<Stop>> watchByTournee(int tourneeId) {
    final query = _db.select(_db.stops)
      ..where((s) => s.tourneeId.equals(tourneeId))
      ..orderBy([
        (s) => OrderingTerm.asc(s.ordreOptimise),
        (s) => OrderingTerm.asc(s.id),
      ]);
    return query.watch();
  }

  Future<List<Stop>> getByTournee(int tourneeId) {
    return (_db.select(_db.stops)
          ..where((s) => s.tourneeId.equals(tourneeId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.ordreOptimise),
            (s) => OrderingTerm.asc(s.id),
          ]))
        .get();
  }

  Future<Stop?> getById(int id) {
    return (_db.select(_db.stops)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(StopsCompanion entry) {
    return _db.into(_db.stops).insert(entry);
  }

  Future<int> update(int id, StopsCompanion entry) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(id))).write(entry);
  }

  /// Deplace un arret d'une tournee vers une autre. Reset l'ordre
  /// optimise (le nouvel ordre dans la tournee de destination sera
  /// calcule par l'auto-reorder local declenche apres).
  ///
  /// Use case : Noah a embarque le mauvais colis dans la mauvaise
  /// tournee, ou un client appelle "j'ai oublie de te dire, mets-moi
  /// avec la tournee de demain". Pas besoin de supprimer + recreer.
  ///
  /// Note : l'invalidation de l'optimisation VROOM des 2 tournees
  /// (source + destination) et l'auto-reorder local sont a la charge
  /// du caller (typiquement le screen qui declenche le move).
  Future<int> moveToTournee(int stopId, int newTourneeId) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(stopId)))
        .write(StopsCompanion(
      tourneeId: Value(newTourneeId),
      ordreOptimise: const Value(null),
    ));
  }

  /// Affecte un coequipier a un arret. [coequipierId] null = Noah
  /// lui-meme (cas par defaut, pas d'aidant).
  Future<int> setCoequipier(int stopId, int? coequipierId) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(stopId)))
        .write(StopsCompanion(coequipierId: Value(coequipierId)));
  }

  /// Incremente le compteur `nbColis` de [delta] (typiquement +1 quand
  /// Noah scanne un code-barre supplementaire pour un client existant)
  /// ET append le numero de tracking a la liste JSON `tracking_numbers`
  /// si fourni. Idempotent sur le tracking : si le numero est deja
  /// present dans la liste, on n'incremente PAS (anti-double-scan).
  ///
  /// Retourne true si l'arret a effectivement ete incremente, false si
  /// le tracking etait deja present (donc no-op).
  Future<bool> incrementColisWithTracking(
    int stopId, {
    required String trackingNumber,
    int delta = 1,
  }) async {
    final stop = await getById(stopId);
    if (stop == null) return false;
    final existing = _parseTrackingList(stop.trackingNumbers);
    if (existing.contains(trackingNumber)) return false;
    existing.add(trackingNumber);
    await (_db.update(_db.stops)..where((s) => s.id.equals(stopId))).write(
      StopsCompanion(
        nbColis: Value(stop.nbColis + delta),
        trackingNumbers: Value(_encodeTrackingList(existing)),
      ),
    );
    return true;
  }

  /// Cherche dans tous les stops de [tourneeId] celui qui contient deja
  /// [trackingNumber] dans sa liste JSON tracking_numbers. Retourne null
  /// si aucun stop ne le contient. Utile pour decider entre incrementer
  /// un stop existant ou en creer un nouveau au scan code-barre.
  Future<Stop?> findByTrackingInTournee(
    int tourneeId,
    String trackingNumber,
  ) async {
    final stops = await getByTournee(tourneeId);
    for (final s in stops) {
      final list = _parseTrackingList(s.trackingNumbers);
      if (list.contains(trackingNumber)) return s;
    }
    return null;
  }

  /// Parse la liste JSON de tracking numbers d'un stop. Format
  /// `["FA28...","FA28..."]`. Tolere null / format casse en retournant
  /// liste vide.
  static List<String> _parseTrackingList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {
      // Format casse : on traite comme liste vide.
    }
    return [];
  }

  static String _encodeTrackingList(List<String> items) {
    return jsonEncode(items);
  }

  /// Bascule le type d'un arret entre 'livraison' et 'ramasse'. Sert au
  /// "Convertir en ramasse" / "Convertir en livraison" depuis la bottom
  /// sheet, quand Noah s'apercoit qu'il a mal coche au moment de la
  /// creation, ou que le client lui demande un retour en plus.
  ///
  /// Pas de log dans StopHistory : le type est une caracteristique de
  /// l'arret, pas une transition de statut. Si l'arret etait deja
  /// valide (statut livre/echec), le statut reste, on bascule juste le
  /// type pour les futures stats. Pour vraiment "annuler", utiliser
  /// [markAaLivrer] separement.
  Future<int> setType(int stopId, String type) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(stopId)))
        .write(StopsCompanion(type: Value(type)));
  }

  /// Affecte un coequipier a TOUS les stops d'une tournee qui n'ont
  /// pas encore d'affectation. Sert au "Tout affecter a X" rapide.
  Future<int> setCoequipierForUnassigned(
    int tourneeId,
    int? coequipierId,
  ) async {
    return (_db.update(_db.stops)
          ..where((s) =>
              s.tourneeId.equals(tourneeId) &
              s.coequipierId.isNull()))
        .write(StopsCompanion(coequipierId: Value(coequipierId)));
  }

  /// Attache (ou retire avec null) une photo preuve a un arret deja
  /// valide. Sert au flow "Marquer livre -> Snackbar 'Photo ?' -> tap
  /// micro -> photo". Ne touche pas au statut, ni a la position GPS,
  /// ni a livreLe.
  Future<int> setPreuvePhoto(int stopId, String? path) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(stopId)))
        .write(StopsCompanion(preuvePhotoPath: Value(path)));
  }

  /// Met a jour uniquement les coords + l'adresse normalisee d'un arret.
  /// Utilise par le re-geocodage des arrets sauves en mode hors-ligne
  /// (sans coords) : on ne touche pas au reste (nbColis, notes, etc.).
  Future<int> updateCoords({
    required int stopId,
    required double lat,
    required double lng,
    String? adresseNormalisee,
  }) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(stopId)))
        .write(StopsCompanion(
      lat: Value(lat),
      lng: Value(lng),
      adresseNormalisee: adresseNormalisee == null
          ? const Value.absent()
          : Value(adresseNormalisee),
    ));
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.stops)..where((s) => s.id.equals(id))).go();
  }

  /// Marque un arret comme livre + ecrit une ligne dans StopHistory
  /// pour tracer la transition (en cas de litige client).
  ///
  /// [preuvePhotoPath] (optionnel) : chemin local d'une photo preuve
  /// prise par le livreur (cf `PreuvePhotoService.capturer`).
  ///
  /// Atomique : le read previous + l'update du stop + le log d'historique
  /// se font dans la meme transaction SQLite. Sans ca, une concurrence
  /// sur le meme stop (double-tap rapide) lirait un previous stale et
  /// loguerait un fromStatus errone (vu lors d'un audit 2026-05-14).
  Future<int> markLivre(
    int id, {
    ({double lat, double lng})? position,
    DateTime? livreLe,
    String? preuvePhotoPath,
  }) async {
    return _db.transaction(() async {
      final previous = await getById(id);
      final n = await (_db.update(_db.stops)..where((s) => s.id.equals(id)))
          .write(
        StopsCompanion(
          statutLivraison: const Value('livre'),
          raisonEchec: const Value(null),
          livreLat:
              position == null ? const Value(null) : Value(position.lat),
          livreLng:
              position == null ? const Value(null) : Value(position.lng),
          livreLe: Value(livreLe ?? DateTime.now()),
          preuvePhotoPath: preuvePhotoPath == null
              ? const Value.absent()
              : Value(preuvePhotoPath),
        ),
      );
      if (previous != null) {
        await _logHistory(
          stopId: id,
          action: 'mark_livre',
          fromStatus: previous.statutLivraison,
          toStatus: 'livre',
        );
      }
      return n;
    });
  }

  /// Marque un arret en echec + log dans StopHistory avec la raison.
  ///
  /// [preuvePhotoPath] (optionnel) : photo preuve d'un echec (ex: porte
  /// fermee, boite aux lettres pleine). Atomique (cf [markLivre]).
  Future<int> markEchec(
    int id,
    String raison, {
    ({double lat, double lng})? position,
    DateTime? livreLe,
    String? preuvePhotoPath,
  }) async {
    return _db.transaction(() async {
      final previous = await getById(id);
      final n = await (_db.update(_db.stops)..where((s) => s.id.equals(id)))
          .write(
        StopsCompanion(
          statutLivraison: const Value('echec'),
          raisonEchec: Value(raison),
          livreLat:
              position == null ? const Value(null) : Value(position.lat),
          livreLng:
              position == null ? const Value(null) : Value(position.lng),
          livreLe: Value(livreLe ?? DateTime.now()),
          preuvePhotoPath: preuvePhotoPath == null
              ? const Value.absent()
              : Value(preuvePhotoPath),
        ),
      );
      if (previous != null) {
        await _logHistory(
          stopId: id,
          action: 'mark_echec',
          fromStatus: previous.statutLivraison,
          toStatus: 'echec',
          raison: raison,
        );
      }
      return n;
    });
  }

  /// Annule un statut deja pose : repasse 'a_livrer' + reset toutes les
  /// metadonnees de validation (raisonEchec, coords GPS, livreLe, photo)
  /// + log la transition inverse. Atomique (cf [markLivre]).
  ///
  /// Alias [revertStatus] sert au bouton "Annuler le dernier statut"
  /// (action loggee = 'revert' au lieu de 'mark_a_livrer'), mais
  /// l'effet est identique.
  Future<int> markAaLivrer(int id) async {
    return _markAaLivrerImpl(id, action: 'mark_a_livrer');
  }

  Future<void> _logHistory({
    required int stopId,
    required String action,
    required String fromStatus,
    required String toStatus,
    String? raison,
  }) async {
    await _db.into(_db.stopHistory).insert(
          StopHistoryCompanion.insert(
            stopId: stopId,
            action: action,
            fromStatus: fromStatus,
            toStatus: toStatus,
            raison: Value(raison),
          ),
        );
  }

  /// Recupere l'historique des transitions d'un arret, ordre chrono
  /// du plus recent au plus ancien.
  Future<List<StopHistoryData>> getHistory(int stopId) {
    return (_db.select(_db.stopHistory)
          ..where((h) => h.stopId.equals(stopId))
          ..orderBy([(h) => OrderingTerm.desc(h.timestamp)]))
        .get();
  }

  Future<int> countByTournee(int tourneeId) async {
    final result = await getByTournee(tourneeId);
    return result.length;
  }

  /// Recupere le **dernier** stop d'une tournee dont le statut a ete
  /// transitionne (le plus recent dans `stop_history`). Sert au bouton
  /// "Annuler le dernier statut" : on remet ce stop a `a_livrer`.
  /// Retourne null si rien a annuler (aucune transition livre/echec).
  Future<Stop?> getLastTransitionedStop(int tourneeId) async {
    // On limite au dernier event qui change vers livre/echec.
    final stops = await getByTournee(tourneeId);
    if (stops.isEmpty) return null;
    final stopIds = stops.map((s) => s.id).toList();
    final hist = await (_db.select(_db.stopHistory)
          ..where((h) =>
              h.stopId.isIn(stopIds) &
              h.toStatus.isIn(['livre', 'echec']))
          ..orderBy([(h) => OrderingTerm.desc(h.timestamp)])
          ..limit(1))
        .getSingleOrNull();
    if (hist == null) return null;
    // Audit 2026-05-17 fix : avant `firstWhere` sans `orElse` qui
    // throw StateError si le stop a ete supprime entre le getByTournee
    // et le check history (race rare mais possible quand sync 3.A
    // arrive depuis un autre device). Retourne null silencieusement
    // a la place — le bouton "Annuler le dernier statut" sera no-op.
    for (final s in stops) {
      if (s.id == hist.stopId) return s;
    }
    return null;
  }

  /// Annule le statut d'un stop : alias de [markAaLivrer] avec
  /// `action='revert'` dans le log d'historique. Comportement identique
  /// (reset complet des metadonnees + photo).
  ///
  /// Bug fix audit 2026-05-14 : avant ce refactor, revertStatus oubliait
  /// de reset preuvePhotoPath, laissant la photo orpheline sur un stop
  /// repassé en a_livrer (incoherent avec markAaLivrer).
  Future<void> revertStatus(int stopId) async {
    await _markAaLivrerImpl(stopId, action: 'revert');
  }

  /// Implementation partagee entre [markAaLivrer] et [revertStatus].
  /// La seule difference est le label `action` ecrit dans StopHistory.
  /// Atomique : read previous + update + log dans 1 transaction (evite
  /// les races sur le meme stop).
  Future<int> _markAaLivrerImpl(int id, {required String action}) async {
    return _db.transaction(() async {
      final previous = await getById(id);
      final n = await (_db.update(_db.stops)..where((s) => s.id.equals(id)))
          .write(
        const StopsCompanion(
          statutLivraison: Value('a_livrer'),
          raisonEchec: Value(null),
          livreLat: Value(null),
          livreLng: Value(null),
          livreLe: Value(null),
          preuvePhotoPath: Value(null),
        ),
      );
      if (previous != null) {
        await _logHistory(
          stopId: id,
          action: action,
          fromStatus: previous.statutLivraison,
          toStatus: 'a_livrer',
        );
      }
      return n;
    });
  }

  /// Applique l'ordre optimise calcule par le solveur : pour chaque
  /// stop, on ecrit `ordre_optimise = position dans la liste` (1-based).
  /// Batch atomique : un seul echange transactionnel avec SQLite.
  Future<void> applyOptimizedOrder(List<int> orderedStopIds) async {
    if (orderedStopIds.isEmpty) return;
    await _db.batch((batch) {
      for (var i = 0; i < orderedStopIds.length; i++) {
        batch.update(
          _db.stops,
          StopsCompanion(ordreOptimise: Value(i + 1)),
          where: (s) => s.id.equals(orderedStopIds[i]),
        );
      }
    });
  }

  /// Pose `ordrePriorite = position dans [orderedStopIds]` (1-based)
  /// pour chaque stop. Sert au reorder manuel (drag&drop dans
  /// TourneeDuJourScreen) afin que la prochaine optimisation reprenne
  /// cet ordre par defaut. Batch identique a [applyOptimizedOrder].
  Future<void> applyOrdrePriorite(List<int> orderedStopIds) async {
    if (orderedStopIds.isEmpty) return;
    await _db.batch((batch) {
      for (var i = 0; i < orderedStopIds.length; i++) {
        batch.update(
          _db.stops,
          StopsCompanion(ordrePriorite: Value(i + 1)),
          where: (s) => s.id.equals(orderedStopIds[i]),
        );
      }
    });
  }
}
