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

  Future<int> delete(int id) {
    return (_db.delete(_db.stops)..where((s) => s.id.equals(id))).go();
  }

  /// Marque un arret comme livre + ecrit une ligne dans StopHistory
  /// pour tracer la transition (en cas de litige client).
  Future<int> markLivre(
    int id, {
    ({double lat, double lng})? position,
    DateTime? livreLe,
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
  Future<int> markEchec(
    int id,
    String raison, {
    ({double lat, double lng})? position,
    DateTime? livreLe,
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
