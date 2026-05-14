# opti_route

Application mobile d'optimisation de tournées pour livreur multi-points.

## État du projet

🚧 **En développement actif** — Phase 1 (version gratuite, Android uniquement). Voir [docs/plan_free.md](docs/plan_free.md) pour le plan détaillé et [docs/user-guide.md](docs/user-guide.md) pour le guide utilisateur.

**~144 tests unitaires**, `flutter analyze` à 0 erreur, prêt pour publication Play Store côté technique (manque keystore + 25 USD compte Google).

## Objectif

Aider un chauffeur-livreur à organiser sa tournée quotidienne :
- Saisie d'adresses **manuelle, par OCR caméra, ou hors-ligne** (geocodage différé).
- Cascade géocodage **BAN + SIRENE + Photon** (3 sources gratuites France).
- Définition de **contraintes par client** : priorité (premier/dernier), nombre de colis, fenêtres horaires, notes, capacité véhicule, profil VL/HGV.
- **Optimisation automatique** de l'ordre de passage via VROOM/ORS, avec gestion HGV + capacité + évitement péages.
- **Mode tournée en cours** : GPS live, distance jusqu'au prochain arrêt, lancement Maps/Waze, validation Livré/Échec avec preuve GPS + journal.
- **Rappels locaux** programmables par tournée (notifs Android).
- **Carnet d'adresses** auto-rempli, notes pré-définies par client, export CSV ou vCard, filtre par couleur.
- **Statistiques** 7j/30j/1 an : tournées, arrêts, colis, distance, **coût carburant estimé**, jours les plus chargés, top 5 clients.
- **Partage** en texte court (WhatsApp/SMS) ou PDF récap.
- **Mode sombre** complet (conduite de nuit).
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
