import 'database.dart';

/// Wrapper type-safe sur la table `parametres` (cle/valeur).
///
/// Centralise les noms de cles pour eviter les fautes de frappe et
/// expose des helpers typed pour les parametres connus.
class ParametresRepository {
  ParametresRepository(this._db);

  final AppDatabase _db;

  // ─── Cles connues (constantes) ───────────────────────────────────
  static const _kTomTomApiKey = 'tomtom_api_key';

  /// Cle API TomTom (peut etre null = non configure).
  Future<String?> getTomTomApiKey() async {
    final v = await _readRaw(_kTomTomApiKey);
    final trimmed = v?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Stream reactif sur la cle TomTom : utile pour que le provider
  /// Riverpod du geocoder se reinstancie quand la cle change.
  Stream<String?> watchTomTomApiKey() => _watchRaw(_kTomTomApiKey).map((v) {
        final trimmed = v?.trim();
        return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
      });

  Future<void> setTomTomApiKey(String value) =>
      _write(_kTomTomApiKey, value.trim());

  Future<void> clearTomTomApiKey() => _delete(_kTomTomApiKey);

  // ─── Helpers internes ────────────────────────────────────────────
  Future<String?> _readRaw(String cle) async {
    final row = await (_db.select(_db.parametres)
          ..where((p) => p.cle.equals(cle)))
        .getSingleOrNull();
    return row?.valeur;
  }

  Stream<String?> _watchRaw(String cle) {
    final query = _db.select(_db.parametres)
      ..where((p) => p.cle.equals(cle));
    return query.watchSingleOrNull().map((row) => row?.valeur);
  }

  Future<void> _write(String cle, String valeur) {
    return _db.into(_db.parametres).insertOnConflictUpdate(
          ParametresCompanion.insert(cle: cle, valeur: valeur),
        );
  }

  Future<int> _delete(String cle) {
    return (_db.delete(_db.parametres)..where((p) => p.cle.equals(cle))).go();
  }
}
