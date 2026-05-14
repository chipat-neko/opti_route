# Smoke tests device — APK v2.4.x — 2026-05-14

Procedure de validation **device reel** apres les bumps deps Sprint B
(flutter_local_notifications 18 -> 21, 3 majors) et Sprint C (local_auth
2 -> 3 + local_auth_android 1 -> 2). Ces 2 sprints touchent les couches
natives Android : les regressions peuvent etre **silencieuses en
release uniquement** (marchent en debug, ratent en prod).

A executer sur le **Xiaomi** apres install de l'APK release.

---

## 1. Notifications v21 (10 min)

**But** : verifier qu'une notif planifiee se declenche bien apres
l'echeance, en mode release, apres la migration positional -> named
parameters de `flutter_local_notifications`.

**Procedure** :

1. Ouvrir l'app -> menu hamburger -> **Parametres**
2. Faire defiler jusqu'a **Notifications**
3. Taper **"Test : notif dans 2 min"**
4. Verifier que le snackbar confirme "Notif test programmee dans 120 s"
5. **Verrouiller l'ecran** (bouton power), poser le phone
6. Attendre 2-3 minutes (mettre un minuteur)
7. La notif doit apparaitre :
   - **Titre** : `Test notification opti_route`
   - **Body** : `Bravo, les notifs locales marchent ! (declenchee a HH:MM:SS)`
   - Icone : ic_launcher de l'app
   - Channel : `Rappels de tournee` (Importance.high -> vibration + son)

**Resultat attendu** : KO (regression Sprint B) si :
- Aucune notif apres 5 min
- Notif apparait MAIS sans vibration / son (channel mal cree)
- Crash de l'app au tap "Test"
- Notif apparait au lancement de l'app au lieu de l'echeance (timer
  rate, deja vu sur les anciennes versions du plugin)

**Si KO** : checker logcat pendant l'echeance :
```
adb logcat -s FlutterLocalNotifications:V flutter:V
```
Probablement un crash silencieux a la deserialisation Gson (le
plugin v19+ a normalement integre Gson 2.12, mais nos ProGuard rules
historiques peuvent interferer). Reverter au commit `35525be^` (avant
bump notifications) en attendant fix.

---

## 2. Biometrie v3 (5 min)

**But** : verifier qu'apres la migration `AuthenticationOptions`
wrapper supprime + `stickyAuth` -> `persistAcrossBackgrounding` +
`biometricHint` -> `signInHint`, le LockScreen biometrique marche
toujours en release.

**Pre-requis** : avoir une empreinte enrolee sur le Xiaomi (ou
reconnaissance faciale, l'un ou l'autre).

**Procedure** :

1. Ouvrir l'app -> menu hamburger -> **Parametres**
2. Section **Securite** -> activer **"PIN de deverrouillage"**
3. Saisir un PIN 4-6 chiffres (ex: 1234) -> confirmer
4. Toggle **"Authentification biometrique"** -> ON
   - L'OS doit afficher une boite de dialogue empreinte/face pour
     **valider l'activation**. C'est normal.
5. **Fermer COMPLETEMENT l'app** : swipe-out du multitache (pas juste
   home button -- il faut que l'app soit deroutee du recent apps).
6. Relancer l'app depuis le launcher
7. Le **LockScreen** doit apparaitre :
   - Texte "opti_route" (signInTitle)
   - Hint "Touche le capteur ou montre ton visage" (nouvel signInHint)
   - Bouton "Utiliser le PIN" (cancelButton)
8. **Sans rien faire**, attendre 1 sec : le scanner biometrique doit
   s'activer automatiquement et accepter une empreinte
9. L'app se deverrouille -> HomeScreen apparait

**Resultat attendu** : KO (regression Sprint C) si :
- LockScreen n'apparait pas du tout au cold start
- LockScreen apparait MAIS scanner bio ne s'active pas
- Scanner accepte n'importe quelle empreinte (cas hypothetique grave)
- Crash au moment de l'activation initiale

**Si KO** : checker logcat pour `LocalAuthException` :
```
adb logcat -s LocalAuth:V flutter:V MainActivity:V
```
Sprint C a casse `useErrorDialogs` (retire) -> si l'app ne catche
plus les erreurs systeme, elle peut crash sur "no biometric enrolled"
au lieu de fallback PIN. Reverter au commit pre-Sprint C en attendant.

---

## 3. Smoke optionnel : tests unitaires (post-VSCode)

A faire **apres** avoir ferme VSCode pour debloquer le lock Windows
sur `build/native_assets/sqlite3.dll` (cf
[[project-pending-flutter-test-validation]]).

```powershell
# Tuer l'Analyzer VSCode
Get-Process dart | Stop-Process -Force

# Lancer le test
cd d:/opti_route/app
flutter test
```

**Attendu** : **578 tests verts** (les 8 widget_smoke_test reactives
au commit `35525be` doivent maintenant passer grace au bundle Manrope
+ JetBrainsMono + `GoogleFonts.config.allowRuntimeFetching = false`).

---

## Resume

| Test                | Duree | Critere KO                         |
|---------------------|-------|------------------------------------|
| 1. Notif test 2 min | 3 min | Notif ne se declenche pas          |
| 2. LockScreen bio   | 5 min | LockScreen absent ou bio inactive  |
| 3. `flutter test`   | 30 s  | Moins de 578 verts                 |

Si les 3 sont OK -> Sprint A/B/C de la session 2026-05-14 valides en
release. Branche `feat/vague-A-mode-terrain` peut etre poussee +
mergee sur main sans crainte.
