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
  static const _kOnboardingDone = 'onboarding_done';
  static const _kOrsUsedCount = 'ors_used_count';
  static const _kOrsUsedDate = 'ors_used_date';
  static const _kThemeMode = 'theme_mode';
  static const _kLastCarnetExport = 'last_carnet_export_at';
  static const _kDailyReminderEnabled = 'daily_tournee_reminder';

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

  /// Onboarding du premier lancement : vrai si l'utilisateur a deja
  /// passe le walkthrough (cle ORS + tutoriel mini).
  Future<bool> isOnboardingDone() async {
    final v = await _readKey(_kOnboardingDone);
    return v == '1';
  }

  Stream<bool> watchOnboardingDone() =>
      _watchKey(_kOnboardingDone).map((v) => v == '1');

  Future<void> setOnboardingDone() => _write(_kOnboardingDone, '1');
  Future<void> resetOnboarding() => _delete(_kOnboardingDone);

  /// Compteur des optimisations OpenRouteService consommees aujourd'hui.
  /// Quota plan free : 500/jour. Affiche dans Parametres pour eviter
  /// la mauvaise surprise au milieu d'une tournee.
  ///
  /// On stocke 2 cles : `ors_used_count` (entier) et `ors_used_date`
  /// (YYYY-MM-DD). A chaque lecture/incrementation, si la date stockee
  /// != date du jour, on remet le compteur a zero.
  Future<int> getOrsUsedToday() async {
    final date = await _readKey(_kOrsUsedDate);
    final today = _todayIso();
    if (date != today) return 0;
    final v = await _readKey(_kOrsUsedCount);
    return int.tryParse(v ?? '') ?? 0;
  }

  Stream<int> watchOrsUsedToday() async* {
    // Stream basique : on emet a chaque changement de count OU de date.
    // En pratique, l'UI peut juste re-watch le count et l'UI re-render
    // a chaque incrementation, ce qui suffit pour notre cas.
    await for (final v in _watchKey(_kOrsUsedCount)) {
      final date = await _readKey(_kOrsUsedDate);
      if (date != _todayIso()) {
        yield 0;
      } else {
        yield int.tryParse(v ?? '') ?? 0;
      }
    }
  }

  /// Incremente le compteur d'utilisation ORS du jour. Si on bascule
  /// sur un nouveau jour, on reset a 1 (pas 0+1 -> on commence direct
  /// avec ce nouvel appel).
  Future<void> incrementOrsUsed() async {
    final today = _todayIso();
    final storedDate = await _readKey(_kOrsUsedDate);
    int next;
    if (storedDate != today) {
      next = 1;
    } else {
      final current = int.tryParse(
              (await _readKey(_kOrsUsedCount)) ?? '') ??
          0;
      next = current + 1;
    }
    await _write(_kOrsUsedCount, '$next');
    await _write(_kOrsUsedDate, today);
  }

  /// Mode de theme choisi par l'utilisateur :
  /// - `'system'` (default) : suit les reglages Android
  /// - `'light'` : force le mode clair
  /// - `'dark'` : force le mode sombre
  Future<String> getThemeMode() async {
    final v = await _readKey(_kThemeMode);
    return v ?? 'system';
  }

  Stream<String> watchThemeMode() =>
      _watchKey(_kThemeMode).map((v) => v ?? 'system');

  Future<void> setThemeMode(String mode) {
    assert(mode == 'system' || mode == 'light' || mode == 'dark');
    return _write(_kThemeMode, mode);
  }

  /// Timestamp ISO du dernier export du carnet (CSV ou PDF). Sert a
  /// afficher une banner "pense a sauvegarder" dans le carnet quand
  /// trop de temps s'est ecoule.
  Future<DateTime?> getLastCarnetExport() async {
    final v = await _readKey(_kLastCarnetExport);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Stream<DateTime?> watchLastCarnetExport() =>
      _watchKey(_kLastCarnetExport).map(
        (v) => v == null ? null : DateTime.tryParse(v),
      );

  Future<void> markCarnetExported() =>
      _write(_kLastCarnetExport, DateTime.now().toIso8601String());

  /// Rappel quotidien "tournee a preparer" : si actif, une notification
  /// locale est planifiee a heure fixe pour rappeler a Noah de verifier
  /// la tournee du lendemain.
  Future<bool> isDailyReminderEnabled() async {
    final v = await _readKey(_kDailyReminderEnabled);
    return v == '1';
  }

  Stream<bool> watchDailyReminderEnabled() =>
      _watchKey(_kDailyReminderEnabled).map((v) => v == '1');

  Future<void> setDailyReminderEnabled(bool enabled) =>
      _write(_kDailyReminderEnabled, enabled ? '1' : '0');

  static String _todayIso() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

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
