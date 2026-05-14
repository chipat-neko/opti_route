# Changelog

Toutes les modifications notables du projet sont consignées dans ce fichier.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Non publié]

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
