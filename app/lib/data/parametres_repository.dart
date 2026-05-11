import 'database.dart';
import 'tour_assistant/assistant_suggestion.dart';

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
  // TourAssistant (cles dynamiques par kind, prefixe + nom enum)
  static const _kAssistantEnabled = 'assistant_enabled';
  static const _kAssistantProximityEnabled = 'assistant_proximity_enabled';
  static const _kAssistantProximityThresholdM = 'assistant_proximity_threshold_m';
  static const _kAssistantCooldownMin = 'assistant_cooldown_minutes';
  static const _kAssistantAcceptPrefix = 'assistant_accept_';
  static const _kAssistantRefusePrefix = 'assistant_refuse_';

  static const int _defaultProximityThresholdM = 300;
  static const int _defaultCooldownMin = 5;

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

  // ─── TourAssistant (systeme expert d'aide a la tournee) ──────────

  /// Master switch : si false, aucune suggestion n'est produite.
  Future<bool> isAssistantEnabled() async {
    final v = await _readKey(_kAssistantEnabled);
    return v != '0'; // default true (si jamais ecrit, on est actif)
  }

  Stream<bool> watchAssistantEnabled() =>
      _watchKey(_kAssistantEnabled).map((v) => v != '0');

  Future<void> setAssistantEnabled(bool enabled) =>
      _write(_kAssistantEnabled, enabled ? '1' : '0');

  /// Toggle de la regle "proximity" (livrer au passage GPS).
  Future<bool> isAssistantProximityEnabled() async {
    final v = await _readKey(_kAssistantProximityEnabled);
    return v != '0';
  }

  Stream<bool> watchAssistantProximityEnabled() =>
      _watchKey(_kAssistantProximityEnabled).map((v) => v != '0');

  Future<void> setAssistantProximityEnabled(bool enabled) =>
      _write(_kAssistantProximityEnabled, enabled ? '1' : '0');

  /// Rayon en metres pour la regle proximity. Ajuste automatiquement
  /// par AssistantCalibration. Default 300, plage [100, 800].
  Future<int> assistantProximityThresholdM() async {
    final v = await _readKey(_kAssistantProximityThresholdM);
    return int.tryParse(v ?? '') ?? _defaultProximityThresholdM;
  }

  Stream<int> watchAssistantProximityThresholdM() =>
      _watchKey(_kAssistantProximityThresholdM)
          .map((v) => int.tryParse(v ?? '') ?? _defaultProximityThresholdM);

  Future<void> setAssistantProximityThresholdM(int meters) =>
      _write(_kAssistantProximityThresholdM, meters.toString());

  /// Minutes avant qu'une suggestion refusee pour un (kind, stopId)
  /// soit a nouveau proposable. Default 5 min.
  Future<int> assistantCooldownMinutes() async {
    final v = await _readKey(_kAssistantCooldownMin);
    return int.tryParse(v ?? '') ?? _defaultCooldownMin;
  }

  Future<void> setAssistantCooldownMinutes(int minutes) =>
      _write(_kAssistantCooldownMin, minutes.toString());

  /// Incremente le compteur accept ou refuse pour un kind donne. Sert
  /// a la calibration progressive.
  Future<void> assistantIncrement(
    SuggestionKind kind, {
    required bool accept,
  }) async {
    final key = (accept ? _kAssistantAcceptPrefix : _kAssistantRefusePrefix) +
        kind.name;
    final v = int.tryParse((await _readKey(key)) ?? '') ?? 0;
    await _write(key, (v + 1).toString());
  }

  Future<int> assistantAcceptCount(SuggestionKind kind) async {
    final v = await _readKey(_kAssistantAcceptPrefix + kind.name);
    return int.tryParse(v ?? '') ?? 0;
  }

  Future<int> assistantRefuseCount(SuggestionKind kind) async {
    final v = await _readKey(_kAssistantRefusePrefix + kind.name);
    return int.tryParse(v ?? '') ?? 0;
  }

  /// Reset les 2 compteurs (accept + refuse) pour un kind. Appele
  /// apres un ajustement de seuil dans AssistantCalibration.
  Future<void> assistantResetCounters(SuggestionKind kind) async {
    await _delete(_kAssistantAcceptPrefix + kind.name);
    await _delete(_kAssistantRefusePrefix + kind.name);
  }

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
