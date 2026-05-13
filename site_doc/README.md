# Site compagnon opti_route

Site web statique (HTML/CSS/JS pur) accompagnant l'app Flutter. Sert
de :
- **Vitrine** marketing (`index.html`)
- **Tableau de bord chef d'equipe** (`dashboard.html`) : upload du CSV
  expoté depuis l'app → visualisation interactive

## Pile technique

- HTML5 sémantique + CSS3 (variables CSS pour le thème)
- JS vanilla (zéro framework)
- [Chart.js](https://www.chartjs.org/) en CDN pour les graphes
- Google Fonts : Manrope + JetBrains Mono

## Thème

Identique à l'app (`app/lib/theme/app_tokens.dart`) :
- Mode clair (défaut) + mode sombre (toggle bouton ☾)
- Palette : cream / ink / lime + accents emerald / amber / red
- Le mode est persisté en `localStorage`

## Structure

```
docs/website/
├── index.html        — Landing page (hero + features + équipe + how + footer)
├── dashboard.html    — Viewer CSV interactif (upload + stats + graphes + tableau)
├── styles.css        — Tokens + composants (réutilisé sur les 2 pages)
├── script.js         — Theme toggle commun
├── dashboard.js      — Parser CSV + Chart.js + interactions dashboard
└── assets/
    └── favicon.svg   — Logo pin + route lime
```

## Dashboard : format CSV attendu

Header obligatoire :

```
date,nom,statut,arrets,colis_livres,distance_km,duree_min,pause_min
```

C'est exactement le format produit par
`StatsService.exportCsvTournees` dans l'app
(`app/lib/data/stats_service.dart`). L'utilisateur exporte depuis
**Statistiques → Exporter en CSV**, puis se l'envoie à lui-même
(email / Drive) et l'ouvre sur le web.

## Déploiement GitHub Pages

1. Aller dans le repo GitHub → **Settings** → **Pages**.
2. Source : **Deploy from a branch**.
3. Branche : `main` (ou la branche courante), dossier : `/docs`.
4. Save. L'URL sera `https://chipat-neko.github.io/opti_route/website/`.

Le site est statique : aucune build step, juste les fichiers tels
quels. Toute modification sur `main` est déployée automatiquement.

## Tester en local

Pas de serveur requis pour les pages individuelles, mais Chart.js
charge mieux derrière un mini serveur. Au choix :

```sh
# Python 3
cd docs/website
python -m http.server 8000
# Ouvre http://localhost:8000

# Ou Node
npx serve docs/website
```

## Important : limites Phase 1

Le dashboard est un **viewer local** : il lit un CSV envoyé
manuellement depuis l'app, dans le navigateur de l'utilisateur. Aucune
donnée n'est envoyée à un serveur.

Pour une vraie sync temps-réel (chef voit les coéquipiers en direct
sans qu'ils envoient quoi que ce soit), il faut un **backend en
Phase 2** : Firebase Auth + Firestore ou Supabase. Estimation : ~25
USD/mois minimum pour un usage solo, plus si plusieurs comptes.
