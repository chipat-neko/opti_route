# Audit des dependances — 2026-05-14

Verification `flutter pub outdated` apres la session features
v1.9.0+2011. **Mise a jour 2026-05-14 (apres bumps)** : 2 paquets
bumpe avec succes (`connectivity_plus 6 -> 7`, `share_plus 11 -> 12`),
les 6 autres sont bloques par interdependances (necessitent un
sprint multi-bumps coordonne).

## Bumps effectues le 2026-05-14

| Paquet | De | A | Resultat |
|---|---|---|---|
| connectivity_plus | 6.1.5 | 7.1.1 | OK — 562 tests verts, 0 issue analyzer, API `onConnectivityChanged(List<ConnectivityResult>)` inchangee |
| share_plus | 11.1.0 | 12.0.2 | OK — `SharePlus.instance.share(ShareParams(...))` inchange |

## Bumps tentes mais bloques

| Paquet | De | Vise | Bloqueur |
|---|---|---|---|
| timezone | 0.10.1 | 0.11.0 | `flutter_local_notifications 18` requiert `timezone ^0.10` |
| latlong2 | 0.9.1 | 0.10.1 | `flutter_map 8` requiert `latlong2 ^0.9` |
| share_plus | 11.1.0 | 13.1.0 | `share_plus 13` requiert `win32 ^6` ; `file_picker 8` est sur `win32 5` |

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

## Etat 2026-05-14 apres bumps

- Build APK : OK (v2.1.x)
- Tests : 562/562 verts
- Analyzer : 0 issue
- 2 deps bumpees : connectivity_plus 7, share_plus 12
- 6 deps reportees aux sprints A/B/C/D ci-dessus
