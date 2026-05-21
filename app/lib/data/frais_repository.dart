import 'package:drift/drift.dart';

import 'database.dart';

/// CRUD pour les notes de frais (carburant / peages / parking / repas /
/// autre). Voir `tables/frais.dart` pour le schema.
///
/// Filtres pratiques : par mois (utile pour la compta), par tournee
/// (calcul marge brute), et stream global trie date desc pour la liste.
class FraisRepository {
  FraisRepository(this._db);

  final AppDatabase _db;

  /// Stream de tous les frais, du plus recent au plus ancien.
  Stream<List<Frai>> watchAll() {
    final query = _db.select(_db.frais)
      ..orderBy([(f) => OrderingTerm.desc(f.date)]);
    return query.watch();
  }

  /// Stream des frais d'un mois donne (year, month 1-12). Sert a la vue
  /// "Frais du mois" et au total mensuel par categorie.
  Stream<List<Frai>> watchByMonth(int year, int month) {
    final start = DateTime(year, month);
    // Premier jour du mois suivant -> borne haute exclusive.
    final end = DateTime(year, month + 1);
    final query = _db.select(_db.frais)
      ..where((f) =>
          f.date.isBiggerOrEqualValue(start) & f.date.isSmallerThanValue(end))
      ..orderBy([(f) => OrderingTerm.desc(f.date)]);
    return query.watch();
  }

  /// Stream des frais rattaches a une tournee. Pour la card "Frais
  /// imputes" dans l'ecran d'une tournee (calcul marge brute).
  Stream<List<Frai>> watchByTournee(int tourneeId) {
    final query = _db.select(_db.frais)
      ..where((f) => f.tourneeId.equals(tourneeId))
      ..orderBy([(f) => OrderingTerm.desc(f.date)]);
    return query.watch();
  }

  Future<Frai?> getById(int id) {
    return (_db.select(_db.frais)..where((f) => f.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create({
    required DateTime date,
    required String type,
    required int montantCentimes,
    required String libelle,
    String? notes,
    int? tourneeId,
    String? photoPath,
  }) {
    return _db.into(_db.frais).insert(
          FraisCompanion.insert(
            date: date,
            type: type.trim(),
            montantCentimes: montantCentimes,
            libelle: libelle.trim(),
            notes: Value(notes?.trim()),
            tourneeId: Value(tourneeId),
            photoPath: Value(photoPath),
          ),
        );
  }

  /// Edition d'un frais. Tous les champs sont optionnels sauf l'id.
  /// On ne touche pas a `creeLe`. Met `updatedAt = now` automatiquement
  /// via le trigger AFTER UPDATE (cf database.dart _createUpdatedAtTriggers).
  Future<int> update(
    int id, {
    DateTime? date,
    String? type,
    int? montantCentimes,
    String? libelle,
    String? notes,
    int? tourneeId,
    String? photoPath,
    bool clearTournee = false,
    bool clearPhoto = false,
    bool clearNotes = false,
  }) {
    return (_db.update(_db.frais)..where((f) => f.id.equals(id))).write(
      FraisCompanion(
        date: date == null ? const Value.absent() : Value(date),
        type: type == null ? const Value.absent() : Value(type.trim()),
        montantCentimes: montantCentimes == null
            ? const Value.absent()
            : Value(montantCentimes),
        libelle: libelle == null ? const Value.absent() : Value(libelle.trim()),
        notes: clearNotes
            ? const Value(null)
            : (notes == null ? const Value.absent() : Value(notes.trim())),
        tourneeId: clearTournee
            ? const Value(null)
            : (tourneeId == null ? const Value.absent() : Value(tourneeId)),
        photoPath: clearPhoto
            ? const Value(null)
            : (photoPath == null
                ? const Value.absent()
                : Value(photoPath)),
      ),
    );
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.frais)..where((f) => f.id.equals(id))).go();
  }

  /// Total des frais (en centimes) sur une periode. Si [type] est non
  /// null, filtre sur ce type uniquement (sinon tous types confondus).
  /// Calcul SQL pour eviter de charger toutes les lignes.
  Future<int> totalCentimes({
    required DateTime from,
    required DateTime to,
    String? type,
  }) async {
    final sum = _db.frais.montantCentimes.sum();
    final query = _db.selectOnly(_db.frais)..addColumns([sum]);
    query.where(_db.frais.date.isBiggerOrEqualValue(from) &
        _db.frais.date.isSmallerThanValue(to));
    if (type != null) {
      query.where(_db.frais.type.equals(type));
    }
    final row = await query.getSingle();
    return (row.read(sum) ?? 0).toInt();
  }
}
