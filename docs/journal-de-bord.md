# Journal de bord — opti_route

**Application Android d'optimisation de tournées de livraison**, développée pour Noah, chauffeur-livreur. Stack 100 % gratuite (Flutter + OpenStreetMap + APIs officielles France), zéro budget API, aucune carte de crédit requise.

Ce document trace l'historique des fonctionnalités livrées, mises à jour à chaque PR mergée. Le `.pdf` joint est régénéré automatiquement après chaque modification via `python docs/_build_pdf.py journal-de-bord`.

---

## Vue d'ensemble

À ce jour, **53 PRs mergées** sur la branche `main`. L'app couvre tout le cycle de vie d'une tournée : création → géocodage → optimisation → exécution avec GPS → validation des livraisons → bilan.

Les sections ci-dessous regroupent les PRs par grand axe fonctionnel pour rester lisible.

---

## 1. Setup & infrastructure (#1 → #5)

Mise en place du projet et des fondations techniques.

- **#1** — Pre-push hook qui bloque les push directs sur `main` (workflow trunk-based).
- **#2** — Base de données locale Drift (SQLite) avec les tables clés : `tournees`, `stops`, `parametres`.
- **#3** — Première UI métier : liste des tournées + écran d'une tournée du jour.
- **#4** — Import du handoff Claude Design dans `docs/design/` (tokens couleurs, typo, écrans cibles).
- **#5** — Tokens de design + thème Material 3 global (cream / ink / lime / emerald + Manrope + JetBrains Mono).

## 2. Géocodage hybride France (#6, #12, #13, #14–#17, #20–#23, #41, #42)

Plusieurs itérations pour arriver à une cascade fiable et 100 % gratuite.

- **#6** — Premier autocomplete d'adresse via Nominatim. lat/lng cachés en backend, jamais affichés.
- **#12** — Adresse précise (avec numéro de rue) priorisée sur la rue seule.
- **#13** — Bascule de Nominatim vers Photon (Komoot) pour la fiabilité.
- **#14 → #17** — Tentative d'intégration TomTom (clé API user, gestion d'erreurs, cascade), abandonnée pour passer aux APIs officielles France.
- **#20** — Recherche par nom d'entreprise / commerce (POIs).
- **#21** — Bascule définitive sur les **APIs officielles France** : BAN (cadastre DGFiP) + Recherche-Entreprises (SIRENE/INSEE).
- **#22** — Parseur Recherche-Entreprises + cache des résultats vides.
- **#23** — Ajout de **Photon (OSM)** comme 3ᵉ source pour les enseignes / marques (Carrefour, Citroën…) que SIRENE ne connaît pas.
- **#41** — Filtre des entreprises SIRENE cessées (`etat_administratif=C`) ou siège fermé : on tombe alors sur Photon qui a souvent le pin physique correct.
- **#42** — Adresse postale propre dans `Stop.adresseBrute` : on retire le préfixe nom de l'entreprise (`displayName` SIRENE) qui dupliquait `nomClient` à l'affichage.

## 3. Tournée & arrêts — création, édition (#7, #9, #10, #19, #24)

- **#7** — Home = tournée du jour, l'historique déplacé dans un drawer.
- **#9** — Ajout multiple d'arrêts avec impératifs : adresse, priorité (premier / flexible / dernier / éviter), nb colis, fenêtre horaire, durée, nom client, notes.
- **#10** — Cache du géocodage + édition d'un arrêt existant.
- **#19** — Ajout des points de suppression (tournée + formulaires) manquants.
- **#24** — Saisie manuelle d'enseigne quand l'autocomplete ne trouve pas le commerce.

## 4. Carte (#11, #44)

- **#11** — Carte de la tournée avec pins et auto-fit (centre + zoom auto sur tous les arrêts).
- **#44** — Tracé de l'itinéraire optimisé en **polyline verte** sur la carte (suit les routes réelles, sens uniques, virages — récupéré via `/v2/directions/driving-car/geojson` ORS).

## 5. Optimisation (#18, #37, #38)

- **#18** — Optimisation via OpenRouteService (VROOM en backend). Plan free 500 / jour, sans CB.
- **#37** — Respecter l'ordre des arrêts `EN 1ER` / `EN DERNIER` choisi par le livreur. VROOM ne le faisait pas car son champ `priority` est un score, pas un ordre absolu. Solution : firsts/lasts gérés côté app, VROOM optimise uniquement les flexibles.
- **#38** — Distance/durée totales **réelles** sur toute la tournée (un 2ᵉ appel `/directions` couvre le parcours complet, plus seulement le segment VROOM).

## 6. OCR bordereaux MESEXP (#25 → #35)

Scan caméra et parsing automatique des bordereaux papier (format MESEXP / Messagerie Express).

- **#25** — Première version : caméra + ML Kit (Google) pour reconnaître le texte.
- **#26** — Parser auto avec extraction destinataire / colis / CP-ville.
- **#27 → #35** — Itérations massives basées sur les vraies données terrain (logcat OCRDUMP) : heuristique d'occurrences, rue par adjacence, CP par adjacence + bonus-ville, score de confidence (carte orange si bordereau ambigu), filtres anti-rues numérotées et anti-transporteurs.

## 7. Carnet d'adresses local (#36, #48)

100 % local au téléphone (table SQLite), zéro sync, zéro backend.

