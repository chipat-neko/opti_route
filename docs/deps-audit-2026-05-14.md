# Audit des dependances — 2026-05-14

Verification `flutter pub outdated` apres la session features
v1.9.0+2011. **Aucun bump effectue** dans cette session : tous les
paquets obsoletes necessitent un major bump (breaking changes
potentiels), trop risque sans tests dedies.

## Etat actuel

Tous les paquets directs sont sur des versions stables, sans
upgrade patch/minor automatique disponible. Les obsolescences sont
purement des major bumps :

| Paquet | Actuel | Latest | Type | Risque |
|---|---|---|---|---|
| connectivity_plus | 6.1.5 | 7.1.1 | MAJOR | Moyen — API `onConnectivityChanged` peut-etre changee |
| file_picker | 8.3.7 | 11.0.2 | MAJOR x3 | **Eleve** — 3 versions de retard, API probablement bougee |
| flutter_local_notifications | 18.0.1 | 21.0.0 | MAJOR x3 | **Eleve** — ProGuard rules deja sensibles (TypeToken Gson), 3 versions de retard |
| latlong2 | 0.9.1 | 0.10.1 | MAJOR (pre-1.0) | Faible — utilise seulement par flutter_map |
| local_auth | 2.3.0 | 3.0.1 | MAJOR | Moyen — `AuthMessages` API peut bouger |
| local_auth_android | 1.0.56 | 2.0.8 | MAJOR | Va avec local_auth |
| share_plus | 11.1.0 | 13.1.0 | MAJOR x2 | Moyen — `SharePlus.instance.share()` deja utilise partout |
| timezone | 0.10.1 | 0.11.0 | MAJOR (pre-1.0) | Faible — setup tz tres stable |

## Recommandations

### A faire dans un sprint dedie "deps modernisation" (1-2 jours)

Procedure pour bumper proprement chaque major :

1. **Bumper 1 paquet a la fois** (pas tout d'un coup)
2. Lire le **changelog** du paquet sur pub.dev (section "BREAKING")
3. Adapter le code qui casse a la compilation
4. Relancer **toute la suite de tests** (`flutter test`)
5. Build APK + smoke test sur device reel
6. Commit isole `chore(deps): bump X v8 -> v11`

### Ordre suggere (du moins risque au plus risque)

1. `timezone` 0.10 → 0.11 (1 fichier touche : `notifications_service.dart`)
2. `latlong2` 0.9 → 0.10 (uniquement flutter_map, isole)
3. `connectivity_plus` 6 → 7 (1 fichier touche : `offline_geocode_automation.dart`)
4. `share_plus` 11 → 13 (5+ fichiers touches : backup, share template,
   stats export, PDF tournee, share text tournee)
5. `local_auth` 2 → 3 (lock_screen.dart + security_service.dart)
6. `file_picker` 8 → 11 (carnet_adresses_screen, tournees_list_screen,
   parametres_screen pour restore) — **changements API les plus
   probables**
7. `flutter_local_notifications` 18 → 21 — **a faire en DERNIER**,
   sensible aux ProGuard rules (cf [[feedback-proguard-local-notifications]])

### A NE PAS faire

- `flutter pub upgrade --major-versions` sans verifier chaque diff.
  Risque de TOUT casser en silence.
- Bumper `flutter_local_notifications` en meme temps que les autres :
  les regressions sont silencieuses (notifs qui ne firent plus en
  release uniquement).

## Verdict 2026-05-14

App actuellement stable a v1.9.0+2011, **548 tests verts**, 0 issue
analyzer. Pas urgent de bumper. A planifier dans un sprint dedie
quand on a 2 jours libres et un device de test sous la main.
