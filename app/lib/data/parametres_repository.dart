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
  static const _kCoutCarburantLitre = 'cout_carburant_litre_eur';
  static const _kConsoLitresPar100Km = 'conso_l_per_100km';
  static const _kDensiteUi = 'densite_ui';
  static const _kContrasteEleve = 'contraste_eleve';
  static const _kVeilleReminderHHmm = 'veille_reminder_hhmm';
  static const _kThemePreset = 'theme_preset';
  static const _kEntrepriseNom = 'entreprise_nom';
  static const _kEntrepriseSiret = 'entreprise_siret';
  static const _kEntrepriseSlogan = 'entreprise_slogan';
  static const _kModeChef = 'mode_chef_equipe';
  static const _kVerrouActif = 'verrou_actif';
  static const _kPinHash = 'pin_hash';
  static const _kBiometrieActive = 'biometrie_active';
  static const _kAutoLockMinutes = 'auto_lock_minutes';
  static const _kQuietHoursStart = 'quiet_hours_start';
  static const _kQuietHoursEnd = 'quiet_hours_end';
  static const _kAutoBackupPeriod = 'auto_backup_period';
  static const _kLastAutoBackupAt = 'last_auto_backup_at';

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
    // Atomique : sans transaction, deux appels concurrents (optim
    // VROOM + directions paralleles) verraient la meme valeur courante
    // et perdraient une incrementation.
    await _db.transaction(() async {
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
    });
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

  /// Cout du carburant en EUR/litre. Defaut commun France (gasoil
  /// hors stations autoroute) : 1.85 EUR/L au 2026-05-11. Sert au
  /// calcul du cout estime de la tournee.
  static const double defaultCoutCarburantLitre = 1.85;

  /// Consommation moyenne du vehicule en L/100km. Defaut : 7 L/100km
  /// (VUL diesel typique). Modifiable selon le vehicule de Noah.
  static const double defaultConsoLitresPar100Km = 7.0;

  Future<double> getCoutCarburantLitre() async {
    final v = await _readKey(_kCoutCarburantLitre);
    return double.tryParse(v ?? '') ?? defaultCoutCarburantLitre;
  }

  Future<void> setCoutCarburantLitre(double value) {
    return _write(_kCoutCarburantLitre, value.toStringAsFixed(3));
  }

  Future<double> getConsoLitresPar100Km() async {
    final v = await _readKey(_kConsoLitresPar100Km);
    return double.tryParse(v ?? '') ?? defaultConsoLitresPar100Km;
  }

  Future<void> setConsoLitresPar100Km(double value) {
    return _write(_kConsoLitresPar100Km, value.toStringAsFixed(2));
  }

  /// Densite de l'interface : 'normal' (defaut) ou 'large' (cibles
  /// tactiles agrandies + polices doublees, utile en mode conduite).
  Future<String> getDensiteUi() async =>
      (await _readKey(_kDensiteUi)) ?? 'normal';

  Stream<String> watchDensiteUi() =>
      _watchKey(_kDensiteUi).map((v) => v ?? 'normal');

  Future<void> setDensiteUi(String v) {
    assert(v == 'normal' || v == 'large');
    return _write(_kDensiteUi, v);
  }

  /// Mode contraste eleve : booleen. Renforce les bordures et les
  /// textes pour les conditions de lecture difficiles (soleil direct).
  Future<bool> getContrasteEleve() async =>
      (await _readKey(_kContrasteEleve)) == '1';

  Stream<bool> watchContrasteEleve() =>
      _watchKey(_kContrasteEleve).map((v) => v == '1');

  Future<void> setContrasteEleve(bool v) =>
      _write(_kContrasteEleve, v ? '1' : '0');

  /// Heure (format "HH:mm") du rappel veille a programmer
  /// automatiquement la veille de chaque tournee. Null = pas de
  /// rappel veille auto. Ex: "21:00" pour rappel a 21h le soir avant.
  Future<String?> getVeilleReminderHHmm() => _readKey(_kVeilleReminderHHmm);

  Stream<String?> watchVeilleReminderHHmm() =>
      _watchKey(_kVeilleReminderHHmm);

  Future<void> setVeilleReminderHHmm(String hhmm) =>
      _write(_kVeilleReminderHHmm, hhmm);

  Future<int> clearVeilleReminderHHmm() => _delete(_kVeilleReminderHHmm);

  /// Nom du preset de theme choisi par l'utilisateur
  /// ('lime' / 'ocean' / 'terracotta' / 'mono'). Defaut : 'lime'.
  Future<String> getThemePreset() async =>
      (await _readKey(_kThemePreset)) ?? 'lime';

  Stream<String> watchThemePreset() =>
      _watchKey(_kThemePreset).map((v) => v ?? 'lime');

  Future<void> setThemePreset(String preset) {
    assert(['lime', 'ocean', 'terracotta', 'mono'].contains(preset));
    return _write(_kThemePreset, preset);
  }

  /// Profil entreprise (optionnel) — affiche dans les exports PDF /
  /// texte. Le chef d'equipe peut renseigner sa raison sociale, son
  /// SIRET et un slogan court pour personnaliser les bordereaux
  /// imprimables qu'il distribue a ses coequipiers.
  Future<String?> getEntrepriseNom() => _readKey(_kEntrepriseNom);
  Stream<String?> watchEntrepriseNom() => _watchKey(_kEntrepriseNom);
  Future<void> setEntrepriseNom(String v) =>
      _write(_kEntrepriseNom, v.trim());
  Future<int> clearEntrepriseNom() => _delete(_kEntrepriseNom);

  Future<String?> getEntrepriseSiret() => _readKey(_kEntrepriseSiret);
  Future<void> setEntrepriseSiret(String v) =>
      _write(_kEntrepriseSiret, v.trim());
  Future<int> clearEntrepriseSiret() => _delete(_kEntrepriseSiret);

  Future<String?> getEntrepriseSlogan() => _readKey(_kEntrepriseSlogan);
  Future<void> setEntrepriseSlogan(String v) =>
      _write(_kEntrepriseSlogan, v.trim());
  Future<int> clearEntrepriseSlogan() => _delete(_kEntrepriseSlogan);

  /// Mode "chef d'equipe" : active une vue tableau de bord agregee
  /// (toutes les tournees du jour par coequipier) dans le drawer, et
  /// l'affectation en masse depuis la liste d'arrets. Par defaut false
  /// pour ne pas polluer l'UI d'un livreur solo.
  Future<bool> getModeChef() async =>
      (await _readKey(_kModeChef)) == '1';

  Stream<bool> watchModeChef() =>
      _watchKey(_kModeChef).map((v) => v == '1');

  Future<void> setModeChef(bool v) =>
      _write(_kModeChef, v ? '1' : '0');

  /// Verrouillage de l'app : si activ, un ecran PIN/biometrie s'affiche
  /// a l'ouverture (cold start) + au retour foreground apres N minutes
  /// (cf. [getAutoLockMinutes]). Default false : pas de verrou. Pour
  /// proteger les donnees clients (codes interphones, telephones,
  /// photos de preuve) si le phone est vole ou perdu.
  Future<bool> getVerrouActif() async =>
      (await _readKey(_kVerrouActif)) == '1';

  Stream<bool> watchVerrouActif() =>
      _watchKey(_kVerrouActif).map((v) => v == '1');

  Future<void> setVerrouActif(bool v) =>
      _write(_kVerrouActif, v ? '1' : '0');

  /// Hash SHA-256 du PIN choisi par l'utilisateur (4 a 6 chiffres). Le
  /// PIN en clair n'est jamais stocke. Null si verrou desactiv ou PIN
  /// pas encore defini.
  Future<String?> getPinHash() => _readKey(_kPinHash);

  Future<void> setPinHash(String hash) => _write(_kPinHash, hash);

  Future<int> clearPinHash() => _delete(_kPinHash);

  /// Biometrie (empreinte / face) activee en alternative au PIN. Demande
  /// quand meme un PIN comme fallback. Default false.
  Future<bool> getBiometrieActive() async =>
      (await _readKey(_kBiometrieActive)) == '1';

  Future<void> setBiometrieActive(bool v) =>
      _write(_kBiometrieActive, v ? '1' : '0');

  /// Duree (en minutes) avant auto-lock apres mise en background. 0 =
  /// jamais (verrouille seulement au cold start). Default 5 minutes.
  static const int defaultAutoLockMinutes = 5;

  Future<int> getAutoLockMinutes() async {
    final v = await _readKey(_kAutoLockMinutes);
    return int.tryParse(v ?? '') ?? defaultAutoLockMinutes;
  }

  Future<void> setAutoLockMinutes(int minutes) {
    assert(minutes >= 0 && minutes <= 60);
    return _write(_kAutoLockMinutes, minutes.toString());
  }

  /// Heure de debut du mode "ne pas deranger" au format "HH:mm".
  /// Null = quiet hours desactives. Pendant le creneau [start, end],
  /// `NotificationsService` skip les notifs locales (rappel veille,
  /// fin de tournee, etc.) pour ne pas vibrer pendant la pause-dejeuner
  /// ou la nuit.
  ///
  /// Cas particulier : si `start > end` (ex: 22h → 06h), le creneau
  /// passe minuit et couvre 22h..23:59 + 00:00..06h.
  Future<String?> getQuietHoursStart() => _readKey(_kQuietHoursStart);
  Stream<String?> watchQuietHoursStart() => _watchKey(_kQuietHoursStart);
  Future<void> setQuietHoursStart(String hhmm) =>
      _write(_kQuietHoursStart, hhmm);
  Future<int> clearQuietHoursStart() => _delete(_kQuietHoursStart);

  Future<String?> getQuietHoursEnd() => _readKey(_kQuietHoursEnd);
  Stream<String?> watchQuietHoursEnd() => _watchKey(_kQuietHoursEnd);
  Future<void> setQuietHoursEnd(String hhmm) => _write(_kQuietHoursEnd, hhmm);
  Future<int> clearQuietHoursEnd() => _delete(_kQuietHoursEnd);

  /// Vrai si l'heure [now] (defaut : maintenant) tombe dans le creneau
  /// quiet hours configure. Retourne false si l'un des 2 champs n'est
  /// pas defini (quiet hours desactives).
  ///
  /// Gere le cas "creneau qui passe minuit" : si start > end (22h →
  /// 06h), le creneau couvre 22h..minuit + minuit..06h.
  ///
  /// Pour les tests : passer [now] explicitement pour figer l'heure.
  Future<bool> isQuietHoursNow({DateTime? now}) async {
    final start = await getQuietHoursStart();
    final end = await getQuietHoursEnd();
    if (start == null || end == null) return false;
    return isWithinQuietHours(
      now: now ?? DateTime.now(),
      startHHmm: start,
      endHHmm: end,
    );
  }

  /// Version pure / testable de la logique quiet hours. Sans I/O,
  /// utilise par les tests et par `isQuietHoursNow`.
  ///
  /// Retourne false si l'un des 2 formats HH:mm est invalide.
  /// `start == end` est traite comme "creneau vide" (jamais quiet).
  static bool isWithinQuietHours({
    required DateTime now,
    required String startHHmm,
    required String endHHmm,
  }) {
    final s = _parseMinutes(startHHmm);
    final e = _parseMinutes(endHHmm);
    if (s == null || e == null) return false;
    if (s == e) return false; // creneau vide
    final m = now.hour * 60 + now.minute;
    if (s < e) {
      // Creneau dans la meme journee : [s, e)
      return m >= s && m < e;
    } else {
      // Creneau qui passe minuit (ex: 22h -> 06h) : [s, 24h) U [0, e)
      return m >= s || m < e;
    }
  }

  static int? _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Parse une chaine "HH:mm" en tuple (hour, minute) ou retourne null
  /// si le format est invalide. Helper expose pour les widgets qui
  /// veulent reutiliser cette logique (TimePicker initialTime).
  static ({int hour, int minute})? parseHHmm(String? hhmm) {
    if (hhmm == null) return null;
    final mins = _parseMinutes(hhmm);
    if (mins == null) return null;
    return (hour: mins ~/ 60, minute: mins % 60);
  }

  /// Periode du backup auto local. Valeurs : 'jamais' (defaut) /
  /// 'hebdo' / 'mensuel'. Cf [AutoBackupService] pour le declenchement
  /// au boot. Pas de typage strict (enum) volontairement -- les
  /// valeurs sont stockees telles quelles dans la table parametres,
  /// flexibles pour l'avenir.
  Future<String> getAutoBackupPeriod() async {
    return (await _readKey(_kAutoBackupPeriod)) ?? 'jamais';
  }

  Stream<String> watchAutoBackupPeriod() =>
      _watchKey(_kAutoBackupPeriod).map((v) => v ?? 'jamais');

  Future<void> setAutoBackupPeriod(String value) {
    assert(['jamais', 'hebdo', 'mensuel'].contains(value));
    return _write(_kAutoBackupPeriod, value);
  }

  /// Timestamp du dernier backup auto reussi (ISO8601). Sert au
  /// service a savoir si la periode est atteinte. Null = aucun
  /// backup auto encore execute.
  Future<DateTime?> getLastAutoBackupAt() async {
    final raw = await _readKey(_kLastAutoBackupAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastAutoBackupAt(DateTime when) =>
      _write(_kLastAutoBackupAt, when.toIso8601String());

  /// Estime le cout carburant d'une distance (en metres) selon les
  /// parametres courants. Retourne en EUR (double, arrondi a 0.01).
  Future<double> estimerCoutCarburant({required int distanceMeters}) async {
    final coutLitre = await getCoutCarburantLitre();
    final conso = await getConsoLitresPar100Km();
    final litres = (distanceMeters / 1000) * (conso / 100);
    return litres * coutLitre;
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
