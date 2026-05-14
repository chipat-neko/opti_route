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
  Future<int> markLivre(
    int id, {
    ({double lat, double lng})? position,
    DateTime? livreLe,
    String? preuvePhotoPath,
  }) async {
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
  }

  /// Marque un arret en echec + log dans StopHistory avec la raison.
  ///
  /// [preuvePhotoPath] (optionnel) : photo preuve d'un echec (ex: porte
  /// fermee, boite aux lettres pleine).
  Future<int> markEchec(
    int id,
    String raison, {
    ({double lat, double lng})? position,
    DateTime? livreLe,
    String? preuvePhotoPath,
  }) async {
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
  }

  /// Annule un statut deja pose + log la transition inverse.
  Future<int> markAaLivrer(int id) async {
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
        action: 'mark_a_livrer',
        fromStatus: previous.statutLivraison,
        toStatus: 'a_livrer',
      );
    }
    return n;
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
    return stops.firstWhere((s) => s.id == hist.stopId);
  }

  /// Annule le statut d'un stop : le remet a 'a_livrer' + reset
  /// raisonEchec + log dans l'historique.
  Future<void> revertStatus(int stopId) async {
    final stop = await getById(stopId);
    if (stop == null) return;
    await (_db.update(_db.stops)..where((s) => s.id.equals(stopId)))
        .write(StopsCompanion(
      statutLivraison: const Value('a_livrer'),
      raisonEchec: const Value(null),
      livreLat: const Value(null),
      livreLng: const Value(null),
      livreLe: const Value(null),
    ));
    await _logHistory(
      stopId: stopId,
      action: 'revert',
      fromStatus: stop.statutLivraison,
      toStatus: 'a_livrer',
    );
  }

  /// Applique l'ordre optimise calcule par le solveur : pour chaque
  /// stop, on ecrit `ordre_optimise = position dans la liste` (1-based).
  /// Tout est fait dans une transaction pour eviter un etat partiel.
  Future<void> applyOptimizedOrder(List<int> orderedStopIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedStopIds.length; i++) {
        await (_db.update(_db.stops)
              ..where((s) => s.id.equals(orderedStopIds[i])))
            .write(StopsCompanion(ordreOptimise: Value(i + 1)));
      }
    });
  }
}
