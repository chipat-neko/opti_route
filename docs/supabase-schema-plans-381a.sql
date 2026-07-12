-- ARCHIVE : source canonique = supabase/migrations/. Ne plus editer ici (cf #510).
-- ═════════════════════════════════════════════════════════════════
-- Supabase schema : Plans / abonnements — ÉTAPE A (fondation neutre)
-- Carte Trello #388 ([381-A], épopée #381)
-- Date : 2026-06-04
-- ═════════════════════════════════════════════════════════════════
--
-- Objectif : poser les RAILS des plans SANS rien brider.
--   1. catalogue des plans (free / tier1 / tier2 / tier3 + illimite)
--   2. colonne `plan` sur entreprises, défaut 'illimite' (grandfathering)
--   3. RPC lecture seule get_entreprise_plan()
--
-- ⚠️ AUCUNE limite n'est appliquée ici (le bridage = #381-C / carte #390).
--    Tout le monde reste 'illimite' -> 100 % réversible, ne casse aucune
--    install existante (toi + ton employeur gardent l'accès total).
--
-- ⚠️ Idempotent : rejouable sans casser (CREATE IF NOT EXISTS,
--    ON CONFLICT, ADD COLUMN IF NOT EXISTS).
-- À déployer : Dashboard Supabase > SQL Editor (copier-coller) ou
--    `supabase db push`. À jouer APRÈS supabase-schema-multi-tenant.sql
--    (dépend de la table public.entreprises + de is_super_admin()).

-- ─────────────────────────────────────────────────────────────────
-- 1. TABLE catalogue des plans
--    NULL sur max_entrepots / max_membres = ILLIMITÉ (pas de limite).
-- ─────────────────────────────────────────────────────────────────
create table if not exists public.plans (
  code                   text primary key,          -- 'free' | 'tier1' | ...
  nom                    text not null,             -- libellé affiché
  badge                  text not null,             -- ex 'Free', 'Tier 1'
  max_entrepots          int,                       -- null = illimité
  max_membres            int,                       -- null = illimité
  peut_creer_entreprise  boolean not null default false,
  ordre                  int not null default 0,    -- tri d'affichage
  cree_le                timestamptz not null default now()
);

-- ─────────────────────────────────────────────────────────────────
-- 2. SEED des plans (rejouable : ON CONFLICT met à jour les libellés)
--    Reprend les 4 paliers décrits par Noah dans la carte #381 :
--      free  : solo uniquement
--      tier1 : 1 entrepôt sans créer d'entreprise, équipe max 5
--      tier2 : crée une entreprise, max 2 entrepôts
--      tier3 : entreprise, entrepôts illimités
--    + 'illimite' : palier interne de grandfathering (comptes existants).
-- ─────────────────────────────────────────────────────────────────
insert into public.plans
  (code, nom, badge, max_entrepots, max_membres, peut_creer_entreprise, ordre)
values
  ('free',     'Solo',              'Free',     0,    1,    false, 0),
  ('tier1',    'Petite équipe',     'Tier 1',   1,    5,    false, 1),
  ('tier2',    'Petite entreprise', 'Tier 2',   2,    null, true,  2),
  ('tier3',    'Grande entreprise', 'Tier 3',   null, null, true,  3),
  ('illimite', 'Illimité',          'Illimité', null, null, true,  99)
on conflict (code) do update set
  nom                   = excluded.nom,
  badge                 = excluded.badge,
  max_entrepots         = excluded.max_entrepots,
  max_membres           = excluded.max_membres,
  peut_creer_entreprise = excluded.peut_creer_entreprise,
  ordre                 = excluded.ordre;

-- ─────────────────────────────────────────────────────────────────
-- 3. COLONNE plan sur entreprises (défaut 'illimite' = grandfathering)
--    Les plans (étape 2) DOIVENT être seedés avant cet ALTER : la FK
--    exige que 'illimite' existe déjà dans public.plans.
-- ─────────────────────────────────────────────────────────────────
alter table public.entreprises
  add column if not exists plan text not null default 'illimite'
  references public.plans(code) on update cascade;

-- Sécurise les lignes pré-existantes si la colonne avait été ajoutée
-- autrement (sans default). Sur Postgres le default est appliqué aux
-- lignes existantes lors de l'ADD COLUMN, mais on reste idempotent.
update public.entreprises set plan = 'illimite' where plan is null;

-- ─────────────────────────────────────────────────────────────────
-- 4. RPC lecture seule : get_entreprise_plan(entreprise_id)
--    Renvoie la ligne de plan de l'entreprise. Lecture seule, aucun
--    effet de bord (le bridage viendra en #381-C).
-- ─────────────────────────────────────────────────────────────────
create or replace function public.get_entreprise_plan(p_entreprise_id uuid)
returns public.plans language sql security definer set search_path = public as $$
  select p.*
  from public.plans p
  join public.entreprises e on e.plan = p.code
  where e.cloud_id = p_entreprise_id;
$$;
grant execute on function public.get_entreprise_plan(uuid) to authenticated;

-- ─────────────────────────────────────────────────────────────────
-- 5. RLS : le catalogue des plans est lisible par tous (authenticated),
--    modifiable uniquement par le super admin (is_super_admin existe
--    déjà dans supabase-schema-multi-tenant.sql).
-- ─────────────────────────────────────────────────────────────────
alter table public.plans enable row level security;

drop policy if exists sel_plans on public.plans;
create policy sel_plans on public.plans
  for select to authenticated using (true);

drop policy if exists write_plans on public.plans;
create policy write_plans on public.plans
  for all to authenticated
  using (public.is_super_admin())
  with check (public.is_super_admin());

-- ═════════════════════════════════════════════════════════════════
-- FIN #381-A. Vérif rapide après déploiement :
--   select * from public.plans order by ordre;
--   select cloud_id, nom, plan from public.entreprises;  -- tout 'illimite'
--   select * from public.get_entreprise_plan('<un cloud_id>');
-- ═════════════════════════════════════════════════════════════════
