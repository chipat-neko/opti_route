# Migrations Supabase — schéma cloud opti_route

Ce dossier reconstitue le **schéma cloud Postgres** de façon **rejouable**
sur un projet Supabase vierge (`supabase db reset` ou nouveau projet), à
partir des scripts SQL qui ont été historiquement appliqués **à la main**
dans le SQL Editor du Dashboard.

## Ordre d'application (déterminant)

| # | Migration | Contenu | Source |
|---|---|---|---|
| 1 | `20260525000000_base_schema.sql` | 4 tables miroir Drift (tournées, stops, coéquipiers, saved_destinations) + RLS (sous-jalon 2.A) | `docs/supabase-schema.sql` |
| 2 | `20260531000000_multi_tenant.sql` | entreprises / entrepôts / memberships (#362) | `docs/supabase-schema-multi-tenant.sql` |
| 3 | `20260604000000_plans_381a.sql` | catalogue plans + colonne `plan` sur entreprises (#381-A) | `docs/supabase-schema-plans-381a.sql` |
| 4 | `20260813000000_cron_lockout_revoked.sql` | job pg_cron quotidien qui appelle l'Edge Function `cron_lockout_revoked` (expiration J+30 des accès révoqués, #363) | **reconstituée** depuis l'en-tête de `supabase/functions/cron_lockout_revoked/index.ts` (F31) |

L'ordre est **imposé** : le script 3 référence `public.entreprises` et
`is_super_admin()` créés par le script 2 (indiqué en tête de
`plans-381a.sql`). Les préfixes de timestamp encodent cet ordre logique
(la date de `base_schema` est approximative — le fichier source n'en
portait pas ; les scripts 2 et 3 reprennent la date de leur en-tête, le
script 4 celle de sa création).
Le script 4 ne référence aucune table (dépendance seulement logique :
l'Edge Function qu'il planifie écrit dans les tables du script 2).

## Sûreté

Les scripts sont **idempotents** : `CREATE ... IF NOT EXISTS`,
`CREATE OR REPLACE`, `ALTER ... ADD COLUMN IF NOT EXISTS`, `ON CONFLICT`,
`DROP POLICY IF EXISTS`, et pour le job cron un `cron.unschedule`
tolérant à l'absence. Ils peuvent donc être rejoués sans casser une
base existante.

## ⚠️ Base de production — à valider avant tout push

- La base Supabase de **prod est déjà à cet état** (scripts appliqués
  manuellement). Ces migrations servent surtout à **recréer un
  environnement vierge** (dev / staging) à l'identique.
- **La chaîne complète n'a PAS pu être rejouée/validée ici** (cette
  machine n'a pas la CLI Supabase). Avant de faire confiance à un
  `supabase db push` / `supabase db reset` : **jouer les migrations sur
  une base vierge** et vérifier qu'elles passent dans l'ordre, sans
  conflit résiduel entre les 3 fichiers historiques.
- **Migration 4 (job cron) — définition reconstituée.** Le job a été créé
  à la main dans le Dashboard ; son nom réel n'est pas connu ici. Avant
  de rejouer ce script sur la prod : `select jobid, jobname, schedule,
  command from cron.job;` puis aligner le fichier. Si le job existant
  porte un autre `jobname`, le script en créerait un **second** (double
  exécution quotidienne). Détails et TODO en tête du fichier.
- **Secrets du job cron** : la commande planifiée lit `project_url` et
  `cron_secret` dans **Supabase Vault** au moment de l'exécution — rien
  n'est en clair dans le SQL. Les deux secrets sont à créer une fois par
  projet (`vault.create_secret(...)`, cf section 1 du fichier) ;
  `cron_secret` doit valoir exactement le `CRON_SECRET` déclaré dans
  Dashboard > Edge Functions > Secrets.
- Les fichiers `docs/*.sql` restent la **source historique de référence**
  (non supprimés).
