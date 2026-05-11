# Session autonome — 2026-05-11

*Session ~9h en autonomie 100% pendant que Noah dort, prête à installer
à 05h30 heure de Paris le 12/05/2026.*

## Recap

Cette session prolonge la Vague 8 (mode sombre + smoke tests UI) avec
des améliorations ergonomie / features. **Aucune CB requise**,
toujours 100% gratuit.

## Migrations Drift

- **v14 → v15** : `tournees.profilOrs` + `tournees.eviterPeages`
- **v15 → v16** : `tournees.rappelLe` (DateTime nullable)
- **v16 → v17** : `saved_destinations.notesCarnet`

Toutes les migrations ajoutent des colonnes avec valeur par défaut
back-compat : pas de perte de données pour les utilisateurs existants.

## Features livrées

### Optimisation (P6 du plan)

- **Profil VROOM HGV** : choix camion >3.5t ou Voiture/VUL dans le form
  Tournée. Le profil ORS bascule l'URL Directions (`driving-car` /
  `driving-hgv`) et le payload VROOM. Le HGV respecte les restrictions
  poids/hauteur et évite les centres piétonnisés.
- **Capacité VROOM** : si `vehiculeCapaciteColis > 0`, VROOM reçoit
  `capacity` sur le véhicule + `delivery` par job. Le solveur ne
  surcharge plus le camion.
- **Évitement péages** : SwitchListTile dans le form. Ajoute
  `options.avoid_features: ['tollways']` aux appels Directions.

Tests : +4 (HGV / péages / capacité>0 / capacité=0).

### Mode hors-ligne

- **Saisie d'arrêt en mode dégradé** : nouveau bouton "Hors ligne" à
  côté de "Scanner" dans Ajout arrêt. Dialog texte pur qui sauvegarde
  l'arrêt avec `adresseBrute` rempli et `lat/lng = null`.
- **Badge "GPS manquant"** (amber) dans la liste des arrêts.
- **Re-géocodage batch** : option "Géolocaliser hors-ligne" dans le
  menu Plus de la tournée du jour. Retape les `adresseBrute` des stops
  sans coords dans le cascade BAN/SIRENE/Photon, met à jour les coords
  des stops résolus. Snackbar bilan "N résolu(s), M échec(s)".
- Nouveau service `StopsGeocodeRetryService` + méthode
  `StopsRepository.updateCoords()`.

Tests : +4 (aucun candidat / résolution OK / geocoder vide / throw).

### Notifications

- **Rappels de tournée** : colonne `rappelLe` + UI `_RappelPickerTile`
  dans le form Tournée. Programme une notif locale via
  `NotificationsService.scheduleTourneeRappel()` en
  `exactAllowWhileIdle` (passe le doze Android). Id de notif = id Drift
  de la tournée → cancel propre.
- Cancellation auto :
  - quand la tournée passe à `terminee` (auto via batch livré ou via
    bottom sheet)
  - quand la tournée est supprimée
  - quand `rappelLe` est remis à null dans le form
- Bouton "Annuler tous les rappels" dans Paramètres → Notifications.

### Carnet d'adresses

- **Notes pré-définies par client** : nouvelle colonne `notesCarnet`,
  champ multi-lignes dans `CarnetEditScreen`. À la prochaine création
  d'un arrêt pour ce client (depuis l'autocomplete carnet), le champ
  Notes de `AjoutArretScreen` est pré-rempli (si Noah n'a pas déjà
  tapé ses propres notes).
- **Export vCard** (.vcf, RFC 2426 v3.0) : nouveau
  `CarnetVcardExportService`. PopupMenu sur la page Carnet propose CSV
  ou vCard. Le vCard import direct dans Contacts Android (FN, ORG,
  ADR, GEO, NOTE, CATEGORIES). Tests : +7.
- **Filtre par couleur / favoris** : row de chips scrollable au-dessus
  de la liste. Tous / Favoris / les 6 couleurs de `colorTagOptions`.
  Compose avec la recherche texte.
- **Dernier passage** sur les tiles : "Livre N fois - dernier 12 mai 26".

### Tournée du jour

