# scripts/

Scripts Windows pour Noah (mise à jour du logiciel chef MSIX sur PC).

## Workflow d'update (le plus simple)

Double-clic sur **`MAJ_optiroute_chef.bat`** sur ton bureau. C'est tout.

Le script enchaîne :
1. `git pull` dans `E:\opti_route`
2. `flutter pub get`
3. `flutter build windows --release --dart-define-from-file=cloud.env.json`
4. `dart run msix:create` (package en MSIX, signé avec ton cert existant)
5. Lance `Installer_optiroute_chef.bat` (UAC → certutil + Add-AppxPackage)

**Durée typique** : 8-12 minutes (le build Flutter Windows est lent).

**Log** : `%USERPROFILE%\Desktop\optiroute_maj_log.txt` si quelque chose
casse.

---

## Les 2 fichiers

### `MAJ_optiroute_chef.bat`
Le **nouveau** script à mettre sur le bureau. Pull + build + install
en une seule commande. C'est lui que tu lances pour update.

### `Installer_optiroute_chef.bat`
L'**ancien** script (versionné ici pour ne pas le perdre). Installe le
MSIX déjà buildé. `MAJ_optiroute_chef.bat` l'appelle automatiquement
en étape 5.

Si tu le perds du bureau : `copy E:\opti_route\scripts\Installer_optiroute_chef.bat %USERPROFILE%\Desktop\`

---

## Installation initiale

Si tu installes opti_route chef sur **un nouveau PC** :

1. Cloner le repo sur disque NTFS (C: ou E:, pas exFAT) :
   ```
   git clone https://github.com/chipat-neko/opti_route.git E:\opti_route
   ```
2. Activer **Dev Mode Windows** (Réglages > Espace développeurs)
3. Installer **VS Build Tools 2022** avec le composant C++ ATL
4. Télécharger nuget.exe et le mettre dans `C:\Users\Noah\nugettools\`
5. Copier `cloud.env.json` dans `E:\opti_route\app\` (credentials Supabase, jamais commit)
6. Copier `Installer_optiroute_chef.bat` et `MAJ_optiroute_chef.bat`
   sur le bureau
7. Double-clic `MAJ_optiroute_chef.bat` → premier build complet + install

Détails dans la mémoire de session
[[feedback-windows-build-exfat]] (build) et
[[project-logiciel-chef-88]] (#88·5).

---

## Pourquoi un MSIX et pas un .exe ?

- MSIX = vraie app Windows native (apparaît dans le menu Démarrer)
- Signature cert auto-générée = pas de SmartScreen warning à chaque
  lancement
- Update propre via `Add-AppxPackage` (gère la migration auto si
  `msix_version` > précédente)
- Désinstallation propre via Réglages > Applications

**À chaque PR mergée qui modifie l'app**, n'oublie pas de bumper
`msix_version` dans `app/pubspec.yaml` sinon Windows refuse de réinstaller
("application déjà présente").

---

## Alternative : GitHub Actions Windows artifact

Un workflow `.github/workflows/build-windows.yml` build aussi un .exe
(pas MSIX) en artifact ZIP téléchargeable. Voir `docs/windows-update.md`.
Utile si tu changes de PC et que tu veux juste un exe sans tout le
setup local. Ne remplace pas le MSIX (pas de menu Démarrer, pas de
cert installé).