- **#36** — Auto-mémorisation à chaque arrêt validé. L'autocomplete d'adresse interroge le carnet **avant** la BAN/SIRENE → les clients déjà livrés remontent en haut avec un badge `DÉJÀ LIVRÉ`.
- **#48** — Édition manuelle du carnet : écran liste avec recherche tolérante aux accents, swipe-to-delete, édition complète (nom + adresse). Accessible depuis le drawer.

## 8. Validation & bilan de tournée (#39, #43)

- **#39** — Validation depuis la bottom sheet d'arrêt : `Livré` / `Échec` (avec raison : Absent / Refusé / Adresse fausse / Autre). Pastille verte/rouge sur la carte.
- **#43** — Bilan auto : bandeau de progression (X livrés / Y total + barre 3 couleurs + N échecs), bascule automatique vers `statut='terminée'` quand tous les arrêts ont un statut.

## 9. Navigation externe Maps / Waze (#40)

Boutons rapides Maps + Waze dans la bottom sheet d'arrêt qui ouvrent l'app externe (URL `geo:` ou format dédié) en mode navigation directe vers les coordonnées de l'arrêt. Quand le téléphone est en Android Auto, ces apps prennent le relais sur l'écran du véhicule.

## 10. Mode tournée en cours (#45)

- FAB **Démarrer** (vert lime) qui demande la permission GPS puis bascule en `statut='en_cours'`.
- Carte **Prochain arrêt** en haut de l'écran avec :
  - Le 1ᵉʳ arrêt non livré dans l'ordre optimisé.
  - Distance vol d'oiseau **live** depuis la position GPS du chauffeur.
  - Boutons rapides Maps / Waze.
- FAB **Pause** pour repasser en optimisée (sans perdre les statuts déjà posés).

## 11. Historique des tournées (#46)

Liste sectionnée : `En cours / À venir` puis `Terminées`, triées par date décroissante. Cards plus riches : nom, date, badge statut. Pour les terminées : distance + durée totales en mono vert. Tap court → ouvre la tournée. Long press → édition.

## 12. Préférences globales (#47)

Section dans Paramètres pour configurer les valeurs par défaut :
- **Capacité véhicule** (colis) : préremplie à la création d'une tournée.
- **Durée d'arrêt** (minutes) : préremplie à la création d'un arrêt.
- **App de navigation par défaut** (Maps / Waze / Aucune) : quand définie, l'app correspondante passe en bouton plein vert dans la bottom sheet.

## 13. Compteur de colis (#50)

Tuile **Colis** dans la stat-row de la tournée + indication `X / Y colis` dans le bandeau de progression.

## 14. Drag-and-drop manuel des arrêts (#51)

Réordonner les arrêts à la main après l'optim, pour gérer les contraintes terrain que le solveur ignore (sens uniques mal mappés sur OSM, place de stationnement, demi-tour fourgon impossible…). Poignée de drag explicite à droite de chaque card pour ne pas conflit avec le tap qui ouvre la bottom sheet.

## 15. Bouton Optimiser grisé (#52)

Bouton **Optimiser** désactivé tant que `optimiseeLe != null` (rien n'a changé depuis la dernière optimisation). Toute modification d'arrêt (add / edit / delete / changement du point de départ) appelle `invalidateOptimization` qui remet le marqueur à null et réactive le bouton. Économise des appels ORS inutiles.

## 16. App icon + splash screen (#53)

Identité visuelle finalisée :
- **App icon** : pin lime + tracé de route avec point de départ emerald, sur fond ink avec gradient + grille subtile (design dédié Claude Design, sources versionnées dans `assets/branding/source/`).
- **Splash screen** : logo cream sur fond ink, géré via `flutter_native_splash`.

L'icône Flutter par défaut était un placeholder ; on est maintenant sur l'identité finale du projet.

---

## Préférences techniques en place

- Trunk-based + PRs squash → historique main lisible (1 PR = 1 commit).
- Tests unitaires sur les parties critiques (parser bordereau, repos Drift, geocodage cascade).
- `.claude/settings.local.json` (gitignored) avec mode `bypassPermissions` + deny list pour les destructifs.

## À venir

Roadmap des prochaines améliorations (sans CB, dans la version free) :

**Confort terrain quotidien**
- Indication "tournée en cours" globale (badge sur l'icône drawer).
- Recherche dans la liste des arrêts (utile sur 15+ arrêts).
- Édition rapide d'un arrêt depuis la bottom sheet (nb colis / notes sans aller dans l'écran complet).
- Mode sombre (auto selon l'heure ou bascule manuelle).
- Statistiques cumulatives (écran 7/30/365 j depuis le drawer).

**Workflow**
- Templates de tournée (réutiliser une tournée passée).
- Multi-tournées par jour (matin / après-midi).
- Backup du carnet d'adresses (export CSV).
- Mode hors-ligne basique (cache tiles OSM + géocodage offline).
- Géocodage manuel par tap sur la carte.
- Réordonnancement en mode "tournée en cours" (validation).

**Préparation publication Play Store**
- Onboarding premier lancement (clé ORS + point de départ + tutoriel mini).
- Export PDF de tournée (récap carte + liste + stats).
- Privacy policy / CGU (obligatoires Play Store).
- Signing config release propre (actuellement clé debug = pas publiable).
- CI GitHub Actions (tests automatiques sur PR).

**Plus loin**
- Scan des bordereaux **collés sur les colis** (autre format, en attente de photos terrain).
- GPS turn-by-turn intégré (Mapbox SDK = CB requise → reporté).
