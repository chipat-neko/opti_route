# scripts/

Scripts Windows pour Noah.

## `MAJ_optiroute_chef.bat`

Ouvre la dernière version d'opti_route (web app GitHub Pages) dans
Chrome avec hard-refresh forcé. Remplace l'ancien
`Installer_optiroute_chef.bat` du bureau.

### Installation

1. Télécharge ce fichier depuis GitHub :
   https://raw.githubusercontent.com/chipat-neko/opti_route/main/scripts/MAJ_optiroute_chef.bat
2. Enregistre-le sur ton bureau (clic droit → Enregistrer sous…)
3. Supprime l'ancien `Installer_optiroute_chef.bat`
4. Double-clic sur `MAJ_optiroute_chef.bat` à chaque fois que tu
   veux ouvrir le mode chef avec la dernière version

### Comment ça marche

- Ouvre l'URL https://chipat-neko.github.io/opti_route/ (web app)
- Ajoute un timestamp `?t=...` pour contourner le cache navigateur
- Cherche Chrome dans `Program Files` (préféré pour la PWA), sinon
  fallback navigateur par défaut

### Pourquoi pas l'exe ?

La web app est mise à jour automatiquement à chaque merge sur main
(workflow `.github/workflows/deploy-web.yml`). L'exe Windows nécessite
de re-télécharger / dézipper / remplacer manuellement à chaque release.

Si tu veux vraiment l'exe : voir `docs/windows-update.md` (workflow
`build-windows.yml` qui produit un ZIP en artifact GitHub Actions).
