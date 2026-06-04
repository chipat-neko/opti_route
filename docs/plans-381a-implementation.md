# Plans #381-A — Fondation neutre (plan d'implémentation)

Carte Trello **#388** ([381-A], épopée #381). **Aucun bridage** ici : on pose
les rails, tout le monde reste `illimite`. Le bridage réel = #381-C (#390).

## 1. SQL Supabase (FAIT — prêt à déployer)

Fichier : [`docs/supabase-schema-plans-381a.sql`](supabase-schema-plans-381a.sql)

- Table `public.plans` (catalogue : free / tier1 / tier2 / tier3 / illimite).
  `max_entrepots` et `max_membres` à `NULL` = illimité.
- Colonne `plan` sur `public.entreprises`, **défaut `'illimite'`** → les
  comptes existants (toi + employeur) ne sont jamais bridés (grandfathering).
- RPC `get_entreprise_plan(uuid)` en **lecture seule**.
- RLS : catalogue lisible par tous les `authenticated`, écriture super admin.

**À déployer** par Noah dans Supabase (SQL Editor) **après** le schéma
multi-tenant. Idempotent (rejouable).

## 2. Côté app Flutter (À FAIRE — nécessite codegen + build)

> Ces étapes touchent Drift → `dart run build_runner build` + tests + build.
> À lancer quand on passe de la *préparation* à l'*implémentation*.

### 2.1 Modèle `Plan` (Dart pur, pas de codegen)
`lib/data/models/plan.dart` :
```dart
class Plan {
  final String code;          // 'free' | 'tier1' | ...
  final String nom;
  final String badge;         // 'Free', 'Tier 1', ...
  final int? maxEntrepots;    // null = illimité
  final int? maxMembres;      // null = illimité
  final bool peutCreerEntreprise;
  const Plan({...});
  bool get entrepotsIllimites => maxEntrepots == null;
  bool get membresIllimites => maxMembres == null;
}
```

### 2.2 Drift : colonne `plan` sur la table `entreprises` locale
- Ajouter `TextColumn get plan => text().withDefault(const Constant('illimite'))();`
  dans la table Drift `Entreprises`.
- Migration `onUpgrade` : `if (from < 51)` → `_safeAddColumn(...)` **+ backfill**
  `UPDATE entreprises SET plan='illimite'` (cf piège Drift web : le default
  constant n'est pas appliqué aux lignes existantes).
- Bump `schemaVersion` 50 → 51 + mettre à jour les 2 tests de verrou
  (`database_schema_test.dart`, `entreprise_repository_test.dart`).
- `dart run build_runner build --delete-conflicting-outputs`.

### 2.3 Sync cloud
- `cloud_sync_service` : pousser/puller `plan` sur entreprises (comme
  les autres colonnes). Lecture seule côté app pour l'instant.

### 2.4 Provider + badge (lecture seule, 0 bridage)
- `planForEntrepriseProvider(entrepriseId)` : lit le plan (local d'abord,
  RPC `get_entreprise_plan` en secours).
- Petit widget `PlanBadge` (réutilise le style des badges existants) affiché
  sur l'écran « Mon entreprise ». **Purement informatif.**

### 2.5 Tests
- Round-trip colonne `plan` (défaut illimite, persistance).
- Mapping `Plan` depuis une row.
- **Aucun test de limite** (le bridage est #381-C).

## 3. Ce que #381-A ne fait PAS (volontaire)
- Pas de limite appliquée (création entrepôt/membre reste libre) → #381-C.
- Pas de codes promo → #381-B (#389).
- Pas d'UI « Passer premium » → #381-D (#391).
- Pas de paiement → #381-E (#392).
