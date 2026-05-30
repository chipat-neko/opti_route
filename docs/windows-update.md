# Mettre à jour opti_route sur ton PC

## ✅ Recommandé : PWA Chrome (mise à jour automatique)

Au lieu de l'exe, installe la web app comme PWA. Avantages : icône
sur le bureau identique à un .exe, fonctionne hors ligne, et **se met
à jour automatiquement** quand un nouveau code est mergé.

### Première install

1. Ouvre Chrome (ou Edge) et va sur **https://chipat-neko.github.io/opti_route/**
2. Dans la barre d'adresse, à droite, tu vois une icône **"+"** ou
   "Installer". Sinon : menu **⋮** (3 points) en haut à droite →
   **Installer opti_route** ou **Installer cette application**
3. Confirme. Une icône `opti_route` apparaît sur le bureau et dans
   le menu Démarrer.
4. Double-clic sur l'icône = la PWA s'ouvre comme une vraie app
   (sans barre d'URL, plein écran).

### Mise à jour

Aucune action manuelle. Quand tu lances la PWA et qu'il y a une
nouvelle version sur GitHub Pages, Chrome la télécharge en arrière-plan
et l'active au prochain lancement. **Pour forcer immédiatement :**
- Dans la PWA, **`Ctrl + Shift + R`** (hard refresh, vide le cache)
- Ou ferme complètement la PWA + relance

### Désinstaller

Menu Windows → clic droit sur `opti_route` → Désinstaller. Ou dans
Chrome : `chrome://apps` → clic droit → Supprimer.

---

## Alternative : Exe Windows téléchargé depuis GitHub Actions

Si tu préfères vraiment l'exe (mode hors-ligne total, indépendant
de Chrome), tu peux télécharger un build Windows depuis GitHub Actions
après chaque merge sur main.

### Première install

1. Va sur https://github.com/chipat-neko/opti_route/actions
2. Clique sur le workflow **"Build Windows (.exe) → artifact"** dans
   la colonne de gauche
3. Choisis la dernière exécution en haut de la liste (status ✅)
4. Scroll en bas → section **Artifacts** → clique sur
   `opti_route-windows-<sha>` pour télécharger le ZIP
5. Dézippe quelque part (ex: `C:\Apps\opti_route\`)
6. Crée un raccourci sur le bureau pointant vers
   `C:\Apps\opti_route\opti_route.exe`
7. Double-clic = l'app s'ouvre

### Mise à jour

À chaque merge sur main, un nouveau ZIP est produit (5-10 min après).
Procédure :

1. Va sur https://github.com/chipat-neko/opti_route/actions/workflows/build-windows.yml
2. Télécharge le ZIP de la dernière exécution
3. Ferme l'app si elle est ouverte
4. Dézippe dans le même dossier (`C:\Apps\opti_route\`) en
   **remplaçant** tous les fichiers existants
5. Relance via ton raccourci

**Note** : le ZIP contient `opti_route.exe` + plusieurs DLL Flutter
(`flutter_windows.dll`, `*.dll` plugins). Tu dois TOUT remplacer en
même temps — un mix ancien exe / nouvelles DLL crashe au démarrage.

### Forcer un rebuild sans push

Si tu veux un build à la demande (par exemple pour tester une
branche) :
1. Va sur https://github.com/chipat-neko/opti_route/actions/workflows/build-windows.yml
2. Bouton **"Run workflow"** → choisis la branche → **Run**
3. Attends 8-12 min, télécharge l'artifact

---

## Comparatif

| | PWA Chrome | Exe Windows |
|---|---|---|
| Install | 30 s | 2-3 min |
| Update | Auto (`Ctrl+Shift+R` pour forcer) | Manuel à chaque release |
| Hors ligne | ✅ (service worker) | ✅ |
| Plein écran sans navigateur | ✅ | ✅ |
| Cloud Supabase | ✅ | ✅ (si secret CLOUD_ENV_JSON défini) |
| Performance | Légèrement plus lente (JS) | Plus rapide (natif) |
| Crash récup | Recharge la page | Relancer l'exe |

**Pour Noah** : la PWA suffit pour 99 % des usages. Garde l'exe
seulement si tu veux un mode "vraiment offline jamais connecté".
