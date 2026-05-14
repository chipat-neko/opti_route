# Plan GPS turn-by-turn intégré — opti_route — 2026-05-14

Évaluation de faisabilité pour intégrer une **navigation turn-by-turn
directement dans l'app**, au lieu de déléguer à Google Maps / Waze via
deep link (état actuel). Noah a exprimé ce besoin dans la mémoire
`project_gps_integre_futur.md` : "à terme une nav embedded pour éviter
Maps/Waze en parallèle".

## Pourquoi c'est demandé

État actuel : tap sur un arrêt → bottom sheet → "Ouvrir dans Maps"
ou "Ouvrir dans Waze" → l'app de navigation prend le focus, opti_route
passe en background. Au retour, Noah doit ré-ouvrir l'app + cocher
livré/échec.

Cible : carte dans opti_route + voix d'instructions ("Tournez à droite
dans 200 m") + boutons Livré/Échec accessibles **sans changer d'app**.

## Contraintes opti_route

1. **Zéro budget API** (mémoire `project_strategy.md`). Donc pas de
   Google Maps SDK, pas de Mapbox payant, pas de HERE.
2. **100 % hors-ligne au minimum** sur l'optimisation (ORS reste
   en ligne pour le routing). Idéalement la nav doit aussi marcher
   dans les zones sans réseau (tournées rurales).
3. **Android-first** (iOS plus tard). Le code doit rester compatible
   Flutter, pas de natif Java/Kotlin custom.

## Options évaluées

### Option A — `flutter_mapbox_navigation` (Mapbox SDK)

- **Pour** : SDK mature, instructions voix natives, UI déjà rodée
- **Contre** : Mapbox **gratuit jusqu'à 25k requêtes/mois** puis
  payant. Pour 30 tournées/jour × 10 arrêts × 30 jours = 9k
  requêtes/mois -> OK techniquement, mais on dépend d'un compte
  Mapbox + carte de crédit. Va contre la promesse "zéro CB"
- **Verdict** : ❌ exclu Phase 1, peut être réenvisagé en Phase 2
  (cloud / monétisation)

### Option B — Routing OSRM/Valhalla auto-hébergé + UI custom

- **Pour** : 100 % gratuit, libre, marche hors-ligne avec données
  pre-téléchargées
- **Contre** : auto-hébergement = serveur à payer/maintenir, ou
  bien on bundle les données OSM (gigaoctets) dans l'APK -> non
  viable (limite Play Store 200 MB)
- **Verdict** : ❌ trop d'infra pour un solo dev

### Option C — Continue avec ORS turn-by-turn + UI custom dans `flutter_map`

