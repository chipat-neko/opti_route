import 'database.dart';

/// Wrapper type-safe sur la table `parametres` (cle/valeur).
///
/// Centralise les noms de cles pour eviter les fautes de frappe et
/// expose des helpers typed pour les parametres connus.
class ParametresRepository {
  ParametresRepository(this._db);

  final AppDatabase _db;

  // ─── Cles connues (constantes) ───────────────────────────────────
  static const _kOrsApiKey = 'ors_api_key';
  static const _kCapaciteDefault = 'vehicule_capacite_default';
  static const _kDureeArretDefault = 'duree_arret_default_min';
  static const _kNavAppDefault = 'nav_app_default';

  /// Cle API OpenRouteService (optimisation de tournees).
  Future<String?> getOrsApiKey() => _readKey(_kOrsApiKey);
  Stream<String?> watchOrsApiKey() => _watchKey(_kOrsApiKey);
  Future<void> setOrsApiKey(String value) =>
      _write(_kOrsApiKey, value.trim());
  Future<void> clearOrsApiKey() => _delete(_kOrsApiKey);

  /// Capacite par defaut du vehicule (en colis), prerempli a la
  /// creation d'une nouvelle tournee.
  Future<int?> getCapaciteDefault() async {
    final v = await _readKey(_kCapaciteDefault);
    return v == null ? null : int.tryParse(v);
  }

  Future<void> setCapaciteDefault(int value) =>
      _write(_kCapaciteDefault, value.toString());
  Future<void> clearCapaciteDefault() => _delete(_kCapaciteDefault);

  /// Duree par defaut d'un arret (en minutes), preremplie a la creation
  /// d'un nouvel arret.
  Future<int?> getDureeArretDefault() async {
    final v = await _readKey(_kDureeArretDefault);
    return v == null ? null : int.tryParse(v);
  }

  Future<void> setDureeArretDefault(int value) =>
      _write(_kDureeArretDefault, value.toString());
  Future<void> clearDureeArretDefault() => _delete(_kDureeArretDefault);

  /// App de navigation par defaut : 'maps' / 'waze' / null (demander
  /// a chaque fois). Si defini, l'app correspondante est mise en
  /// avant (bouton plein) dans la bottom sheet.
  Future<String?> getNavAppDefault() => _readKey(_kNavAppDefault);
  Stream<String?> watchNavAppDefault() => _watchKey(_kNavAppDefault);
  Future<void> setNavAppDefault(String value) =>
      _write(_kNavAppDefault, value);
  Future<void> clearNavAppDefault() => _delete(_kNavAppDefault);

  Future<String?> _readKey(String cle) async {
    final v = await _readRaw(cle);
    final trimmed = v?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Stream<String?> _watchKey(String cle) => _watchRaw(cle).map((v) {
        final trimmed = v?.trim();
        return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
      });

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
