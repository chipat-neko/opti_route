# scripts/

Scripts Windows pour Noah (mise à jour du logiciel chef MSIX sur PC).

## Workflow d'update (le plus simple)

Double-clic sur le raccourci **"MAJ opti_route chef"** sur ton bureau.
C'est tout.

> Si le raccourci n'existe pas encore, va dans `E:\opti_route\scripts\`
> et lance **`Creer_raccourci_bureau.bat`** UNE FOIS. Il crée le
> raccourci automatiquement.

Le script (PowerShell) enchaîne avec une **vraie barre de progression** :
1. **Check distant** : compare HEAD vs `origin/main`. Si à jour → skip
   tout, te le dit en 5 secondes (pas de rebuild inutile).
2. `git pull` dans `E:\opti_route` (si en retard)
3. `flutter pub get`
4. `flutter build windows --release --dart-define-from-file=cloud.env.json`
5. `dart run msix:create` (package en MSIX, signé avec ton cert existant)
6. Lance `Installer_optiroute_chef.bat` (UAC → certutil + Add-AppxPackage)

**Durée typique** : 8-12 minutes (le build Flutter Windows est lent).
Tu vois en permanence l'étape en cours + le temps écoulé.

**Log** : `%USERPROFILE%\Desktop\optiroute_maj_log.txt` si quelque chose
casse.

**Anti double-run** : un mutex (fichier lock `%TEMP%\optiroute_maj.lock`)
empêche 2 instances en parallèle. Si tu double-cliques 2× le raccourci,
la 2ème instance refuse poliment au lieu de bouclier sur le repo.

**Options avancées** (lancer le .bat en ligne de commande) :
- `-Force` : rebuild même si déjà à jour (rare)
- `-NoInstall` : build seulement, ne lance pas l'installeur

---

## Les fichiers

### `MAJ_optiroute_chef.ps1`
**Le vrai script** (PowerShell). Mutex anti double-run, barre de
progression Write-Progress native, skip si à jour, détection précise
des erreurs (capture exit code + stderr → log).

### `MAJ_optiroute_chef.bat`
Wrapper minuscule qui lance le `.ps1`. C'est lui que tu double-cliques
(ou plutôt son raccourci sur le bureau).

### `Creer_raccourci_bureau.bat`
Crée un raccourci `.lnk` "MAJ opti_route chef" sur le bureau qui
pointe vers le `.bat` ci-dessus. À lancer **une seule fois** après
clone du repo. Avantage : si tu bouges le repo plus tard, le raccourci
suit (il pointe vers un dossier, pas vers une copie figée).

### `Installer_optiroute_chef.bat`
Installe le MSIX déjà buildé (certutil + Add-AppxPackage, auto-élève
en admin via UAC). Appelé automatiquement à l'étape 6 de la MAJ.
Garde-le sur ton bureau : `copy E:\opti_route\scripts\Installer_optiroute_chef.bat %USERPROFILE%\Desktop\`

---

## Installation initiale

Si tu installes opti_route chef sur **un nouveau PC** :

1. Cloner le repo sur disque NTFS (C: ou E:, pas exFAT) :
   ```
   git clone https://github.com/chipat-neko/opti_route.git E:\opti_route
   ```
2. Activer **Dev Mode Windows** (Réglages > Espace développeurs)
3. Installer **VS Build Tools 2022** avec le composant C++ ATL
4. Télécharger nuget.exe et le mettre dans un dossier local de ton
   choix (par exemple `%USERPROFILE%\nugettools\`, soit
   `C:\Users\Noah\nugettools\` sur le poste de Noah — c'est un
   exemple, pas un chemin imposé)
5. Copier `cloud.env.json` dans `E:\opti_route\app\` (credentials Supabase, jamais commit)
6. Copier `Installer_optiroute_chef.bat` sur le bureau
7. Lancer `E:\opti_route\scripts\Creer_raccourci_bureau.bat` une fois
   (crée le raccourci "MAJ opti_route chef" sur le bureau)
8. Double-clic sur le raccourci → premier build complet + install

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
