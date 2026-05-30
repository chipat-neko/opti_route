# Mettre à jour opti_route chef sur ton PC

Ton installation actuelle utilise un **MSIX signé** (app Windows
native dans le menu Démarrer). Pour mettre à jour : double-clic sur
**`MAJ_optiroute_chef.bat`** sur ton bureau.

Le script :
1. `git pull` sur `E:\opti_route`
2. `flutter pub get`
3. `flutter build windows --release --dart-define-from-file=cloud.env.json`
4. `dart run msix:create` (re-package + re-signe avec ton cert)
5. Lance `Installer_optiroute_chef.bat` (UAC → certutil + Add-AppxPackage)

Durée : 8-12 min. Log : `%USERPROFILE%\Desktop\optiroute_maj_log.txt`.

Voir `scripts/README.md` pour le détail.

---

## Important : bump `msix_version` à chaque release

Windows refuse d'installer un MSIX qui a la même version que celui
déjà présent. Avant chaque update tu veux distribuer (ou que tu pull),
le maintainer doit bumper `msix_version` dans `app/pubspec.yaml` :

```yaml
msix_config:
  msix_version: 2.9.0.0   # ← incrementer (ex 2.9.1.0)
```

Si tu lances `MAJ_optiroute_chef.bat` après un `git pull` et que la
version n'a pas changé, l'étape 5 affichera `addappx code=1` dans le
log et l'app restera à l'ancienne. C'est pour ça que le bump est
critique.

---

## Setup initial sur un nouveau PC

1. Clone NTFS : `git clone https://github.com/chipat-neko/opti_route.git E:\opti_route`
2. **Dev Mode Windows** ON (Réglages > Espace développeurs)
3. **VS Build Tools 2022** + composant C++ ATL (cf
   [`feedback_windows_build_exfat.md`](../C:\Users\Noah\.claude\projects\d--opti-route\memory\feedback_windows_build_exfat.md)
   memory)
4. `nuget.exe` dans `C:\Users\Noah\nugettools\`
5. Copier `cloud.env.json` dans `E:\opti_route\app\` (jamais commit)
6. Mettre `MAJ_optiroute_chef.bat` et `Installer_optiroute_chef.bat`
   sur le bureau (depuis `scripts/` du repo)
7. Double-clic `MAJ_optiroute_chef.bat` → build complet + install

---

## Alternative web (sans rien installer)

Si tu veux juste consulter le dashboard chef depuis n'importe quel
appareil sans rien builder : **https://chipat-neko.github.io/opti_route/**

La web app GitHub Pages est rebuildé automatiquement à chaque merge
sur main (`.github/workflows/deploy-web.yml`). Tu vois la dernière
version en faisant `Ctrl+Shift+R` dans Chrome.

Différences vs le MSIX :
- ✅ Mise à jour auto, rien à installer
- ❌ Pas d'icône menu Démarrer
- ❌ Performances JS légèrement moins bonnes que natif
- ❌ Pas d'accès à `flutter_local_notifications` Windows ni à certains
  plugins natifs

Pour Noah qui a déjà l'install MSIX : le `MAJ_optiroute_chef.bat`
reste le bon workflow. La web app est un fallback si jamais tu es sur
un PC sans setup.

---

## Alternative : GitHub Actions Windows artifact (.exe sans MSIX)

Le workflow `.github/workflows/build-windows.yml` produit un **.exe**
(pas MSIX, pas signé) en artifact ZIP téléchargeable.

URL : https://github.com/chipat-neko/opti_route/actions/workflows/build-windows.yml

Tu télécharges le ZIP, dézippes, lances `opti_route.exe`. C'est utile
pour :
- Tester rapidement sur un PC où tu n'as pas le setup Flutter
- Donner à quelqu'un sans qu'il installe rien

**Limite** : pas d'icône menu Démarrer (lance depuis l'.exe direct
ou un raccourci à créer), SmartScreen peut grogner au 1er lancement
(cliquer "Plus d'infos" → "Exécuter quand même").
