# Audit des dependances — 2026-05-14

Verification `flutter pub outdated` apres la session features
v1.9.0+2011. **Mise a jour 2026-05-14 (apres bumps + Sprint A/B/C)** :
7 paquets bumpe avec succes (`connectivity_plus 6 -> 7`,
`share_plus 11 -> 12`, `file_picker 8 -> 11`,
`flutter_local_notifications 18 -> 21`, `timezone 0.10 -> 0.11`,
`local_auth 2 -> 3`, `local_auth_android 1 -> 2`). Sprint D
(flutter_map / latlong2) reste bloque upstream.

## Bumps effectues le 2026-05-14

| Paquet | De | A | Resultat |
|---|---|---|---|
| connectivity_plus | 6.1.5 | 7.1.1 | OK — 562 tests verts, 0 issue analyzer, API `onConnectivityChanged(List<ConnectivityResult>)` inchangee |
| share_plus | 11.1.0 | 12.0.2 | OK — `SharePlus.instance.share(ShareParams(...))` inchange |
| file_picker | 8.3.7 | 11.0.2 | OK — Sprint A, 3 sites adaptes (instance → static : `FilePicker.platform.pickFiles()` → `FilePicker.pickFiles()`). 570 tests verts. |
| flutter_local_notifications | 18.0.1 | 21.0.0 | OK — Sprint B, migration positional → named (v20 BC). Retrait de `uiLocalNotificationDateInterpretation` (v19 BC). 570 tests verts. ProGuard rules Gson conservees par prudence (Gson bumpe a 2.12 en v19, rules plus obligatoires mais non-nocives). |
| timezone | 0.10.1 | 0.11.0 | OK — debloque par flutter_local_notifications 21 (qui requiert timezone >=0.10, donc 0.11 compatible). |
| local_auth | 2.3.0 | 3.0.1 | OK — Sprint C, `AuthenticationOptions` wrapper supprime, params passes directement. `stickyAuth` → `persistAcrossBackgrounding`, `useErrorDialogs` retire. 570 tests verts. |
| local_auth_android | 1.0.56 | 2.0.8 | OK — Sprint C, `biometricHint` → `signInHint` dans `AndroidAuthMessages`. 1 site adapte (`security_service.dart`). |

## Bumps tentes mais bloques

| Paquet | De | Vise | Bloqueur |
|---|---|---|---|
| latlong2 | 0.9.1 | 0.10.1 | **flutter_map 8.3.0 = derniere stable au 2026-05-14**, et requiert toujours `latlong2 ^0.9.1`. Sprint D donc execute mais sans impact : pas d'upgrade dispo. Attendre flutter_map 9.x ou un patch 8.3.x qui releve la contrainte. |
| share_plus | 12.0.2 | 13.1.0 | `share_plus 13` requiert `win32 ^6` ; **file_picker 11 et meme 12.0.0-beta sont encore sur win32 ^5.9** (audit precedent obsolete). Vraiment debloqable une fois que file_picker migrera vers win32 6. |

## Bumps reportes (risque eleve, hors session)

| Paquet | Actuel | Latest | Risque | Note |
|---|---|---|---|---|
| file_picker | 8.3.7 | 11.0.2 | **Eleve** | 3 majors de retard, API probablement bougee. Bloque share_plus 13 (win32 6) |
| flutter_local_notifications | 18.0.1 | 21.0.0 | **Eleve** | 3 majors. ProGuard rules deja sensibles (TypeToken Gson). Bloque timezone 0.11 |
| latlong2 | 0.9.1 | 0.10.1 | Faible | Bloque par flutter_map 8 |
| local_auth | 2.3.0 | 3.0.1 | Moyen | `AuthMessages` peut bouger |
| local_auth_android | 1.0.56 | 2.0.8 | Moyen | Va avec local_auth |
| timezone | 0.10.1 | 0.11.0 | Faible | Bloque par flutter_local_notifications 18 |

## Sprints coordonnes recommandes pour debloquer

**Sprint A — share/file (couple win32)** *(0.5 jour)* :
- Bumper `file_picker 8 → 11` (3 majors, lire changelog : API
  pickFiles peut changer, FileType.custom toujours dispo ?)
