# Changelog

Toutes les modifications notables du projet sont consignées dans ce fichier.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Non publié]

### Session 2026-08-13 — Fin de l'audit v2 + branchements (#533-#548)

Seize PR mergées les 2026-08-13 et 2026-08-14. Aucune release :
`pubspec` reste en **2.9.3+10071**, mais le tag **`v2.9.3`** manquant a
été posé rétroactivement sur `1514866` (le repo n'avait aucun tag, on
ne pouvait donc pas retrouver le commit exact d'un build livré).

**Sécurité et chaîne de build**
- **#533** : les **15 références `uses:`** des trois workflows sont
  épinglées par SHA de commit. Les refs flottants résolvaient déjà sur
  ces commits, donc le changement est iso-comportement. À noter :
  `denoland/setup-deno@v2` n'était pas un tag mais une **branche**,
  encore plus mutable qu'un tag. Nouveau `build-android.yml`
  (`workflow_dispatch`) : c'était le seul chemin de build qui ne
  strippait pas les fixtures OCR, et il **échoue désormais si l'AAB en
  contient encore**. `build.gradle.kts` sait lire le `key.properties`
  depuis `~/keystores/opti_route/` ou `$OPTIROUTE_KEY_PROPERTIES`, ce
  qui permet de sortir la keystore de l'arbre du repo machine par
  machine.
- **#548** : AGP monté à **8.12.1**, prérequis de `battery_plus` 7. Le
  bump Dependabot aurait cassé le build Android sans qu'aucun job de CI
  ne le voie.

**Cloud**
- **#535** : CORS restreint sur les trois Edge Functions (allow-list +
  `Vary: Origin`) ; `cron_lockout_revoked` n'émet plus d'en-tête du
  tout, étant appelée par pg_cron. Le job pg_cron est enfin versionné
  dans une migration : une recréation de base le perdait en silence.
  ⚠️ Ne prend effet qu'après redéploiement manuel des fonctions.

**Code mort**
- **#537** : suppression de **9 modules** de `lib/data/` sans aucune
  référence hors tests, chacun doublonnant du code vivant — 466 lignes
  de lib et 478 de test. Retire au passage une collision de type
  (`FuelStation` était déclarée deux fois). Le triage complet des 36
  modules concernés est dans
  [`docs/modules-non-branches.md`](docs/modules-non-branches.md) ; il
  corrige le constat d'origine, qui annonçait trois doublons dont un
  seul en était réellement un.

**Fonctionnalités branchées** (modules qui existaient sans appelant)
- **#539, #542** : bandeau « tu es à X m d'un arrêt à livrer », avec
  bouton « marquer livré » en 1 tap. Masqué quand l'arrêt le plus
  proche est déjà celui de la carte du prochain arrêt.
- **#545** : au scan d'un colis, alerte si le numéro de suivi a déjà
  été livré, et contrôle du bon arrêt via la nouvelle entrée « scanner
  le colis de cet arrêt ». L'alerte prévient, elle ne bloque jamais.
- **#547** : dossier litige opposable depuis un arrêt livré. Le hash
  SHA-256 couvre désormais **les octets de la photo** et plus seulement
  le texte — sans quoi la preuve pouvait être remplacée sans que la
  signature bouge. Rien ne quitte l'app sans confirmation explicite.

**Corrections**
- **#540** : quatre bugs préexistants — `periodeCutoff('6m')` valait
  180 jours et non 6 mois calendaires, le filtre « jamais réutilisés »
  ratait les fiches à `useCount = 0`, une livraison à 23 h produisait
  une fenêtre horaire vide, et `poi_detour` rendait un index dans sa
  liste filtrée. Deux autres anomalies suspectées n'en étaient pas et
  sont documentées comme telles.
- **#543** : un swipe sur le dernier arrêt suivi d'une fermeture
  d'écran ne clôturait jamais la tournée.
- **#544, #546** : « Tout livrer » et les commandes vocales passent par
  le service commun. Corrige au passage que la voix n'enregistrait
  aucune position GPS et ne terminait jamais une tournée, et que
  l'annulation d'un statut laissait une tournée « terminée » avec un
  arrêt à livrer.

**Structure et tests**
- **#538** : `carnet_adresses_screen` passe de 1080 à 220 lignes et
  `entreprise_multi_tenant_section` de 1137 à 319, sur le modèle de
  `tournee_du_jour/`. Les quatre services de sauvegarde, statistiques
  et résumé hebdomadaire acceptent une horloge injectable, ce qui rend
  testables des cas de bord qui ne l'étaient pas.
- **#541** : `scripts/handoff-pc.ps1` et
  [`docs/handoff-pc-console.md`](docs/handoff-pc-console.md)
  regroupent ce qui ne peut être fait que sur le PC principal ou en
  console.

### Session 2026-07-12 — Audit v2 appliqué (#511-#532)