- **Pour** :
  - `ORS Directions API` (déjà utilisé pour l'optimisation) retourne
    aussi des **instructions de manœuvre** par segment ("Turn right",
    "Continue straight 500 m"). On a déjà la clé ORS, pas de surcoût.
  - `flutter_map` 8.3 sait déjà afficher des polylines routes et
    markers position GPS live (`geolocator` + `MapController.move`)
  - Synthèse vocale via `flutter_tts` (gratuit, on-device, pas de
    cloud)
- **Contre** :
  - L'instruction "100 m" arrivera **tardivement** sans recalcul
    fréquent. ORS rate-limit = 500 calls/jour, donc impossible de
    re-router toutes les 30 sec. Solution : pré-calculer l'itinéraire
    complet 1 fois au démarrage du segment, puis interpoler la
    distance restante en local jusqu'au prochain virage.
  - Pas d'UI prête à l'emploi -> ~1 semaine de dev pour avoir un
    bandeau d'instruction + carte plein écran + voix
- **Verdict** : ✅ **option recommandée**

### Option D — Maintenir le statu quo (deep link Maps/Waze)

- **Pour** : 0 développement, déjà robuste
- **Contre** : exactement le pain point que Noah veut résoudre
- **Verdict** : statu quo OK pour Phase 1, mais pas une réponse

## Recommandation : Option C, par étapes

### Étape 1 — PoC "Suivi GPS live + polyline" (~2 jours)

1. Nouveau provider `livePositionStream` qui watch `Geolocator.getPositionStream()` avec haute fréquence (1 Hz)
2. Nouvel écran `NavigationScreen(stopId)` :
   - `flutter_map` plein écran centré sur position courante
   - Polyline `MapController` du segment optimisé (déjà stocké dans `Stop.geometry`)
   - Marker bleu "ma position" qui se déplace en temps réel
   - Bouton FAB "J'y suis" -> retour à la liste avec marquage livré
3. Bouton "Naviguer" sur chaque stop déjà optimisé -> ouvre cette
   nouvelle écran au lieu du deep link Maps/Waze

### Étape 2 — Instructions textuelles ETA (~2 jours)

1. Étendre `ors_optimizer` pour récupérer aussi `directions.steps` (déjà
   dans le payload ORS, on l'ignore actuellement)
2. Persister la liste des `ManeuverStep` (distance restante, direction,
   nom de rue) dans une nouvelle table Drift `stop_directions` ou en
   JSON dans `Stop.directionsJson`
3. Sur la carte, afficher un bandeau supérieur : "→ Continuez tout
   droit · 320 m" qui se met à jour à chaque tick de position GPS
   (calcul haversine entre position courante et coordonnées du
   prochain pivot)
4. ETA d'arrivée en mode persistant en bas (déjà calculé par ORS)

### Étape 3 — Synthèse vocale (~1 jour)

1. Ajouter `flutter_tts: ^4.x` (gratuit, on-device, voix Android
   système)
2. Quand la distance restante au prochain pivot passe **sous 100 m**,
   trigger un `tts.speak("Dans 100 mètres, tournez à droite")`
3. Seuil configurable dans Paramètres (50 m / 100 m / 200 m / muet)
4. Respecter le mode "ne pas déranger" (réutiliser `isQuietHoursNow()`
   du `NotificationsService`)

### Étape 4 — Mode hors-ligne (~2 jours, optionnel)

Pour les tournées dans des zones sans réseau, pré-télécharger les
tuiles OSM de la bbox de la tournée au démarrage. Déjà partiellement
géré par `cached_tile_provider.dart`, mais nécessite un trigger
"pre-fetch" explicite par tournée. Limite : ~100 MB par tournée.

## Risques

1. **Géolocalisation imprécise** en zones urbaines (signal GPS rebondit
   sur les bâtiments). Solution : si la précision rapportée par
   geolocator > 30 m, afficher un warning "Signal GPS faible" + dégrader
   la fréquence vocale (pour ne pas annoncer "tournez maintenant" au
   mauvais moment).
2. **Batterie** : carte plein écran + GPS 1 Hz + écran allumé = ~15 %
   batterie par heure. Mitiger via `wakelock_plus` désactivé après 30s
   d'inactivité (l'écran s'éteint, le GPS continue).
3. **TTS qui parle en boucle** si le user passe et repasse devant le
   pivot. Solution : flag `_spokenForStep[i] = true` pour ne speak
   qu'une fois par étape.
4. **Concurrence avec Maps/Waze** : si Noah lance Maps en parallèle,
   les 2 apps se battent pour la voix. Solution : `flutter_tts.stop()`
   au focus loss + bandeau "Mode nav opti_route actif" pour signaler.

## Décision

**Pas de démarrage cette session** : Étape 1 seule = 2 jours pleins.
Décision Noah requise sur la priorité vs autres pistes (Phase B OCR,
multi-tournées paralleles, etc.).

Ce document sert de **base de discussion** quand Noah voudra démarrer.
Le code et les choix algorithmiques sont à valider en session dédiée.

## Liens

- ORS Directions API : https://openrouteservice.org/dev/#/api-docs/v2/directions
- flutter_tts : https://pub.dev/packages/flutter_tts
- flutter_map polyline : https://docs.fleaflet.dev/layers/polyline-layer
- geolocator stream : https://pub.dev/packages/geolocator#listening-to-location-updates
