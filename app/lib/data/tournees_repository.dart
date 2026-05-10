import 'package:drift/drift.dart';

import 'database.dart';

class TourneesRepository {
  TourneesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Tournee>> watchAll() {
    final query = _db.select(_db.tournees)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Future<Tournee?> getById(int id) {
    return (_db.select(_db.tournees)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(TourneesCompanion entry) {
    return _db.into(_db.tournees).insert(entry);
  }

  Future<int> update(int id, TourneesCompanion entry) {
    return (_db.update(_db.tournees)..where((t) => t.id.equals(id)))
        .write(entry);
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.tournees)..where((t) => t.id.equals(id))).go();
  }

  /// Efface les metadonnees d'optimisation d'une tournee : `optimiseeLe`,
  /// `distanceTotaleM`, `dureeTotaleS`, `traceGeojson`. A appeler des
  /// qu'une modification structurelle (ajout/suppr/edit d'arret, point
  /// de depart change) rend l'optim periment.
  ///
  /// Le `statut` n'est volontairement pas touche : si la tournee est
  /// `en_cours` ou `terminee`, on ne veut pas la faire repasser en
  /// `brouillon` -- on signale juste que l'itineraire calcule n'est
  /// plus a jour, et que le bouton "Optimiser" redevient cliquable.
  Future<int> invalidateOptimization(int id) {
    return (_db.update(_db.tournees)..where((t) => t.id.equals(id))).write(
      const TourneesCompanion(
        optimiseeLe: Value(null),
        distanceTotaleM: Value(null),
        dureeTotaleS: Value(null),
        traceGeojson: Value(null),
      ),
    );
  }
}
