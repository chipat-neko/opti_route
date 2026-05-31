-- ═════════════════════════════════════════════════════════════════
-- Supabase schema : Multi-tenant entreprise + entrepôt + employé
-- Carte Trello #362 (épopée #361)
-- Date : 2026-05-31
-- ═════════════════════════════════════════════════════════════════
--
-- À déployer sur le projet Supabase de Noah via :
--   `supabase db push` (si CLI)
--   OU copier-coller dans Dashboard Supabase > SQL Editor
--
-- ⚠️ Idempotent : peut être rejoué sans casser une install existante
--    (CREATE IF NOT EXISTS, ALTER ADD IF NOT EXISTS, etc.)

-- ─────────────────────────────────────────────────────────────────
-- 1. TABLES
-- ─────────────────────────────────────────────────────────────────

-- Entreprise = compte parent (CALOTE Noah, MESEXP, ...)
create table if not exists public.entreprises (
  cloud_id    uuid primary key default gen_random_uuid(),
  nom         text not null check (length(nom) between 1 and 200),
  siret       text check (siret is null or length(siret) = 14),
  created_by  uuid not null references auth.users(id) on delete restrict,
  cree_le     timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Entrepôt = site/agence rattaché à 1 entreprise
create table if not exists public.entrepots (
  cloud_id       uuid primary key default gen_random_uuid(),
  entreprise_id  uuid not null references public.entreprises(cloud_id) on delete cascade,
  nom            text not null check (length(nom) between 1 and 200),
  adresse        text,
  lat            double precision,
  lng            double precision,
  cree_le        timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Membres entreprise (rôle global : admin_entreprise ou membre)
create table if not exists public.entreprise_users (
  cloud_id       uuid primary key default gen_random_uuid(),
  entreprise_id  uuid not null references public.entreprises(cloud_id) on delete cascade,
  user_id        uuid not null references auth.users(id) on delete cascade,
  role           text not null check (role in ('admin_entreprise', 'membre')),
  statut         text not null default 'actif' check (statut in ('actif', 'revoque', 'expire')),
  revoked_at     timestamptz,
  cree_le        timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (entreprise_id, user_id)
);

-- Membres entrepôt (M:N user × entrepôt, multi-entrepôts possible)
create table if not exists public.entrepot_users (
  cloud_id     uuid primary key default gen_random_uuid(),
  entrepot_id  uuid not null references public.entrepots(cloud_id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         text not null check (role in ('chef_entrepot', 'employe')),
  statut       text not null default 'actif' check (statut in ('actif', 'revoque', 'expire')),
  revoked_at   timestamptz,
  cree_le      timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (entrepot_id, user_id)
);

-- Invitations en attente (magic link Supabase Auth)
create table if not exists public.entreprise_invitations (
  cloud_id       uuid primary key default gen_random_uuid(),
  entreprise_id  uuid not null references public.entreprises(cloud_id) on delete cascade,
  entrepot_id    uuid references public.entrepots(cloud_id) on delete set null,
  email          text not null check (email like '%_@_%'),
  role_target    text not null check (role_target in ('admin_entreprise', 'chef_entrepot', 'employe')),
  invited_by     uuid not null references auth.users(id) on delete cascade,
  statut         text not null default 'pending' check (statut in ('pending', 'accepted', 'expired', 'revoked')),
  expires_at     timestamptz not null default (now() + interval '7 days'),
  cree_le        timestamptz not null default now()
);

-- Notes perso d'un employé sur un client partagé (RLS strict user_id = auth.uid)
create table if not exists public.saved_destination_notes_perso (
  cloud_id              uuid primary key default gen_random_uuid(),
  saved_destination_id  uuid not null,
  user_id               uuid not null references auth.users(id) on delete cascade,
  notes                 text,
  cree_le               timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  unique (saved_destination_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────
-- 2. EXTENSION saved_destinations (lien carnet partagé)
-- ─────────────────────────────────────────────────────────────────
-- ALTER avec garde : si la colonne existe déjà, no-op
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='saved_destinations'
    and column_name='entreprise_id'
  ) then
    alter table public.saved_destinations
      add column entreprise_id uuid references public.entreprises(cloud_id) on delete set null;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='saved_destinations'
    and column_name='entrepot_id'
  ) then
    alter table public.saved_destinations
      add column entrepot_id uuid references public.entrepots(cloud_id) on delete set null;
  end if;
end $$;

-- ─────────────────────────────────────────────────────────────────
-- 3. INDEXES (perf RLS et lookups fréquents)
-- ─────────────────────────────────────────────────────────────────
create index if not exists idx_entreprise_users_user
  on public.entreprise_users(user_id) where statut = 'actif';
create index if not exists idx_entrepot_users_user
  on public.entrepot_users(user_id) where statut = 'actif';
create index if not exists idx_entrepot_users_entrepot
  on public.entrepot_users(entrepot_id);
create index if not exists idx_entrepots_entreprise
  on public.entrepots(entreprise_id);
create index if not exists idx_invitations_email
  on public.entreprise_invitations(email) where statut = 'pending';
create index if not exists idx_sd_entreprise
  on public.saved_destinations(entreprise_id) where entreprise_id is not null;
create index if not exists idx_sd_entrepot
  on public.saved_destinations(entrepot_id) where entrepot_id is not null;
create index if not exists idx_notes_perso_user
  on public.saved_destination_notes_perso(user_id, saved_destination_id);

-- ─────────────────────────────────────────────────────────────────
-- 4. TRIGGERS updated_at (pattern uniforme avec les autres tables)
-- ─────────────────────────────────────────────────────────────────
create or replace function public._set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

do $$
declare t text;
begin
  for t in select unnest(array[
    'entreprises','entrepots','entreprise_users','entrepot_users',
    'saved_destination_notes_perso'
  ])
  loop
    execute format($f$
      drop trigger if exists set_updated_at on public.%I;
      create trigger set_updated_at before update on public.%I
        for each row execute function public._set_updated_at();
    $f$, t, t);
  end loop;
end $$;

-- ─────────────────────────────────────────────────────────────────
-- 5. FONCTIONS HELPERS RLS
-- ─────────────────────────────────────────────────────────────────

-- Renvoie les entreprise_id auxquelles le user courant a accès actif
create or replace function public.current_user_entreprise_ids()
returns setof uuid language sql security definer stable as $$
  select entreprise_id from public.entreprise_users
  where user_id = auth.uid() and statut = 'actif'
$$;

-- Renvoie les entrepot_id auxquels le user courant a accès actif
create or replace function public.current_user_entrepot_ids()
returns setof uuid language sql security definer stable as $$
  select entrepot_id from public.entrepot_users
  where user_id = auth.uid() and statut = 'actif'
$$;

-- True si user est admin_entreprise de l'entreprise donnée
create or replace function public.is_admin_entreprise(p_entreprise_id uuid)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from public.entreprise_users
    where entreprise_id = p_entreprise_id
      and user_id = auth.uid()
      and role = 'admin_entreprise'
      and statut = 'actif'
  )
$$;

-- True si user est chef de l'entrepot donné
create or replace function public.is_chef_entrepot(p_entrepot_id uuid)
returns boolean language sql security definer stable as $$
  select exists (
    select 1 from public.entrepot_users
    where entrepot_id = p_entrepot_id
      and user_id = auth.uid()
      and role = 'chef_entrepot'
      and statut = 'actif'
  )
$$;

-- ─────────────────────────────────────────────────────────────────
-- 6. RLS (Row Level Security) — strict multi-tenant
-- ─────────────────────────────────────────────────────────────────

alter table public.entreprises enable row level security;
alter table public.entrepots enable row level security;
alter table public.entreprise_users enable row level security;
alter table public.entrepot_users enable row level security;
alter table public.entreprise_invitations enable row level security;
alter table public.saved_destination_notes_perso enable row level security;

-- entreprises : SELECT si user dans entreprise_users actif OU créateur
drop policy if exists sel_entreprises on public.entreprises;
create policy sel_entreprises on public.entreprises
  for select using (
    cloud_id in (select public.current_user_entreprise_ids())
    or created_by = auth.uid()
  );
drop policy if exists ins_entreprises on public.entreprises;
create policy ins_entreprises on public.entreprises
  for insert with check (created_by = auth.uid());
drop policy if exists upd_entreprises on public.entreprises;
create policy upd_entreprises on public.entreprises
  for update using (public.is_admin_entreprise(cloud_id));
drop policy if exists del_entreprises on public.entreprises;
create policy del_entreprises on public.entreprises
  for delete using (public.is_admin_entreprise(cloud_id));

-- entrepots : SELECT si user dans entrepot_users OU admin entreprise parente
drop policy if exists sel_entrepots on public.entrepots;
create policy sel_entrepots on public.entrepots
  for select using (
    cloud_id in (select public.current_user_entrepot_ids())
    or public.is_admin_entreprise(entreprise_id)
  );
drop policy if exists ins_entrepots on public.entrepots;
create policy ins_entrepots on public.entrepots
  for insert with check (
    public.is_admin_entreprise(entreprise_id)
    -- ou chef entrepot peut créer un nouvel entrepot dans son entreprise (Q4).
    -- Note : on join entrepots pour récupérer entreprise_id (entrepot_users
    -- n'a que entrepot_id, donc l'alias est `e.entreprise_id` pas `eu.entreprise_id`).
    or entreprise_id in (
      select e.entreprise_id from public.entrepot_users eu
      join public.entrepots e on e.cloud_id = eu.entrepot_id
      where eu.user_id = auth.uid() and eu.role = 'chef_entrepot' and eu.statut = 'actif'
    )
  );
drop policy if exists upd_entrepots on public.entrepots;
create policy upd_entrepots on public.entrepots
  for update using (
    public.is_admin_entreprise(entreprise_id)
    or public.is_chef_entrepot(cloud_id)
  );
drop policy if exists del_entrepots on public.entrepots;
create policy del_entrepots on public.entrepots
  for delete using (public.is_admin_entreprise(entreprise_id));

-- entreprise_users : SELECT pour les membres de l'entreprise + l'user concerné
drop policy if exists sel_eu on public.entreprise_users;
create policy sel_eu on public.entreprise_users
  for select using (
    user_id = auth.uid()
    or entreprise_id in (select public.current_user_entreprise_ids())
  );
drop policy if exists ins_eu on public.entreprise_users;
create policy ins_eu on public.entreprise_users
  for insert with check (public.is_admin_entreprise(entreprise_id));
drop policy if exists upd_eu on public.entreprise_users;
create policy upd_eu on public.entreprise_users
  for update using (public.is_admin_entreprise(entreprise_id));
drop policy if exists del_eu on public.entreprise_users;
create policy del_eu on public.entreprise_users
  for delete using (public.is_admin_entreprise(entreprise_id));

-- entrepot_users : SELECT pour membres de l'entrepôt + admin entreprise
drop policy if exists sel_eu2 on public.entrepot_users;
create policy sel_eu2 on public.entrepot_users
  for select using (
    user_id = auth.uid()
    or entrepot_id in (select public.current_user_entrepot_ids())
    or exists (
      select 1 from public.entrepots e
      where e.cloud_id = entrepot_id
        and public.is_admin_entreprise(e.entreprise_id)
    )
  );
drop policy if exists ins_eu2 on public.entrepot_users;
create policy ins_eu2 on public.entrepot_users
  for insert with check (
    public.is_chef_entrepot(entrepot_id)
    or exists (
      select 1 from public.entrepots e
      where e.cloud_id = entrepot_id
        and public.is_admin_entreprise(e.entreprise_id)
    )
  );
drop policy if exists upd_eu2 on public.entrepot_users;
create policy upd_eu2 on public.entrepot_users
  for update using (
    public.is_chef_entrepot(entrepot_id)
    or exists (
      select 1 from public.entrepots e
      where e.cloud_id = entrepot_id
        and public.is_admin_entreprise(e.entreprise_id)
    )
  );
drop policy if exists del_eu2 on public.entrepot_users;
create policy del_eu2 on public.entrepot_users
  for delete using (
    public.is_chef_entrepot(entrepot_id)
    or exists (
      select 1 from public.entrepots e
      where e.cloud_id = entrepot_id
        and public.is_admin_entreprise(e.entreprise_id)
    )
  );

-- entreprise_invitations : SELECT/INSERT pour chef ou admin entreprise
drop policy if exists sel_inv on public.entreprise_invitations;
create policy sel_inv on public.entreprise_invitations
  for select using (
    invited_by = auth.uid()
    or entreprise_id in (select public.current_user_entreprise_ids())
  );
drop policy if exists ins_inv on public.entreprise_invitations;
create policy ins_inv on public.entreprise_invitations
  for insert with check (
    invited_by = auth.uid()
    and (
      public.is_admin_entreprise(entreprise_id)
      or (entrepot_id is not null and public.is_chef_entrepot(entrepot_id))
    )
  );
drop policy if exists del_inv on public.entreprise_invitations;
create policy del_inv on public.entreprise_invitations
  for delete using (
    invited_by = auth.uid()
    or public.is_admin_entreprise(entreprise_id)
  );

-- saved_destination_notes_perso : strict user_id = auth.uid()
drop policy if exists sel_np on public.saved_destination_notes_perso;
create policy sel_np on public.saved_destination_notes_perso
  for select using (user_id = auth.uid());
drop policy if exists ins_np on public.saved_destination_notes_perso;
create policy ins_np on public.saved_destination_notes_perso
  for insert with check (user_id = auth.uid());
drop policy if exists upd_np on public.saved_destination_notes_perso;
create policy upd_np on public.saved_destination_notes_perso
  for update using (user_id = auth.uid());
drop policy if exists del_np on public.saved_destination_notes_perso;
create policy del_np on public.saved_destination_notes_perso
  for delete using (user_id = auth.uid());

-- saved_destinations : étendre les policies existantes pour le carnet partagé
-- (à vérifier selon les policies actuelles ; les ajouter sans casser le local
-- = adresses perso restent visibles par leur owner, plus carnet entreprise/entrepôt)
do $$
begin
  -- Drop l'ancienne policy SELECT si elle existe (sera remplacée par version étendue)
  if exists (select 1 from pg_policies where schemaname='public' and tablename='saved_destinations' and policyname='sd_select_extended_multi_tenant') then
    drop policy sd_select_extended_multi_tenant on public.saved_destinations;
  end if;
end $$;
-- Ajouter une policy permissive supplémentaire qui s'ajoute aux existantes
create policy sd_select_extended_multi_tenant on public.saved_destinations
  for select using (
    (entreprise_id is not null and entreprise_id in (select public.current_user_entreprise_ids()))
    or
    (entrepot_id is not null and entrepot_id in (select public.current_user_entrepot_ids()))
  );

-- ═════════════════════════════════════════════════════════════════
-- FIN
-- À déployer puis tester :
--   1. Insert entreprise via app (auth user A)
--   2. Vérifier que user B (auth différent) ne voit pas l'entreprise A
--   3. Inviter user B → user B doit voir l'entreprise après acceptation
-- ═════════════════════════════════════════════════════════════════
