# Modules de `lib/data/` non branchés à l'UI — triage

> Analyse du 2026-08-13 (7 agents, lecture seule) des **36 modules** de `app/lib/data/` qui n'étaient importés que par leurs propres tests : du code écrit, testé, mais que rien n'appelait.
>
> Ce document existe pour que ce travail ne soit pas à refaire. Il dit, pour chacun, ce qu'il fait, s'il est vraiment orphelin, et ce qu'il faudrait pour le brancher.

## Où en est-on

| | Nombre | Suite donnée |
|---|---|---|
| **Supprimés** | 9 | #537 — 466 lignes de lib + 478 de test |
| **Branchés depuis** | 3 | `proximity_checker` (#539), `scan_duplicate_check` (#545), `dispute_file` (#547) |
| **Restent à brancher** | 23 | décision produit, pas dette technique |
| **Gardé en l'état** | 1 | `loading_plan_3d` — backlog assumé et daté dans le code |

## Méthode — et pourquoi elle compte

Le constat d'origine de l'audit annonçait « 3 doublons avérés à supprimer en priorité ». **Un seul sur trois a résisté à la vérification.**

- `battery_mode` **n'est référencé nulle part** : la seule occurrence est la chaîne littérale `'securite.battery_mode'` dans `app_role.dart`, clé d'une map — pas un import. Et ce n'est pas un doublon : `battery_monitor_service` *alerte* sur batterie basse, `BatteryMode` *décide* quoi dégrader. Aucune fonction commune.
- `failure_heatmap` n'est pas un doublon de `heatmap_service` : l'un croise (code postal × heure) sur les seuls échecs, l'autre agrège une densité sur une grille lat/lng de 0.01°. Ni les entrées ni les sorties ne se recouvrent.

Appliquer le plan tel quel aurait supprimé deux modules non redondants, dont l'un des plus utiles du lot.

**Règle qui en découle : ne jamais conclure « orphelin » sur un seul grep.** Chaque module a été vérifié sur trois angles — import du chemin, chaque symbole public, référence indirecte (commentaire, string, clé de préférences).

### Le registre de features n'est pas un graphe d'appels

`FeatureRegistry` dans `app_role.dart` liste une cinquantaine de clés. **Deux seulement** sont réellement passées à un widget (`app.update_checker`, `pointage.cumul_semaine`), et `.can(` n'est appelé nulle part.

C'est une feuille de route d'intentions. Une clé du registre ne prouve donc jamais qu'un module est branché — 19 des 36 en avaient une.

## Les 9 supprimés (#537)

Chacun avait **zéro référence hors tests** et un remplaçant vivant, branché à l'UI.

| Module | l. | Remplaçant |
|---|---|---|
| `tournee_share_payload` | 104 | `TemplateShareService`, qui sait en plus réimporter. Prémisse QR morte : aucune lib de génération de QR au pubspec |
| `client_history_stats` | 76 | `ClientStatsService`, affiché dans `carnet_edit_screen` |
| `cheapest_fuel` | 57 | `FuelPriceService` — retirait au passage une **collision de type** : `class FuelStation` était déclarée deux fois |
| `road_sheet` | 48 | `TourneePdfService`, mêmes colonnes |
| `contact_import` | 44 | import vCard déjà livré, qui géocode via BAN là où celui-ci écrivait `lat: 0, lng: 0` |
| `app_lock` | 41 | `SecurityService`. Ses constantes de clés de stockage étaient fausses |
| `pending_geocode_queue` | 34 | `StopsGeocodeRetryService`, persistant |
| `ramasse_bulk` | 33 | `RecapDepot` et `stats_service.nbRamasses` |
| `night_mode_decision` | 29 | `AmbientLightService.decide` |

## Les 23 qui restent, par valeur produit

Classement établi du point de vue d'un livreur en tournée, pas de l'élégance du code.

| # | Module | l. | Coût | Ce que ça apporte |
|---|---|---|---|---|
| 1 | `failure_heatmap` | 38 | ~½ j | « ce quartier est toujours absent avant 11h » → on réordonne le passage |
| 2 | `arrival_message` | 46 | ~½ j | prévenir le client = moins d'absents = moins de second passage. Rien dans l'app ne parle au client aujourd'hui |
| 3 | `return_label` | 35 | ~1-2 h | étiquette « retour dépôt » par colis. `RecapDepotCard` n'affiche qu'une liste |
| 4 | `sector_grouping` | 38 | ~3-4 h | détecte le colis isolé **avant** l'optim. `anomaly_detection_service` admet lui-même que l'anomalie « stop à > 50 km » n'est pas traitée |
| 5 | `client_window_suggestion` | 45 | ~½ j | remplit `fenetreDebut`/`fenetreFin`, colonnes vivantes qui pilotent déjà le badge early/ok/late |
| 6 | `sos_message` | 48 | ~½ j | travailleur isolé. Prérequis : aucune clé « contact d'urgence » n'existe |
| 7 | `morning_briefing` | 51 | ~2-4 h | briefing vocal au pointage. TTS déjà vivant, branchable sans la météo |
| 8 | `weather_service` | 83 | ~½ j | seul client météo du repo. Ajouter un cache et un interrupteur (la position part chez un tiers) |
| 9 | `poi_detour` | 68 | ~4-6 h | insérer une station au moindre détour **sans** rebattre l'ordre mémorisé |
| 10 | `stop_grouping` | 59 | ~1 j | « 3 colis au même immeuble = 1 arrêt ». Aucun doublon. `compute()` est en O(n²) |
| 11 | `handover_briefing` | 86 | ~½-1 j | passation à un remplaçant. ⚠️ contient des codes d'interphone |
| 12 | `driving_time_compliance` | 42 | ~1 j | conduite continue. À formuler en conseil de sécurité, pas en obligation légale (4h30 ne s'applique pas à un VUL < 3,5 t) |
| 13 | `bordereau_mentions` | 64 | ~2-3 j | détecte +18 / signature / fragile. ⚠️ le pipeline actuel **filtre** ces mots comme du bruit ; demande une colonne et une migration |
| 14 | `battery_mode` | 33 | ~1-2 j | chaînon manquant entre l'alerte batterie et le mode éco manuel |
| 15 | `tournee_diff` | 63 | ~1 j | comparateur A/B de tournées, surtout utile côté chef |
| 16 | `evening_debrief` | 72 | ~½ j | rien ne collecte de retour de fin de journée |
| 17 | `sector_color` | 41 | — | inutile seul : moitié visuelle d'une paire avec `sector_grouping` |
| 18 | `loading_order` | 43 | — | valeur réelle mais **absente du fichier** : `compute()` est un simple `where` |
| 19 | `eco_driving` | 67 | — | fausse bonne idée en l'état : aucun plugin d'accéléromètre au pubspec |

### Quatre sont **inachevés** — ne pas les brancher tels quels

| Module | Ce qui manque |
|---|---|
| `parking_spots` | in-memory, avoue lui-même que « le storage Drift suivra ». Arbitrer d'abord vs `noteStationnement`, déjà en base |
| `cold_chain` | `sortByExpiry` est un **no-op** : il rend une copie sans trier. Et 3 maillons amont manquent |
| `end_of_day_depot` | `defaultEndAtDepot` est un **stub** qui ignore son paramètre. Sa moitié utile est déjà assurée par l'optimiseur |
| `time_loss_heatmap` | **structurellement inerte** : exige des ETA que `computeEtas` ne produit que pour les stops `à_livrer`. Sur une tournée terminée il rend toujours une map vide. Le brancher produirait un écran vide et un faux bug |

## Pièges à connaître avant de toucher à ce lot

- **Aucun des 36 n'importe un autre des 36.** N'importe quel sous-ensemble est supprimable sans cascade de compilation. Mais côté produit, des chaînes de prérequis existent en intention : `cold_chain` a besoin de `bordereau_mentions`, `morning_briefing` est taillé sur les getters de `weather_service`, `battery_mode` cible `weather_service`.
- **Chaque suppression doit emporter son test** (`app/test/data/<module>_test.dart`), sinon la CI casse à la compilation. Aucun de ces tests n'est partagé.
- **Aucune suppression ne rend une dépendance du pubspec orpheline** : `crypto` reste utilisé par `security_service`, `geo_utils` par 14 fichiers vivants.
- **Deux modules supposent une capacité absente de la plateforme** : `eco_driving` n'a pas de plugin d'accéléromètre, `tournee_share_payload` supposait un QR alors qu'aucune lib de *génération* n'est en dépendance (`mobile_scanner` ne fait que lire).
- **Deux modules composent des données personnelles** : `handover_briefing` inclut les codes d'interphone en clair, `dispute_file` l'identité client et la position GPS. S'ils partent vers un partage, exiger une confirmation explicite et ne rien mettre au presse-papiers par défaut. C'est ce qui a été fait pour `dispute_file` en #547.

## Ce que les branchements ont appris

Les trois modules branchés depuis ont chacun révélé un défaut que le module seul ne montrait pas :

- **`proximity_checker`** → `RouteMetricsAutoUpdater` *jetait* les demandes arrivées pendant une requête OSRM en vol. Invisible tant qu'un `build()` rappelait en boucle.
- **`scan_duplicate_check`** → le contrôle « mauvais arrêt » n'avait aucun point d'entrée possible dans l'app : il a fallu en créer un, sans quoi c'était du code mort de plus.
- **`dispute_file`** → son hash ne couvrait que le texte, donc la photo preuve pouvait être remplacée sans que la signature bouge. Le mot « opposable » était trompeur.

**Leçon générale** : un module non branché n'est pas « du code prêt à l'emploi qui attend ». Il n'a jamais rencontré la réalité de son point d'appel.
