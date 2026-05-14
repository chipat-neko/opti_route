# opti_route — version web (Flutter Web)

Ce dossier contient l'app **opti_route compilee en JavaScript** via
`flutter build web`. C'est **le meme code que l'app Android** (toutes
les features, meme base de donnees Drift, meme UI), tournant
directement dans un navigateur.

## Lancer le site

Double-clique sur **`lancer_le_site.bat`** : un serveur local Python
demarre sur `http://localhost:8080` et le navigateur s'ouvre
automatiquement.

> **Pourquoi un serveur ?**
> Flutter Web ne peut pas etre ouvert directement en `file://` a cause
> des restrictions CORS du navigateur pour le chargement du moteur de
> rendu CanvasKit et de la base SQLite.

## Ce qui marche en web

- Creation / edition / suppression de tournees
- Ajout d'arrets manuels avec autocomplete BAN / SIRENE / Photon
- Optimisation VROOM via OpenRouteService (avec ta cle)
- Carte OpenStreetMap interactive (Leaflet)
- Carnet d'adresses + recherche
- Statistiques cumulatives
- Facturation mensuelle
- Themes (clair / sombre, 4 palettes)
- Export CSV / PDF (download navigateur)
- Persistance des donnees en local (IndexedDB via Drift)

## Ce qui ne marche PAS en web

Certains plugins Android natifs n'ont pas d'equivalent web ; ils sont
ignores sans erreur :

- **OCR de bordereaux** (camera + ML Kit ne fonctionnent pas en web)
- **Verrouillage biometrique** (empreinte / visage)
- **Notifications locales** (rappel veille de tournee)
- **GPS background** (precision GPS depend du navigateur)

Pour ces features, utilise l'app Android (cf.
[install APK](../site_doc/install-apk.html)).

## Mise a jour

A chaque modif du code Dart de l'app, regenere ce dossier :

```sh
cd app
flutter build web --release
cp -r build/web/* ../opti_route_web/
```

Ou utilise le script du repo (a faire).

## Deployer en ligne

Le build est statique : tu peux le poser sur n'importe quel hebergeur
HTTP (GitHub Pages, Netlify, Cloudflare Pages...). Pour GitHub Pages
sous un sous-chemin, recompile avec `--base-href "/opti_route_web/"`.
