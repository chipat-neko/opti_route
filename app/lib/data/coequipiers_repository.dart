import 'package:drift/drift.dart';

import 'database.dart';

/// CRUD pour les coequipiers (aidants livraison locaux).
///
/// Pas de FK cascade : si on supprime un coequipier, les stops qui lui
/// etaient affectes gardent l'id en base (pour l'historique) mais le
/// resolveur UI affichera "Inconnu" ou rien.
class CoequipiersRepository {
  CoequipiersRepository(this._db);

  final AppDatabase _db;

  /// Stream de tous les coequipiers actifs, ordre alpha sur le nom.
  /// Sert au selecteur d'affectation dans la bottom sheet d'un stop.
  Stream<List<Coequipier>> watchActifs() {
    final query = _db.select(_db.coequipiers)
      ..where((c) => c.actif.equals(true))
      ..orderBy([(c) => OrderingTerm.asc(c.nom)]);
    return query.watch();
  }

  /// Stream de tous les coequipiers (actifs + archives). Pour l'UI de
  /// gestion dans Parametres.
  Stream<List<Coequipier>> watchAll() {
    final query = _db.select(_db.coequipiers)
      ..orderBy([
        // Actifs en haut, archives en bas.
        (c) => OrderingTerm.desc(c.actif),
        (c) => OrderingTerm.asc(c.nom),
      ]);
    return query.watch();
  }

  Future<List<Coequipier>> getAllActifs() {
    return (_db.select(_db.coequipiers)
          ..where((c) => c.actif.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.nom)]))
        .get();
  }

  Future<Coequipier?> getById(int id) {
    return (_db.select(_db.coequipiers)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create({
    required String nom,
    String? colorTag,
    String? telephone,
  }) {
    return _db.into(_db.coequipiers).insert(
          CoequipiersCompanion.insert(
            nom: nom.trim(),
            colorTag: Value(colorTag),
            telephone: Value(telephone?.trim()),
          ),
        );
  }

  /// Edition d'un coequipier. Seuls les champs fournis sont mis a jour.
  Future<int> update(
    int id, {
    String? nom,
    String? colorTag,
    String? telephone,
    bool? actif,
  }) {
    return (_db.update(_db.coequipiers)..where((c) => c.id.equals(id)))
        .write(CoequipiersCompanion(
      nom: nom == null ? const Value.absent() : Value(nom.trim()),
      colorTag: colorTag == null ? const Value.absent() : Value(colorTag),
      telephone: telephone == null
          ? const Value.absent()
          : Value(telephone.trim().isEmpty ? null : telephone.trim()),
      actif: actif == null ? const Value.absent() : Value(actif),
    ));
  }

  /// Toggle actif / archive sans toucher au reste. Sert au bouton
  /// "Archiver" / "Restaurer" dans la liste de Parametres.
  /// Atomique : read + write dans 1 transaction (eviter qu'un double-
  /// tap rapide flippe la valeur 2x).
  Future<int> toggleActif(int id) async {
    return _db.transaction(() async {
      final c = await getById(id);
      if (c == null) return 0;
      return update(id, actif: !c.actif);
    });
  }

  /// Supprime definitivement un coequipier. Les stops qui lui etaient
  /// affectes gardent leur `coequipierId` (l'UI affichera "Inconnu").
  Future<int> delete(int id) {
    return (_db.delete(_db.coequipiers)..where((c) => c.id.equals(id))).go();
  }

  /// COUNT(*) cote SQLite -- evite de charger toutes les lignes en RAM
  /// pour ensuite faire .length.
  Future<int> count() async {
    final col = _db.coequipiers.id.count();
    final row =
        await (_db.selectOnly(_db.coequipiers)..addColumns([col])).getSingle();
    return row.read(col) ?? 0;
  }
}
