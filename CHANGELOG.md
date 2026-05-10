# Changelog

Toutes les modifications notables du projet sont consignées dans ce fichier.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Non publié]

### Ajouté
- Plan détaillé Phase 1 version gratuite (`docs/plan_free.md`).
- Plan détaillé version CB avec Google Maps Platform (`docs/plan_cb.md`).
- Script de génération PDF pour les documents Markdown (`docs/_build_pdf.py`).
- Squelette du projet Flutter dans `app/` (cible Android, organisation `com.optiroute`).
- Convention Git du projet (branches, commits, PRs) documentée dans le README.
- Hook `pre-push` versionné (`.githooks/pre-push`) qui bloque les push directs vers `main` ; activation via `git config core.hooksPath .githooks` après clone.
- Schéma de base de données SQLite via `drift` (`app/lib/data/database.dart`) : tables `tournees`, `stops` (avec FK et cascade delete), `parametres` (clé primaire texte). PRAGMA `foreign_keys=ON` activé via la migration strategy. Code drift généré commité dans `database.g.dart`.
- Suite de tests pour la base (`app/test/database_test.dart`) couvrant insertion + valeurs par défaut, cascade delete, upsert sur paramètres.
- Première UI métier : `TourneesListScreen` (liste accueil avec empty state, swipe-to-delete et confirmation, FAB *Nouvelle tournée*) et `TourneeFormScreen` (création / édition avec validation des champs et DatePicker localisé `fr_FR`).
- Couche `TourneesRepository` qui abstrait les opérations CRUD au-dessus de drift et expose un `Stream<List<Tournee>>` pour la réactivité automatique.
- Providers Riverpod (`appDatabaseProvider`, `tourneesRepositoryProvider`, `tourneesStreamProvider`) et `ProviderScope` à la racine.
- `main.dart` réécrit : ne montre plus le compteur Flutter mais ouvre directement la liste de tournées. Configuration des locales `fr_FR` (intl + flutter_localizations).

### Modifié
- `pubspec.yaml` : ajout de `flutter_riverpod ^3.3.1`, `intl ^0.20.2`, `flutter_localizations` (SDK).

### Documentation
- Import du handoff Claude Design dans `docs/design/handoff/` : 6 écrans cibles haute fidélité (carte, liste, navigation, ajout, optimisation, détail livraison), tokens (palette cream/ink/lime/emerald, Manrope + JetBrains Mono), modèle de données suggéré (avec concept `Sheet` pour gérer les feuilles d'expéditeurs multiples par arrêt). Référence pour toute la suite des écrans à implémenter.
