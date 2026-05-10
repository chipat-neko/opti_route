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