- **Partage texte court** (WhatsApp/SMS/mail) via
  `TourneeTextShareService`. Format human-readable, inclut le coût
  carburant estimé dans le header si disponible. Tests : +4.
- **Détection de doublons** à la création d'un arrêt : haversine < 30 m
  OU adresse brute identique → dialog "Doublon possible ?" avec
  preview du candidat.
- **Édition rapide fenêtre horaire** inline dans le bottom sheet
  (tap = TimePicker, long-press = effacer).
- **Undo dernier statut** : option "Annuler dernier statut" dans le
  menu Plus. Trouve via `stop_history`, repasse à `a_livrer`, log
  l'action `revert`. Tests : +4.
- **Refaire dans 7 jours** : duplique à la même heure +7j. SnackBar
  avec action "Ouvrir".
- **Coût carburant estimé** : nouveau bandeau `_CoutCarburantBanner`
  sous la `_StatRow` dès qu'il y a une distance > 0. Configurable via
  Paramètres → Carburant (prix EUR/L + L/100km).

### Stats

- **Carte "Colis par jour de la semaine"** (30 derniers jours) :
  barchart horizontal lime, valeur à droite. Aide Noah à détecter ses
  jours les plus chargés.
- **Carte "Top 5 clients"** : trie le carnet par useCount, rang 1 en
  disque lime.
- **Cumul coût carburant** : ligne discrète en bas de chaque carte
  fenêtre (7j / 30j / 1 an).
- **Pull-to-refresh** : invalide tous les providers stats.
- Nouvelle méthode `StatsService.distanceTotaleMeters()` +
  `colisParJourDeSemaine()`. Tests : +8.

### Carte

- **Bouton "Centrer sur ma position GPS"** : FAB rond entre fit camera
  et fullscreen. Anime la carte sur la position courante à zoom 16.

### Paramètres

- **Stats cache** : affiche taille du cache tuiles (KB/MB) + nombre
  d'entrées du cache géocodage. Refresh auto après purge.
- **Section Carburant** : 2 champs prix/conso + bouton save.

## Tests

| Avant session | Après session |
|---|---|
| 85 tests | **134 tests** |

+49 tests dans :
- `openroute_optimization_service_test.dart` : +4 (HGV/péages/cap)
- `tournee_text_share_service_test.dart` : 4 (nouveau)
- `carnet_vcard_export_service_test.dart` : 7 (nouveau)
- `stops_geocode_retry_service_test.dart` : 4 (nouveau)
- `stats_service_test.dart` : +8 (jours semaine + distance totale)
- `parametres_repository_test.dart` : 5 (nouveau, cout carburant)
- `stops_repository_test.dart` : +4 (undo dernier statut)

`flutter analyze` : 0 erreur, 3 infos cosmétiques sur outils dev.

## État Play Store

- Listing préparé dans `docs/play_store/listing.md` (description,
  mots-clés, ordre des 8 captures, étapes Play Console).
- Reste côté Noah : compte dev Google (25 USD, CB), GitHub Pages pour
  privacy-policy, captures sur appareil, AAB signé via keystore.

## Commits sur `feat/vague-8-quality`

```
e37a819 feat: auto-cancel rappel + dernier passage carnet + 4 tests stats
106e9d9 feat: filtre carnet couleur + refaire +7j + pull-refresh + cumul EUR
69f80c9 feat: estimation cout carburant par tournee
2416db1 feat: notes pre-definies carnet + undo dernier statut
cb8ee8a feat: top 5 clients + fenetres horaires inline + cancel notifs
a7494aa feat: bouton centrer GPS sur carte + stats par jour de semaine
b754f1a feat: doublons + vCard export + tests (19 nouveaux tests)
fa075b7 feat: rappels locaux par tournee + re-geocodage des arrets hors-ligne
a20e3e4 feat: stats cache + mode hors-ligne + partage texte tournee
fed80e2 feat(optim): profil camion HGV + capacite VROOM + evitement peages
f84d0d4 fix(theme): mode sombre - drawer + home + cards lime contraste
6664fd2 feat(theme): mode sombre VRAI COMPLET + smoke tests UI
```

(plus quelques commits intermediaires sur des polishes UX divers)

## Build APK

À déclencher au réveil de Noah :
```
cd d:/opti_route/app
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