Suite de l'audit qualité (référentiel `fable.md` F1-F47 / `task.md`),
appliquée en **douze PR mergées** entre le 2026-07-12 et le 2026-07-13
(#511 à #521, puis #532). Aucune release : `pubspec` reste en
**2.9.3+10071**, aucun tag créé.

**CI/CD**
- **#511** (2026-07-12) : `deploy-web.yml` et `build-windows.yml`
  épinglés sur **Flutter 3.41.9** — le site Pages et l'exe Windows
  livrés étaient compilés avec un `channel: stable` flottant jamais
  passé par `analyze`/`test`. `ci.yml` durci au passage
  (`permissions: contents: read`, bloc `concurrency` avec
  `cancel-in-progress` en PR, `timeout-minutes` sur les deux jobs).
- **#519** (2026-07-13) : **build Windows réparé** (rouge depuis
  ~2026-07-05, indépendamment de l'audit). `runs-on` épinglé sur
  **`windows-2022`** : le toolchain de `windows-latest` était passé en
  préversion (VS 18 / MSVC 14.51), qui transforme la dépréciation de
  `<experimental/coroutine>` en erreur dure STL1011 et cassait
  `flutter_local_notifications_windows` et `local_auth_windows`. Le
  garde-fou `CMAKE_POLICY_VERSION_MINIMUM=3.5` est conservé pour le
  sous-build pdfium, refusé par CMake 4.x.
- **#520** (2026-07-13) : nouveau job `build-web` déclenché **dès la
  PR** (`deploy-web.yml` ne tourne que sur push `main`), étape
  « Coverage summary » qui parse le lcov (LH/LF) dans
  `$GITHUB_STEP_SUMMARY`, et `.github/dependabot.yml` (écosystèmes
  `pub` sur `/app` et `github-actions` sur `/`, hebdo, avec `ignore`
  sur les pins délibérés `receive_sharing_intent` et
  `sqlite3_flutter_libs`).
- **#532** (2026-07-13, volet CI) : `dart run build_runner build
  --delete-conflicting-outputs` ajouté avant les **trois workflows de
  build** (`build-web` de `ci.yml`, `deploy-web`, `build-windows`), qui
  compilaient jusque-là le `database.g.dart` commité **sans le
  régénérer** — un `.g.dart` désynchronisé du schéma source cassait ces
  builds alors que le schéma était correct. Le job `flutter` le faisait
  déjà avant `analyze`/`test`.

**Sécurité / confidentialité**
- **#512** (2026-07-12) : `USE_EXACT_ALARM` retiré du manifest Android
  (permission réservée aux apps réveil/agenda, risque de rejet Play
  Store) ; `SCHEDULE_EXACT_ALARM` et
  `requestExactAlarmsPermission()` conservés.
- **#516** (2026-07-12) : les quatre `zonedSchedule` ne partaient plus
  en `exactAllowWhileIdle` sans garde — sur Android 12+ (autorisation
  « Alarmes et rappels » révoquée) et 14+ le plugin remontait une
  `PlatformException` non gérée qui faisait crasher le rappel. Helper
  `_zonedScheduleSafe` : repli en `inexactAllowWhileIdle`.
- **#514** (2026-07-12) : `.env*` ajouté au `.gitignore` racine ;
  capture de l'erreur du 3ᵉ update dans `cron_lockout_revoked`
  (invitations).

**Performance / fiabilité**
- **#515** (2026-07-12) : `statsBundleProvider` et ses deux dérivés
  (`statsFromBundle`, `statsPreviousWindow`) passés en `autoDispose`
  **ensemble** — plus de recalcul de 365 j de stats à chaque écriture
  DB quand `StatsScreen` est fermé ; `BordereauMlClassifier` (~1,9 Mo
  de JSON, 100 arbres) chargé en lazy à l'ouverture de l'écran de scan
  au lieu du boot de l'app ; `coutCarburantProvider` et
  `resumeHebdoProvider` passés en `autoDispose.family` (fuite
  d'instances par valeur de clé) ; garde `mounted` dans
  `_exitSelection` du carnet et `DateFormat` hissés en `static final`.
- **#515** : correction du bug de recherche **« œ »** — la clé `'œ'` de
  `_normalize` était un mojibake de 2 caractères jamais matché par
  `split('')`, si bien que chercher « oeuvre » ne trouvait pas
  « Œuvre » (carnet d'adresses et liste d'arrêts).
- **#517** (2026-07-12) : `currentPositionProvider` (StreamProvider
  passif, distinct du stream haute précision de `navigation_screen`)
  restait souscrit au GPS app en arrière-plan. Souscription geolocator
  coupée en background et reprise au premier plan via
  `ref.listen(appForegroundProvider)`, en conservant la dernière
  `Position` pour éviter un flash de distance au retour.
- **#518** (2026-07-12) : `route_metrics_auto_updater` réécrivait
  distance/durée même identiques à la base ; le write drift renotifiait
  le stream tournée, ce qui relançait une requête OSRM en boucle. Garde
  d'idempotence + test de non-régression sur le compte d'émissions du
  stream. Le volet 2 (sortir `requestUpdate` du `build` via
  `ref.listen`) est volontairement différé.
- **#512** : `RouteService.close()` + `ref.onDispose` sur
  `routeServiceProvider` — son `http.Client` n'était jamais fermé,
  contrairement aux autres services.

**Purge de code mort**
- **#512** : l'action `GenerateTrackingLinkAction` retirée de l'UI — la
  feature « lien de suivi colis » est abandonnée (domaine jamais
  acheté) et le bouton copiait encore des liens morts. La couche
  Drift/repo/Edge restait en place à ce stade.
- **#532** : purge complète en trois volets.
  - *Suivi colis (F5)* : suppression de `tracking_codes_repository`,
    `tables/tracking_codes.dart` et leurs tests, de
    `supabase/functions/track/` et son test Deno, de
    `site_doc/suivi.html`, des constantes `kTrackingDomain` /
    `kTrackingCodeLength`, de `pushTrackingCode`, du provider et de la
    section `[functions.track]` de `config.toml`. Le scan colis vivant
    (`tracking_numbers` / `bordereau_patterns`) n'est **pas** touché.
  - *Table `sheets` (F29)*, morte depuis la v2 : repo, table et tests
    supprimés, sortie du `@DriftDatabase`.
  - *Providers morts (F30)* : `carnetPrivees`, `fraisAll`,
    `fraisByTournee`, `entrepriseNom`, `tourneeMembres`,
    `sheetsRepository` et `watchEntrepriseNom`.
- **#532** — **migration Drift v52** (`schemaVersion` 51 → 52) :
  `DROP TABLE IF EXISTS tracking_codes` et `sheets`, plus la création
  des **index `cloud_id`** manquants (F19) via un helper
  `_createCloudIdIndexes` appelé aussi en `onCreate`. Sentinelles de
  migration 51 → 52 mises à jour.
- **Reste à faire hors CI** (documenté dans la PR #532) : régénérer
  `database.g.dart` sur PC (`dart run build_runner build
  --delete-conflicting-outputs`) et le commiter pour que les builds
  locaux soient cohérents ; côté Supabase, supprimer la fonction
  `track` déployée et jouer le `drop table` en prod. Différés : F28
  (modules morts) et F34 (Edge `accept_invitation`).

**Tests**
- **#521** (2026-07-13) : helper `app/test/helpers/test_db.dart`
  (`makeTestDb()` + `seedTournee()`) pour arrêter de recopier
  `AppDatabase(NativeDatabase.memory())` partout (F46) ;
  `app/test/data/schema_integrity_test.dart` qui vérifie via
  `db.allTables` vs `sqlite_master` que toutes les tables du
  `@DriftDatabase` sont bien créées à l'ouverture, en auto-adaptatif
  (pas de liste codée en dur) + round-trip + `schemaVersion` (F18) ; le
  test de timeout de `route_service_test`, qui tournait ~15 s réelles,
  passé en `fake_async` (F45) — `fake_async` déclaré en
  `dev_dependency`.

**Documentation**
- **#513** (2026-07-12) : README de l'Edge Function `invite_employee`
  réécrit — il documentait encore le flux magic-link supprimé lors de
  la refonte du 2026-06-01 et ne mentionnait aucun des secrets Brevo
  requis par le code, si bien qu'une réinstallation en le suivant
  cassait l'invitation d'employé. Le vrai flux (code à 6 chiffres
  CSPRNG, envoi Brevo, RPC `accept_entreprise_invitation`), le body, la
  réponse, le tableau des secrets, `verify_jwt=true` et la commande de
  déploiement sont désormais décrits.
- **#514** : nettoyage documentaire — section 2026-07-08 du CHANGELOG,
  `ARCHITECTURE` (lien mort `docs/plan-ocr-85pct.md` retiré,
  `supabase/migrations/` ajouté à l'arborescence), `docs/*.sql` marqués
  ARCHIVE (source canonique = `supabase/migrations/`), section RLS
  multi-tenant ajoutée à `docs/supabase-rls.md`, wiki-links morts
  retirés de `scripts/README`, chemins CSV du pipeline ML corrigés vers
  `tools/data/`, `web/index.html` débrandé et raccourcis PWA morts
  retirés du manifest, commentaire erroné corrigé dans
  `frais_repository`.

### Session 2026-07-08 — Audit qualité appliqué (#501-#510) + release 2.9.3

Audit qualité v2 appliqué en dix PR, clôturé par la release
**2.9.3+10071** :
- **#501** : strip des fixtures PII `test_bordereaux` dans les
  workflows web/Windows (RGPD).
- **#502** : documentation actualisée (`CHANGELOG` / `ARCHITECTURE` /
  `README`).
- **#503** : versioning **2.9.3+10071** (`pubspec` source de vérité du
  `versionCode`) et msix **2.9.3.0**.
- **#504** : hygiène (mémoïsation du tracé carte, script de build
  portable, `catch` commentés).
- **#505** : index `docs/README.md` et `CODEOWNERS`.
- **#506** : battery monitor conditionné à la tournée active.
- **#507** : seuil de 15 m avant recentrage caméra en navigation.
- **#508** : +6 smoke tests widget.
- **#509** : `autoDispose` sur `orsUsedToday` / `pendingGeocodeCount`.
- **#510** : `supabase/migrations/` (schéma cloud rejouable).

### Session 2026-07-05 (audit complet #499 + optimisations batterie #500)

**Audit qualité complet (#499)** — corrections issues de l'audit
2026-06-11 :
- **OCR** : parser dédié **France Alliance** branché dans le routage de
  détection de format, avec tests.
- **ML classifier** : pipeline resynchronisé — l'app n'embarque plus
  l'artefact ONNX (~1,5 MB) mais uniquement le JSON exporté ;
  `app/assets/ml/features.json` fait foi et un test garde-fou
  (`bordereau_ml_features_sync_test`) échoue en CI si l'inférence Dart
  et le Python divergent.
- **APK allégé (−24 MB)** : les fixtures OCR `assets/test_bordereaux/`
  (scans de bordereaux clients réels) sont retirées du build APK release
  (`scripts/build-and-install.ps1`).
- **Mémoire/cycles** : `autoDispose` appliqué aux providers de flux qui
  n'ont pas à survivre à leur écran.
- **Ménage repo** : suppression des dossiers morts `opti_route_web/` et
  `site_docv2/`.
- **+68 tests** ; `flutter analyze` : 0 issue.

**Optimisations batterie sans exemption système (#500)** :
- Plafond de cadence GPS Android via `AndroidSettings.intervalDuration`
  et profils d'usage (`lib/data/location_tuning.dart` :
  navigation / présence / passive).
- `currentPositionProvider` passé en `autoDispose` ; le stream GPS de
  navigation est instancié une seule fois (hors `build`).
- `wakelock_plus` relâché dès le passage en arrière-plan et réactivé au
  retour au premier plan (`AppLifecycleState`).
- Présence live du chef en précision moyenne ; capteur de luminosité et
  push de présence suspendus en arrière-plan via `appForegroundProvider`
  (fonction pure `isAppBackground` : `paused`/`hidden` = arrière-plan).
- **+18 tests**. CI enrichie : job `deno test` (Edge Functions) +
  `flutter test --coverage` avec artifact lcov.

### Session 2026-06-04 (plans #381-A, confidentialité Play Store, fix AAB)

- **Fondation « plans » #381-A** (#496) : socle neutre côté app, **aucun
  bridage** de fonctionnalité (simple badge informatif). Release
  **v2.9.2+8065** ; `msix_version` bumpée `2.9.2.13 → .14` pour permettre
  la réinstallation Windows.
- **Confidentialité Play Store** (#497) : politique de confidentialité
  adaptée aux exigences Google Play (`site_doc/`).
- **Fix build AAB** (#498) : désactivation du split ABI pour les bundles
  Android (AAB).

### Session autonome 2026-05-29/30 (boucle nuit, 70+ PR mergées)

Boucle autonome lancée par Noah au soir (PR #318 → #387+), objectif :
tester en continu et améliorer en sécurité jusqu'à 05:00 Paris. Travail
réservé aux zones SANS risque pour la tournée du lendemain (mark-livré,
optimisation, scan, sync cloud non touchés).

**Couverture de tests app** : +800 cas environ sur 50+ fichiers de
tests créés ou enrichis. Cibles principales :

- **Services data/** edge : `cloud_error_humanizer` (#318, #362),
  `bordereau_text_filters` (#319), `BordereauFormatDetector` (#320),
  `cloud_sync_types` (#321), `stop_types` (#322), `OverpassPoiService`
  (#323), `geo_utils` (#327), `heatmap_service` (#329), `Levenshtein`
  proprietes (#330), `BordereauValidator` (#332), `BordereauExtraction`
  (#333), `AddressSuggestion` (#334), `BanGeocodingService` (#335),
  `LocalReorderService` (#336), `LockOrdering` (#337),
  `AnomalyDetection` (#338), `app_constants` (#339),
  `DoublonDetection` (#345), `ChefStatsService` (#348),
  `ChefCarteService` (#349), `EtaCalculator` (#350),
  `RechercheEntreprisesService` (#354), `PhotonService` (#355),
  `RouteService` (#356), `VcardParser` (#357), `FuelPriceService`
  (#358), `TilePrefetchService` (#359), `NavigationService` (#360),
  `AmbientLightService` themeModeStream (#361),
  `SecureSupabaseLocalStorage` (#353).

- **Repos Drift** (DB mémoire schema v37 inchangé) : `Recurrences`
  (#340), `Frais` (#341), `Security` (#346), `Sheets` (#366).

- **Helpers ParametresRepository** (4 PR groupés) : quietHours +
  parseHHmm (#351), recentSearches LRU (#352), entreprise/thème/UI
  (#367), sécurité/ambient/coach/quietHours (#368), defauts
  capacité/durée/navApp (#370), autoBackup/coach (#369).

- **Plugins natifs** mock MethodChannel : `SecureScreenService`
  (#342), `evaluateLowBattery` (#344), `CachedTileProvider` cache
  disque (#380).

- **Data classes pures** (getters + invariants) : `ChefTourneeProgress`
  (#364), `ChefPresenceService.freshnessOf` (#365), `SharedAddress`
  (#363), `OcrBaselineStats` (#377), `stats_service` (TourneeStats /
  StatsBundle / MotivationStats / CoequipierStats) (#378), `realtime`
  PresenceDelta + LivePosition (#374), `cloud_sync_helpers` LWW (#373),
  `BatchScanItem` + `BatchCommitSummary` (#384),
  `CarnetBackfillResult.hasActivity` (#385), `BackupException` (#386).

- **Helpers top-level pures** : `tournee_pdf_widgets` formatPdfDuration
  / statutLabel / inferStatut (#381), `frais_form/type_helpers`
  labelForType / colorForType / iconForType (#382).

- **Defensive data classes** : `BatchScanItem` + `BatchCommitSummary`
  (#384), `CarnetBackfillResult.hasActivity` (#385), `BackupException`
  (#386), `LowBatteryDecision` 4 combinaisons (#389), `RecurrenceService.
  shouldGenerate` row variante (#391), `HeatmapService.maxCount` cas
  degeneres (#392).

- **Verrou schema Drift v38** (#393) : test sentinel qui catch un bump
  de schemaVersion sans migration onUpgrade associee.

**Site SEO `site_doc/`** : passe de 13 → 14/14 pages user-facing
totalement uniformisées.
- JSON-LD HowTo sur install-apk + guide-csv ; WebPage sur roadmap
  (#324) + 6 dernières pages (#325). 15/15 pages avec schema.org.
- sitemap.xml `<lastmod>` (#343), `og:site_name` (#371), `theme-color`
  manquant sur dashboard + guide-csv (#372), `apple-touch-icon` (#375),
  404.html enrichie (#376), `meta author` (#379), `robots.txt` Disallow
  /investisseurs.html (#383), `og:image:width/height/type` 1200x630
  (#387).

**Doc** : CHANGELOG mis à jour (#331, #388), fix chemin README site_doc
(#390).

### Session autonome 2026-05-11 (Vague 8 quality + features livraison)

**Refactor mode sombre** (17 fichiers, 314 occurrences `AppColors.X` → `p.X`
via `AppPalette`). 8 smoke tests UI clair + sombre.

**Optimisation VROOM enrichie** (migration v15) : choix profil
Voiture/VUL ou Camion >3.5t (driving-hgv), capacité véhicule respectée par
le solveur, évitement des péages (avoid_features tollways). Couvert par
+4 tests.

**Mode hors-ligne** : saisie d'arrêt en zone sans 4G via dialog texte
pur, badge "GPS manquant" dans la liste, batch re-géocodage via menu
Plus. Service `StopsGeocodeRetryService` + 4 tests.

**Rappels locaux par tournée** (migration v16) : champ `rappelLe`
configurable dans le form (date + heure picker), notif
`exactAllowWhileIdle` programmée via `NotificationsService.scheduleTourneeRappel`.
Auto-cancel quand la tournée passe en `terminee` ou est supprimée.

**Carnet enrichi** (migration v17) :
- Notes pré-définies par client (`notesCarnet`), re-proposées à la
  prochaine création d'arrêt pour ce client
- Filtre par couleur / favoris (row de chips scrollable)
- Dernier passage affiché sur chaque tile
- Export vCard (.vcf, RFC 2426) compatible import Contacts Android
- Couleur custom propagée sur les disques rang du Top 5

**Tournée du jour enrichie** :
- Édition rapide des fenêtres horaires inline (bottom sheet)
- Détection de doublons à la création (haversine 30 m)
- Undo dernier statut (via stop_history)
- Refaire dans 7 jours (duplicate avec targetDate)
- Coût carburant estimé (params EUR/L + L/100km), affiché en bandeau et
  cumulé dans Stats
- Partage texte court (WhatsApp/SMS) avec coût intégré

**Stats** :
- Carte "Colis par jour de la semaine" (barchart 7 jours)
- Carte "Top 5 clients" (avec couleur custom du carnet)
- Cumul coût carburant par fenêtre temporelle
- Pull-to-refresh

**Carte** : bouton "Centrer sur ma position GPS".

**Paramètres** : stats cache (tuiles MB + nb géocodages), bouton
"Annuler tous les rappels", section Carburant.

**Drawer** : compteur dynamique "X tournées aujourd'hui".

**Helpers extraits** : `GeoUtils.haversineMeters` + areClose dans
`lib/data/geo_utils.dart` (testable sans Flutter).

**Tests** : 85 → 182 (+97). Nouveaux fichiers : geo_utils,
geocode_cache_repository, bordereau_extraction, parametres_repository,
stops_geocode_retry, tournee_text_share, carnet_vcard_export,
ban_geocoding_service, photon_service, france_geocoding_service.
Extensions sur stats_service, stops_repository, tournees_repository,
openroute_optimization_service.

`flutter analyze` : **0 issue** (dart fix appliqué + docstrings tool/
nettoyées).

**Nettoyage** : suppression de `nominatim_service.dart` (~204 lignes
de code mort) — remplacé par FranceGeocodingService depuis longtemps.

**Bilan session** : 39+ commits, 0 issue `flutter analyze`, APK
release **v1.1.0+2** (~96 MB) prêt à `app/build/app/outputs/flutter-apk/app-release.apk`.

### Session 2026-05-12 (fixes terrain + extension tests)

**Fix critique R8/Proguard** : `flutter_local_notifications` crashait
`PlatformException(Missing type parameter)` à la sauvegarde d'une
tournée parce que R8 mangeait les `TypeToken` génériques de Gson en
build release. Ajout des règles Proguard officielles
(`-keep class com.dexterous.** { *; }` + `Signature`/`Annotation`).

**Mojibakes UI** : 11 occurrences de `'â€"'` (em-dash double-encodé),
bullets `'â€¢'`, et flèches `'â†'` (right arrow) corrigées dans 9 écrans
visibles utilisateur (drawer tooltip, mentions légales, carte, tournée
du jour, ajout arrêt, etc.) — remplacement par caractères ASCII propres
(`-`, `*`, `->`).

**Tests étendus** : 285 → 356 (+71). Nouveaux fichiers `sheets_repository_test`,
extensions sur `app_tokens` (+19 tests context.palette + lerp + tags),
`parametres_repository` (+21 tests watchers + ORS key + onboarding),
`address_suggestion` (+7 tests fromJson + secondaryLabel),
`saved_destinations` (+5 tests proximité + favori + accents),
`tournee_text_share` (+4 tests fenêtres + notes), `photon_service` (+6),
`ban_geocoding_service` (+5 reverse), `recherche_entreprises` (+4).

**Script `scripts/mirror-phone.ps1` compatible PS5.1** : l'opérateur
`?.` (PS7+) plantait sur Windows PowerShell 5.1 — remplacé par un
`if` simple.

**Bilan extension** : +14 commits, +71 tests, fix UI critique livré.
APK v1.1.0+2 rebuild avec les fixes.

**Documentation** :
- `docs/user-guide.md` : guide utilisateur exhaustif
- `docs/play_store/listing.md` : fiche Play Store enrichie
- `docs/session-2026-05-11-autonome.md` : recap session
- `README.md` mis à jour avec les nouvelles capacités

---

### Ajouté
- Plan détaillé Phase 1 version gratuite (`docs/plan_free.md`).
- Plan détaillé version CB avec Google Maps Platform (`docs/plan_cb.md`).
- Script de génération PDF pour les documents Markdown (`docs/_build_pdf.py`).
- Squelette du projet Flutter dans `app/` (cible Android, organisation `com.optiroute`).
- Convention Git du projet (branches, commits, PRs) documentée dans le README.
- Hook `pre-push` versionné (`.githooks/pre-push`) qui bloque les push directs vers `main` ; activation via `git config core.hooksPath .githooks` après clone.
- Schéma de base de données SQLite via `drift` (`app/lib/data/database.dart`) : tables `tournees`, `stops` (avec FK et cascade delete), `parametres` (clé primaire texte). PRAGMA `foreign_keys=ON` activé via la migration strategy. Code drift généré commité dans `database.g.dart`.
- Suite de tests pour la base (`app/test/database_test.dart`) couvrant insertion + valeurs par défaut, cascade delete, upsert sur paramètres.
- Première UI métier : `TourneesListScreen` (liste accueil avec empty state, swipe-to-delete et confirmation, FAB *Nouvelle tournée*) et `TourneeFormScreen` (création / édition avec validation des champs et DatePicker localisé `fr_FR`).
- Couche `TourneesRepository` qui abstrait les opérations CRUD au-dessus de drift et expose un `Stream<List<Tournee>>` pour la réactivité automatique.
- Providers Riverpod (`appDatabaseProvider`, `tourneesRepositoryProvider`, `tourneesStreamProvider`) et `ProviderScope` à la racine.
- `main.dart` réécrit : ne montre plus le compteur Flutter mais ouvre directement la liste de tournées. Configuration des locales `fr_FR` (intl + flutter_localizations).

### Modifié
- `pubspec.yaml` : ajout de `flutter_riverpod ^3.3.1`, `intl ^0.20.2`, `flutter_localizations` (SDK).

### Documentation
- Import du handoff Claude Design dans `docs/design/handoff/` : 6 écrans cibles haute fidélité (carte, liste, navigation, ajout, optimisation, détail livraison), tokens (palette cream/ink/lime/emerald, Manrope + JetBrains Mono), modèle de données suggéré (avec concept `Sheet` pour gérer les feuilles d'expéditeurs multiples par arrêt). Référence pour toute la suite des écrans à implémenter.

### Visuel
- Thème global câblé : `lib/theme/app_tokens.dart` expose les primitives (palette cream/ink/lime/emerald, échelles d'espacement et de radius, shadows) et `lib/theme/app_theme.dart` produit un `ThemeData` Material 3 prêt à l'emploi (Manrope via google_fonts, AppBar/Card/Input/Button/FAB tous configurés selon la spec). Les écrans existants (liste tournées, formulaire) prennent automatiquement le nouveau look ; couleurs hardcodées remplacées par les tokens. Helper `appMonoStyle()` exposé pour JetBrains Mono.

### Géocodage
- **Champ adresse intelligent** : la saisie de tournée a un seul champ « Adresse de départ » avec autocomplete via Nominatim (OpenStreetMap), debounce 400 ms, suggestions ≥ 3 caractères. La sélection valide le champ et stocke `lat` / `lon` en base sans jamais les exposer.
- `lib/data/address_suggestion.dart` : modèle des résultats Nominatim (display_name, lat, lon, road, city, postcode...).
- `lib/data/nominatim_service.dart` : client HTTP avec User-Agent identifiable (requis par la policy publique de Nominatim).
- `lib/widgets/address_autocomplete_field.dart` : widget réutilisable (sera réutilisé pour la saisie d'arrêts au jalon suivant).
- Permission `INTERNET` ajoutée au `AndroidManifest.xml` principal (était seulement dans debug/profile).

### Architecture
- **Home refactorée en architecture hybride** : la home n'est plus la liste des tournées, mais directement la **tournée du jour** (selon décision Noah). Si aucune tournée pour aujourd'hui, un empty state propose la création.
- `lib/screens/home_screen.dart` : dispatcher qui choisit entre `TourneeDuJourScreen` (tournée active présente) et `_NoTourTodayScreen` (sinon).
- `lib/screens/tournee_du_jour_screen.dart` : nouvelle vue principale, alignée sur `screen-list.jsx` du handoff (header avec date, big title, sous-titre, stat row Arrêts/Distance/Restant en JetBrains Mono, placeholder pour la future liste des arrêts).
- `currentTourneeProvider` (Riverpod) : sélectionne automatiquement la tournée active selon les règles `en_cours > optimisée > brouillon`, datée d'aujourd'hui.
- `lib/widgets/app_drawer.dart` : drawer commun avec entrées « Tournée du jour » et « Historique des tournées » — l'historique reste accessible mais ne pollue plus l'accueil.
- `TourneesListScreen` repositionné comme **écran d'historique** (titre AppBar « Historique des tournées », accessible via le drawer).

### Base de données
- **Nouvelle table `sheets`** : feuilles d'expéditeurs attachées à un arrêt. Cas réel : un livreur peut déposer au même point des colis venant d'expéditeurs distincts (Chronopost, La Poste, Colissimo) — chacun a sa propre référence, son nb de colis, son poids, son contact. La table porte FK `stop_id` avec cascade delete (transitif : supprimer une tournée supprime ses stops, qui suppriment leurs sheets).
- **`schemaVersion` 1 → 2** avec `MigrationStrategy.onUpgrade` qui crée la nouvelle table sur les bases existantes. Validé sur appareil réel avec une base v1 préexistante.
- `lib/data/sheets_repository.dart` : `SheetsRepository` (CRUD + `watchByStop` + `totalColisForStop`).
- Provider `sheetsRepositoryProvider` ajouté.

### Géocodage 100% officiel France (BAN + Recherche-Entreprises)
**Décision Noah** : on bascule sur les **deux APIs officielles de l'État français** et on supprime TomTom et Photon. Plus simple, plus fiable, source de vérité = État.

- **`BanGeocodingService`** (`api-adresse.data.gouv.fr/search/`) : Base Adresse Nationale, ~25 millions d'adresses (IGN + La Poste + DGFiP). Couverture quasi exhaustive France métropolitaine + DOM-TOM. Inclut tous les numéros de rue (cadastre DGFiP).
- **`RechercheEntreprisesService`** (`recherche-entreprises.api.gouv.fr/search`) : base SIRENE/INSEE, 30+ millions d'entreprises françaises déclarées. Adresse du siège social + lat/lon + SIREN + activité + nom complet (`poiName`).
- **`FranceGeocodingService`** : cascade intelligente.
  - Détection : si la requête commence par un nombre (`14`, `12 bis`...) → **BAN** d'abord, **Recherche-Entreprises** en fallback.
  - Sinon → **Recherche-Entreprises** d'abord, **BAN** en fallback.
  - Si le primaire trouve un résultat précis (`house_number` ou `poiName`), on s'arrête (pas de 2ᵉ requête inutile).
  - Sinon merge + dédup par lat/lng (5 décimales).
- **Aucune clé API**, aucun compte, aucune CB, aucune limite stricte.

### Suppressions
- **`TomTomService`**, **`PhotonService`**, **`CascadingGeocodingService`** : supprimés (~500 lignes) — ne sont plus utilisés depuis la bascule sur les APIs officielles France.
- **`tomtomApiKeyProvider`** retiré de `database_providers.dart`.
- Méthodes TomTom retirées de `ParametresRepository`.
- **`ParametresScreen`** simplifié : section *Géocodage* devient une simple carte d'info statique « Sources officielles France ». Le champ clé TomTom et tous ses contrôles sont retirés. La section *Optimisation de tournée* (clé ORS) reste inchangée.

### Recherche par nom d'entreprise / commerce (POI)
- **Bascule de l'endpoint TomTom** de `/search/2/geocode/` vers `/search/2/search/` (Fuzzy Search) : retourne maintenant aussi les POIs (commerces, entreprises, sites). Tu peux taper *« Carrosserie Coculo Fontenay sur Eure »* et obtenir l'adresse exacte de l'entreprise.
- **`AddressSuggestion.poiName`** ajouté : nom du POI quand le résultat est une entreprise/commerce. `primaryLabel` retourne le nom du POI à la place de l'adresse quand présent.
- **`PhotonService`** : reconnaît les POIs OpenStreetMap (osm_key dans `amenity`/`shop`/`office`/`tourism`/`leisure`/`craft`/`healthcare`/`building`/`industrial`) et extrait le `name` comme nom d'entreprise.
- **`_SuggestionTile`** mis à jour visuellement :
  - **POI** : icône `storefront_outlined` sur fond `emeraldSoft`, badge **« COMMERCE »** en `emerald`, sub-line riche avec adresse complète (numéro · rue · CP ville).
  - **Adresse précise** : icône `place_outlined` lime (inchangé).
  - **Adresse imprécise** : icône grisée + badge **« SANS NUMERO »** ambre (inchangé).

### Suppression depuis les écrans
- **Menu overflow** (3 points) dans l'AppBar de `TourneeDuJourScreen` avec une action *Supprimer la tournée* (confirmation modale avant suppression). Après confirmation, le `HomeScreen` détecte automatiquement qu'il n'y a plus de tournée du jour et bascule sur l'empty state.
- **Bouton danger rouge** dans `TourneeFormScreen` (mode édition seulement) : *Supprimer cette tournée* en bas du formulaire, séparé par un divider, avec sous-texte explicatif (« tous les arrêts seront supprimés »).
- **Bouton danger rouge** dans `AjoutArretScreen` (mode édition seulement) : *Supprimer cet arrêt*. Confirmation modale qui affiche le nom du client + l'adresse pour éviter les erreurs.
- Les 3 nouvelles actions utilisent le même style (`AppColors.red`, outlined, radius 14, hauteur 52) pour rester visuellement cohérent avec le design.
- Les chemins existants restent : swipe-to-delete dans la liste d'historique et sur les arrêts de la tournée du jour fonctionnent toujours.

### Optimisation de tournée (jalon 7)
- **`OptimizationService`** (interface) + **`OpenRouteOptimizationService`** : appel à `POST https://api.openrouteservice.org/optimization` (VROOM en backend). Plan free 500 optimisations/jour, sans CB.
- **Mapping métier → solveur** :
  - Coordonnées dépôt = `start` + `end` du véhicule (retour au dépôt en fin de tournée).
  - Chaque stop devient un `job` avec `service` (durée d'arrêt en secondes), `location` (lon, lat), `priority` (0-100 selon priorité métier), `time_windows` (HH:mm convertis en secondes depuis 00:00) si fenêtre horaire définie.
  - Mapping priorités : `obligatoire_premier` → priority 100, `flexible` → 50, `eviter_si_possible` → 10, `obligatoire_dernier` → 0.
- **Migration DB v3 → v4** : ajout sur `tournees` des colonnes `distance_totale_m`, `duree_totale_s`, `optimisee_le` (toutes nullable).
- **`StopsRepository.applyOptimizedOrder(orderedIds)`** : transaction qui écrit `ordre_optimise = 1..N` selon l'ordre retourné par le solveur.
- **`ParametresScreen`** étendu avec un champ « Clé API ORS » + carte d'état + boutons enregistrer/effacer.
- **`TourneeDuJourScreen`** : nouvelle action `bolt` dans l'AppBar (désactivée si pas de clé ORS) qui :
  - Lance l'appel ORS (loader pendant la requête).
  - Applique l'ordre optimisé aux stops (rangement automatique de la liste via le stream drift).
  - Met à jour `tournees.statut='optimisee'` + `distance_totale_m` + `duree_totale_s` + `optimisee_le`.
  - SnackBar de succès « Tournée optimisée : X km · Y h Z min » sur fond emerald.
- **Bannière « Itinéraire optimisé »** entre header et stat row quand `statut == 'optimisee'` (carte ink + icône bolt lime, alignée sur `screen-list.jsx` du handoff).
- **Stat row** maintenant alimentée par les vraies distance/durée totales après optimisation.

### Géocodage : ajout TomTom (qualité maximale, gratuit avec inscription)
- **`TomTomService`** (`lib/data/tomtom_service.dart`) — nouveau fournisseur, qualité référence pour la livraison/logistique. Connaît les numéros précis, les commerces, tolère les fautes. Plan free TomTom : 2 500 requêtes/jour, sans carte de crédit. Filtrage par pays (France) et langue (`fr-FR`) par défaut.
- **`ParametresRepository`** (`lib/data/parametres_repository.dart`) — wrapper type-safe sur la table `parametres`. Expose `getTomTomApiKey`, `setTomTomApiKey`, `clearTomTomApiKey`, et un stream `watchTomTomApiKey`.
- **Sélection automatique du fournisseur** dans `geocodingServiceProvider` : si une clé TomTom est configurée → `TomTomService` ; sinon fallback `PhotonService`. Riverpod re-instancie le service automatiquement quand la clé change.
- **`ParametresScreen`** (`lib/screens/parametres_screen.dart`) — nouvel écran accessible depuis le drawer (item « Paramètres » désormais actif) :
  - Indique le fournisseur actif (TomTom en lime, Photon en cream-soft).
  - Champ clé API TomTom (masqué par défaut, toggle visibilité).
  - Boutons « Enregistrer » et « Effacer la clé » (revient à Photon).
  - Bouton « Vider le cache de géocodage » (purge les entrées expirées).
- **Sécurité** : la clé est saisie via l'UI et stockée dans la DB SQLite locale, **jamais en dur dans le code source ni commitée**.

### Géocodage : bascule sur Photon (Komoot)
- **Nouveau fournisseur par défaut** : Photon (`https://photon.komoot.io/api/`) à la place de Nominatim direct. Toujours basé sur OpenStreetMap, mais avec un index dédié et un meilleur ranker — beaucoup d'adresses qui ratent avec Nominatim ressortent correctement (notamment hors grandes villes). Aucune clé API, aucun compte requis.
- **Interface `GeocodingService`** abstraite (`lib/data/geocoding_service.dart`) : permet de basculer entre fournisseurs (Photon / Nominatim / TomTom / etc.) sans toucher au widget. `NominatimService` implémente toujours l'interface — garde une bascule possible sans recoder.
- **Cache local** : la clé est désormais préfixée par `providerKey` (`photon:...` vs `nominatim:...`) pour ne pas mélanger les réponses entre fournisseurs. L'ancien cache Nominatim expirera naturellement (TTL 30 jours) sans interférer.
- Renommage : `lib/providers/nominatim_provider.dart` → `geocoding_providers.dart` (cohérence).

### Géocodage plus précis
- **Détection du numéro de rue** dans la requête (regex tolérante : `14`, `14 bis`, `12 ter`, etc.) → si présent, double appel Nominatim **en parallèle** : recherche libre (`?q=...`) + recherche structurée (`?street=...&city=...`). Les résultats sont mergés et dédupliqués par lat/lng.
- **Re-ranking** des suggestions : numéro exact en tête, puis suggestions avec n'importe quel `house_number`, puis le reste. Empêche Nominatim de privilégier la rue entière quand l'adresse précise existe.
- **Limite** passée de 5 à 8 pour mieux capturer le bon résultat.
- **Badge visuel `SANS NUMERO`** (ambre) sur les suggestions sans `house_number` pour que l'utilisateur sache qu'elles sont approximatives. L'icône pin est aussi grisée dans ce cas (vs lime quand le numéro est précis).

### Carte (jalon 6)
- **`CarteScreen`** : nouvelle vue carte plein écran utilisant `flutter_map` + tuiles OpenStreetMap (User-Agent identifiable). Affiche un pin de dépôt (lime + icône entrepôt) et un pin par arrêt géoréférencé, avec **auto-fit** sur l'ensemble des points au chargement.
- **Markers stylisés** alignés sur le handoff `screen-map.jsx` : pending = paper outline ink avec index mono, livré = emerald + ✓, échec = rouge + !, dépôt = lime.
- **Tap sur un pin** d'arrêt → **bottom sheet** avec radius 28 (selon design) : numéro mono dans une chip, nom client, adresse complète, notes en cream-soft, chips info (colis, fenêtre horaire mono).
- **FAB recentrer** (bottom-right) qui re-fit les bounds.
- Action **carte** dans l'AppBar de `TourneeDuJourScreen` (icône `map_outlined`) à côté du crayon d'édition.
- Empty state si aucun arrêt géoréférencé.
- Dépendances : `flutter_map ^8.x` + `latlong2 ^0.9.x`.

### Géocodage finalisé (jalon 5)
- **Cache local des géocodages** : nouvelle table `geocode_cache` (PK = requête normalisée, TTL 30 jours par défaut). `NominatimService` interroge le cache avant de taper Nominatim ; les requêtes répétées (même mot-clé) ne consomment plus le rate-limit public. Best-effort à l'écriture (un échec de cache n'invalide pas le résultat).
- **`schemaVersion` 2 → 3** avec `MigrationStrategy.onUpgrade` qui crée la nouvelle table sur les bases existantes.
- **`GeocodeCacheRepository`** (`lib/data/geocode_cache_repository.dart`) : `read`, `write` (upsert), `purgeExpired`. Encode/decode JSON.
- **Édition d'un arrêt existant** : tap sur un arrêt dans la liste → ouvre `AjoutArretScreen` en **mode édition**. Préremplissage de tous les champs (adresse via `AddressSuggestion` reconstruit, priorité, colis, durée, fenêtres horaires parsées HH:mm, client, notes). Le bouton *+ Ajouter un autre* est masqué en édition.

### Ajout d'arrêts (jalon 4)
- **Écran `AjoutArretScreen`** : page unique qui combine la saisie d'adresse (autocomplete Nominatim, lat/lng cachés) et tous les **impératifs** demandés par Noah :
  - Priorité (`En 1er` / `Flexible` / `En dernier` / `Éviter`) en `ChoiceChip` colorés.
  - Nombre de colis et durée d'arrêt (en minutes).
  - Fenêtre horaire optionnelle (`Pas avant` / `Avant`) via `showTimePicker`. Long-press sur le champ pour effacer.
  - Nom du client et notes libres (code accès, étage, etc.).
  - Deux boutons : `Enregistrer` (revient à la home) et `+ Ajouter un autre` (sauvegarde et reset le formulaire pour enchaîner sans naviguer).
- **`StopsRepository`** + provider famille `stopsByTourneeProvider` : la liste des arrêts est réactive automatiquement via le stream drift.
- **Liste des arrêts dans `TourneeDuJourScreen`** : remplace le placeholder. Chaque ligne montre un index numéroté (mono, ink+lime quand priorité forte), le client ou l'adresse, une sub-info, et des **tags** alignés sur le design (`En 1er`, `2 colis`, `09:00 → 11:00` en mono, `Éviter` ambre). Swipe gauche → confirmation → suppression (cascade sheets via DB).
- Le compteur d'arrêts dans la stat row est désormais réel.
