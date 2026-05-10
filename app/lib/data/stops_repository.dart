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

  /// Marque un arret comme livre. Reset la raison d'echec si elle
  /// avait ete remplie precedemment.
  Future<int> markLivre(int id) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(id))).write(
      const StopsCompanion(
        statutLivraison: Value('livre'),
        raisonEchec: Value(null),
      ),
    );
  }

  /// Marque un arret en echec avec une raison ('absent', 'refuse',
  /// 'adresse_fausse', 'autre').
  Future<int> markEchec(int id, String raison) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(id))).write(
      StopsCompanion(
        statutLivraison: const Value('echec'),
        raisonEchec: Value(raison),
      ),
    );
  }

  /// Annule un statut deja pose : remet en 'a_livrer'.
  Future<int> markAaLivrer(int id) {
    return (_db.update(_db.stops)..where((s) => s.id.equals(id))).write(
      const StopsCompanion(
        statutLivraison: Value('a_livrer'),
        raisonEchec: Value(null),
      ),
    );
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
