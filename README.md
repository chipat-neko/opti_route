# opti_route

Application mobile d'optimisation de tournées pour livreur multi-points.

## État du projet

🚧 **En développement actif** — Phase 1 (version gratuite, Android uniquement). Voir [docs/plan_free.md](docs/plan_free.md) pour le plan détaillé.

## Objectif

Aider un chauffeur-livreur à organiser sa tournée quotidienne :
- Saisie d'adresses **manuelle ou par OCR caméra** sur les bordereaux.
- Définition de **contraintes par client** : priorité (premier/dernier), nombre de colis, fenêtres horaires, notes.
- **Optimisation automatique** de l'ordre de passage pour minimiser le temps total.
- **Mode tournée en cours** avec lancement de la navigation externe (Google Maps / Waze).
- **CarPlay et Android Auto** prévus en Phase 3.

## Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter 3.x (Dart) — un code, iOS + Android |
| Carte | `flutter_map` + tuiles OpenStreetMap |
| Optimisation | OpenRouteService (free tier, basé sur VROOM) |
| Géocodage | Nominatim |
| OCR | Google ML Kit (sur l'appareil, gratuit) |
| Stockage | SQLite via `drift` |
| État | Riverpod |

Une **version CB** ([docs/plan_cb.md](docs/plan_cb.md)) avec Google Maps Platform est planifiée mais réservée à plus tard.

## Structure du dépôt

```
opti_route/
├── app/        ← projet Flutter (code applicatif)
└── docs/       ← plans, documentation, scripts d'aide
```

## Conventions de développement

Le projet suit un workflow **trunk-based avec Pull Requests** :
- Branche `main` protégée — jamais de commit direct.
- Branches dédiées par changement : `feat/...`, `fix/...`, `chore/...`, `docs/...`, `refactor/...`, `test/...`.
- **Conventional Commits** obligatoires (`feat: ...`, `fix: ...`, etc.).
- Squash merge dans `main` après revue de la PR.
- Tags de version (`v0.1.0`, `v0.2.0`...) à chaque jalon majeur du plan terminé.

## Démarrage rapide (développeurs)

```powershell
# Cloner
git clone https://github.com/chipat-neko/opti_route.git
cd opti_route

# Activer les hooks Git versionnés (bloque le push direct vers main)
git config core.hooksPath .githooks

# Vérifier l'environnement Flutter
cd app
flutter doctor

# Installer les dépendances
flutter pub get

# Lancer sur un appareil Android connecté
flutter run
```

> ⚠️ **Important** : le `git config core.hooksPath .githooks` doit être lancé une seule fois après le clone. Il active le hook `pre-push` qui interdit les push directs vers `main` (cf. convention plus haut). Le hook est versionné dans `.githooks/` pour rester partagé.

## Licence

Privé — non distribué publiquement à ce stade.
