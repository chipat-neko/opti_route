# Migrations Supabase — schéma cloud opti_route

Ce dossier reconstitue le **schéma cloud Postgres** de façon **rejouable**
sur un projet Supabase vierge (`supabase db reset` ou nouveau projet), à
partir des 3 scripts SQL qui ont été historiquement appliqués **à la main**
dans le SQL Editor du Dashboard.

## Ordre d'application (déterminant)

| # | Migration | Contenu | Source |
|---|---|---|---|
| 1 | `20260525000000_base_schema.sql` | 4 tables miroir Drift (tournées, stops, coéquipiers, saved_destinations) + RLS (sous-jalon 2.A) | `docs/supabase-schema.sql` |
| 2 | `20260531000000_multi_tenant.sql` | entreprises / entrepôts / memberships (#362) | `docs/supabase-schema-multi-tenant.sql` |
| 3 | `20260604000000_plans_381a.sql` | catalogue plans + colonne `plan` sur entreprises (#381-A) | `docs/supabase-schema-plans-381a.sql` |

L'ordre est **imposé** : le script 3 référence `public.entreprises` et
`is_super_admin()` créés par le script 2 (indiqué en tête de
`plans-381a.sql`). Les préfixes de timestamp encodent cet ordre logique
(la date de `base_schema` est approximative — le fichier source n'en
portait pas ; les deux autres reprennent la date de leur en-tête).

## Sûreté

Les 3 scripts sont **idempotents** : `CREATE ... IF NOT EXISTS`,
`CREATE OR REPLACE`, `ALTER ... ADD COLUMN IF NOT EXISTS`, `ON CONFLICT`,
`DROP POLICY IF EXISTS`. Ils peuvent donc être rejoués sans casser une
base existante.

## ⚠️ Base de production — à valider avant tout push

- La base Supabase de **prod est déjà à cet état** (scripts appliqués
  manuellement). Ces migrations servent surtout à **recréer un
  environnement vierge** (dev / staging) à l'identique.
- **La chaîne complète n'a PAS pu être rejouée/validée ici** (cette
  machine n'a pas la CLI Supabase). Avant de faire confiance à un
  `supabase db push` / `supabase db reset` : **jouer les 3 migrations sur
  une base vierge** et vérifier qu'elles passent dans l'ordre, sans
  conflit résiduel entre les 3 fichiers historiques.
- Les fichiers `docs/*.sql` restent la **source historique de référence**
  (non supprimés).
