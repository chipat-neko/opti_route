import 'package:drift/drift.dart';

import 'database.dart';

/// CRUD pour les feuilles d'expediteurs (`Sheet`) attachees a un `Stop`.
class SheetsRepository {
  SheetsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Sheet>> watchByStop(int stopId) {
    final query = _db.select(_db.sheets)
      ..where((s) => s.stopId.equals(stopId))
      ..orderBy([(s) => OrderingTerm.asc(s.id)]);
    return query.watch();
  }

  Future<List<Sheet>> getByStop(int stopId) {
    return (_db.select(_db.sheets)..where((s) => s.stopId.equals(stopId))).get();
  }

  Future<Sheet?> getById(int id) {
    return (_db.select(_db.sheets)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(SheetsCompanion entry) {
    return _db.into(_db.sheets).insert(entry);
  }

  Future<int> update(int id, SheetsCompanion entry) {
    return (_db.update(_db.sheets)..where((s) => s.id.equals(id))).write(entry);
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.sheets)..where((s) => s.id.equals(id))).go();
  }

  /// Total des colis pour un stop = somme des `nb_colis` de toutes ses
  /// sheets. Utile pour rafraichir `stops.nb_colis` ou afficher un total
  /// dans l'UI.
  Future<int> totalColisForStop(int stopId) async {
    final sheets = await getByStop(stopId);
    return sheets.fold<int>(0, (sum, s) => sum + s.nbColis);
  }
}