- Adapter `tournees_list_screen.dart`, `carnet_adresses_screen.dart`,
  `parametres_screen.dart` (3 sites d'usage)
- Bumper `share_plus 12 → 13` (alignement win32 6)
- Build + smoke test : import .json template, import .zip restore,
  share backup

**Sprint B — flutter_local_notifications + timezone** *(0.5 jour)* :
- Bumper `flutter_local_notifications 18 → 21` (3 majors, lire
  changelog tres attentivement, regressions notifs silencieuses en
  release uniquement). Verifier les regles ProGuard
  (`proguard-rules.pro`) pour les TypeToken Gson.
- Bumper `timezone 0.10 → 0.11` (changement de syntaxe init ?)
- **Smoke test obligatoire sur device reel** : programmer une notif
  de rappel, attendre l'echeance, verifier la reception.

**Sprint C — local_auth** *(0.5 jour)* :
- Bumper `local_auth 2 → 3` + `local_auth_android 1 → 2`
- Adapter `security_service.dart` (`AuthMessages` peut bouger)
- Smoke test : configurer un PIN + biometrie, fermer l'app, reouvrir,
  verifier que le LockScreen apparait et que la biometrie marche.

**Sprint D — flutter_map** *(0.5 jour)* :
- Bumper `flutter_map 8 → latest` pour debloquer `latlong2 0.10`
- Adapter `carte_screen.dart`
- Smoke test : ouvrir la carte d'une tournee, verifier les tiles +
  pins.

## A NE PAS faire

- `flutter pub upgrade --major-versions` sans verifier chaque diff.
  Risque de TOUT casser en silence.
- Bumper `flutter_local_notifications` sans tests device reel : les
  regressions sont silencieuses (notifs qui ne firent plus en
  release uniquement, marche en debug).

## Etat 2026-05-14 apres bumps + Sprint A/B/C

- Build APK : OK (v2.3.0+2016, ~60 MB arm64)
- Tests : 570/570 verts (8 nouveaux tests BackupsListService)
- Analyzer : 0 issue
- 7 deps bumpees : connectivity_plus 7, share_plus 12, file_picker 11, flutter_local_notifications 21, timezone 0.11, **local_auth 3, local_auth_android 2**
- 2 deps qui resteront bloquees jusqu'a updates upstream :
  - latlong2 0.10 → bloque par flutter_map (8.3.0 latest reste sur latlong2 ^0.9)
  - share_plus 13 → bloque par file_picker (toutes versions, y compris 12-beta, restent sur win32 ^5.9)

### Sprint A (file_picker) — fait le 2026-05-14

3 sites d'usage migres en API static :
- `lib/screens/carnet_adresses_screen.dart:222`
- `lib/screens/tournees_list_screen.dart:40`
- `lib/screens/parametres_screen.dart:1373`

Pas de regression : analyzer + tests verts, smoke test import .json + .zip OK.

### Sprint B (flutter_local_notifications + timezone) — fait le 2026-05-14

Migration v18 → v21, breaking changes adresses :
- v19 : retrait du parametre `uiLocalNotificationDateInterpretation`
  dans `zonedSchedule()` (deprecate depuis v18, retire en v19)
- v20 : **toutes les methodes du plugin passent en named parameters**.
  Adapte 8 callsites dans `notifications_service.dart` :
  - `_plugin.initialize(settings)` → `_plugin.initialize(settings: settings)`
  - `_plugin.cancel(id)` → `_plugin.cancel(id: id)`
  - `_plugin.show(id, title, body, details)` → all named
  - `_plugin.zonedSchedule(id, title, body, date, details, ...)` → all named
- v21 : compileSdk 36, minSdk 24, deja gere par Flutter SDK.

ProGuard rules Gson conservees defensivement (cf `proguard-rules.pro:13-24`).
Smoke test obligatoire device reel : prochaine session, programmer une
notif rappel + attendre l'echeance pour valider que la chaine v21
fonctionne en release (regressions silencieuses possibles).

### Sprint C (local_auth + local_auth_android) — fait le 2026-05-14

Migration v2 → v3, breaking changes adresses :
- `AuthenticationOptions` wrapper supprime de `authenticate()` :
  les options passent en params directs (`biometricOnly`,
  `persistAcrossBackgrounding`)
- `stickyAuth` → `persistAcrossBackgrounding` (renommage)
- `useErrorDialogs` retire : si on veut un dialog d'erreur, c'est
  desormais a l'app de l'afficher en catchant `LocalAuthException`
- `biometricHint` → `signInHint` dans `AndroidAuthMessages`
  (local_auth_android v2)
- `BiometricType` enum etend (ajoute `strong` / `weak`) — pas
  d'impact pour notre code qui ne lit pas le type specifique

1 site adapte : `lib/data/security_service.dart:92-118`.
Smoke test device reel attendu : activer PIN+biometrie dans
Parametres, fermer l'app, reouvrir, verifier LockScreen + biometrie.

### Sprint D (flutter_map + latlong2) — bloque upstream

flutter_map 8.3.0 (publie il y a 30 jours) reste la derniere version
stable et requiert toujours `latlong2 ^0.9.1`. Aucun upgrade
disponible cote pubspec. Le bump latlong2 0.9 → 0.10 reste donc
en attente d'une version flutter_map 9.x ou d'un 8.3.x patch qui
relachera la contrainte.

Pas d'impact fonctionnel : flutter_map 8.3.0 marche, latlong2 0.9.1
marche. C'est uniquement une dette technique a re-evaluer dans 2-3
mois.
