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

-- True si user est chef_entrepot d'AU MOINS UN entrepot de l'entreprise
-- donnée. SECURITY DEFINER + search_path : indispensable car appelée
-- depuis la policy `ins_entrepots` — un sous-SELECT sur `entrepots` dans
-- une policy de `entrepots` provoquerait une recursion RLS (42P17).
create or replace function public.is_chef_of_entreprise(p_entreprise_id uuid)
returns boolean language sql security definer stable
set search_path = public as $$
  select exists (
    select 1 from public.entrepot_users eu
    join public.entrepots e on e.cloud_id = eu.entrepot_id
    where eu.user_id = auth.uid()
      and eu.role = 'chef_entrepot'
      and eu.statut = 'actif'
      and e.entreprise_id = p_entreprise_id
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
    -- ⚠️ On passe par une fonction SECURITY DEFINER : un sous-SELECT direct
    -- sur `entrepots` DANS une policy de `entrepots` declenche une recursion
    -- RLS (Postgres 42P17 "infinite recursion detected in policy"). La
    -- fonction (definer + search_path) bypasse la RLS et casse la boucle.
    -- Cf bug terrain 2026-05-31 (creation entrepot KO).
    or public.is_chef_of_entreprise(entreprise_id)
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

-- ─────────────────────────────────────────────────────────────────
-- 7. TRIGGER bootstrap : créateur entreprise → admin_entreprise
-- ─────────────────────────────────────────────────────────────────
-- Sans ce trigger, le créateur insère bien la ligne `entreprises`
-- (policy ins_entreprises : created_by = auth.uid()) mais ne peut PAS
-- s'auto-ajouter dans `entreprise_users` : la policy ins_eu exige
-- is_admin_entreprise()... qu'il n'est pas encore (deadlock œuf/poule).
-- SECURITY DEFINER : la fonction s'exécute avec les droits de son
-- propriétaire (bypass RLS) et crée l'admin initial juste après l'INSERT.
-- `set search_path = public` : durcissement standard des fonctions
-- SECURITY DEFINER (évite le détournement via search_path).
-- Idempotent (on conflict do nothing) : rejouable sans créer de doublon.
create or replace function public.handle_new_entreprise()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  insert into public.entreprise_users (entreprise_id, user_id, role, statut)
  values (new.cloud_id, new.created_by, 'admin_entreprise', 'actif')
  on conflict (entreprise_id, user_id) do nothing;
  return new;
end $$;

drop trigger if exists on_entreprise_created on public.entreprises;
create trigger on_entreprise_created
  after insert on public.entreprises
  for each row execute function public.handle_new_entreprise();

-- ─────────────────────────────────────────────────────────────────
-- 8. GESTION EMPLOYÉS (carte #366) : code d'invitation + RPC
-- ─────────────────────────────────────────────────────────────────

-- Invitation par CODE (alternative au mail magic link, décision #372 :
-- code OU mail au choix du chef). NULL = invitation par mail ;
-- non-null = code à 6 chiffres que l'employé saisit au 1er démarrage.
alter table public.entreprise_invitations
  add column if not exists code text;

-- Une invitation par code n'a pas d'email -> rendre email nullable.
-- Le check `email like '%_@_%'` reste vrai pour NULL (un check ne
-- bloque que s'il vaut FALSE, pas NULL).
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='entreprise_invitations'
      and column_name='email' and is_nullable='NO'
  ) then
    alter table public.entreprise_invitations alter column email drop not null;
  end if;
end $$;

create index if not exists idx_invitations_code
  on public.entreprise_invitations(code)
  where statut = 'pending' and code is not null;

-- Liste des membres d'une entreprise AVEC leur email (auth.users n'est
-- pas lisible en RLS -> SECURITY DEFINER). Garde : le caller doit être
-- membre actif de l'entreprise. Union membres entreprise + membres des
-- entrepôts de cette entreprise.
create or replace function public.list_entreprise_members(p_entreprise_id uuid)
returns table (
  user_id uuid,
  email text,
  role text,
  statut text,
  revoked_at timestamptz,
  entrepot_id uuid,
  entrepot_nom text
) language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from public.entreprise_users eu0
    where eu0.entreprise_id = p_entreprise_id
      and eu0.user_id = auth.uid()
      and eu0.statut = 'actif'
  ) then
    raise exception 'NOT_A_MEMBER';
  end if;

  return query
  select eu.user_id, u.email::text, eu.role, eu.statut, eu.revoked_at,
         null::uuid as entrepot_id, null::text as entrepot_nom
  from public.entreprise_users eu
  join auth.users u on u.id = eu.user_id
  where eu.entreprise_id = p_entreprise_id
  union all
  select epu.user_id, u.email::text, epu.role, epu.statut, epu.revoked_at,
         e.cloud_id as entrepot_id, e.nom as entrepot_nom
  from public.entrepot_users epu
  join public.entrepots e on e.cloud_id = epu.entrepot_id
  join auth.users u on u.id = epu.user_id
  where e.entreprise_id = p_entreprise_id;
end $$;

-- Accepte une invitation par CODE (consommée par l'écran « Qui es-tu ? »
-- #373). SECURITY DEFINER pour créer l'adhésion malgré la RLS. Retourne
-- l'entreprise_id rejointe. Codes d'erreur compatibles invitationErrorToFr.
create or replace function public.accept_entreprise_invitation(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_inv public.entreprise_invitations%rowtype;
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  select * into v_inv from public.entreprise_invitations
  where code = p_code and statut = 'pending'
  limit 1;
  if not found then
    raise exception 'CODE_INTROUVABLE';
  end if;
  if v_inv.expires_at < now() then
    raise exception 'CODE_EXPIRE';
  end if;

  insert into public.entreprise_users (entreprise_id, user_id, role, statut)
  values (
    v_inv.entreprise_id, v_uid,
    case when v_inv.role_target = 'admin_entreprise'
         then 'admin_entreprise' else 'membre' end,
    'actif'
  )
  on conflict (entreprise_id, user_id)
    do update set statut = 'actif', revoked_at = null;

  if v_inv.entrepot_id is not null then
    insert into public.entrepot_users (entrepot_id, user_id, role, statut)
    values (
      v_inv.entrepot_id, v_uid,
      case when v_inv.role_target = 'chef_entrepot'
           then 'chef_entrepot' else 'employe' end,
      'actif'
    )
    on conflict (entrepot_id, user_id)
      do update set statut = 'actif', revoked_at = null;
  end if;

  update public.entreprise_invitations
    set statut = 'accepted' where cloud_id = v_inv.cloud_id;

  return v_inv.entreprise_id;
end $$;

-- ─────────────────────────────────────────────────────────────────
-- 9. RPC création entrepôt (carte #364 / fix RLS récursion 42P17)
-- ─────────────────────────────────────────────────────────────────
-- L'INSERT direct sur `entrepots` via PostgREST evalue les policies RLS
-- (ins + sel pour le RETURNING). Celles-ci appellent is_admin_entreprise
-- / current_user_entreprise_ids qui lisent entreprise_users, dont les
-- propres policies relisent entreprise_users -> Postgres detecte une
-- recursion (42P17) et bloque, MEME pour un admin.
--
-- Solution definitive : creer l'entrepot via une fonction SECURITY
-- DEFINER. Elle s'execute hors RLS (aucune policy evaluee pendant
-- l'insert) -> recursion impossible. Les droits sont verifies
-- explicitement en debut de fonction (admin entreprise OU chef d'un
-- entrepot de cette entreprise, cf decision Q4). Meme pattern que
-- handle_new_entreprise / accept_entreprise_invitation qui fonctionnent.
--
-- Retourne le cloud_id genere. L'app passe son propre UUID (p_cloud_id)
-- pour garder 1 seul ID partout (miroir local Drift), cf CloudEntrepriseSync.
create or replace function public.create_entrepot(
  p_cloud_id uuid,
  p_entreprise_id uuid,
  p_nom text,
  p_adresse text default null,
  p_lat double precision default null,
  p_lng double precision default null
)
returns uuid language plpgsql security definer
set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  -- Droits : admin de l'entreprise OU chef d'un entrepot de l'entreprise.
  if not (
    public.is_admin_entreprise(p_entreprise_id)
    or public.is_chef_of_entreprise(p_entreprise_id)
  ) then
    raise exception 'FORBIDDEN';
  end if;

  insert into public.entrepots (cloud_id, entreprise_id, nom, adresse, lat, lng)
  values (p_cloud_id, p_entreprise_id, p_nom, p_adresse, p_lat, p_lng);

  return p_cloud_id;
end $$;

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 10 — Garde-fou création entreprise (#374) + super admin (#372)
-- ═══════════════════════════════════════════════════════════════════
--
-- Probleme : depuis #364, n'importe quel compte connecte peut creer une
-- entreprise (policy ins_entreprises ouverte) -> pollution base + quota
-- Supabase gratuit grignote.
--
-- Solution (decisions Noah 2026-06-01) :
--  - Creation entreprise = il faut un CODE MAITRE, verifie cote serveur
--    (jamais expose a l'app). Le super admin (Noah) en est dispense.
--  - Super admin = appartenance a la table app_admins (infalsifiable :
--    decompiler l'APK ne revele aucun secret, tout est verifie serveur).
--
-- ⚠️ A FAIRE UNE FOIS PAR NOAH apres deploiement : s'ajouter super admin.
--    Recupere ton UID dans Supabase > Authentication > Users (colonne UID)
--    puis execute (en collant ton UID a la place du texte, garde les ' ') :
--      insert into public.app_admins (user_id)
--        values ('colle-ici-ton-uid') on conflict do nothing;

-- ─── Table de configuration applicative (cle/valeur) ────────────────
-- Stocke le code maitre sous la cle 'entreprise_master_code'. RLS active
-- SANS aucune policy -> aucun acces direct client : lecture/ecriture
-- uniquement via les RPC SECURITY DEFINER ci-dessous.
create table if not exists public.app_config (
  key        text primary key,
  value      text not null,
  updated_at timestamptz not null default now()
);
alter table public.app_config enable row level security;

-- ─── Table des super admins ─────────────────────────────────────────
-- Un user_id present ici = super admin. RLS active sans policy : on ne
-- lit/ecrit QUE via RPC SECURITY DEFINER (ou SQL manuel par Noah).
create table if not exists public.app_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.app_admins enable row level security;

-- ─── is_super_admin() : le compte courant est-il super admin ? ───────
create or replace function public.is_super_admin()
returns boolean language sql security definer set search_path = public as $$
  select exists (select 1 from public.app_admins where user_id = auth.uid());
$$;
grant execute on function public.is_super_admin() to authenticated;

-- ─── _get_or_init_master_code() : interne, genere le code au 1er acces
-- Code maitre = 6 chiffres. S'il n'existe pas encore, on en cree un
-- aleatoire. Interne (pas de grant authenticated : appelable seulement
-- depuis les autres fonctions definer).
create or replace function public._get_or_init_master_code()
returns text language plpgsql security definer set search_path = public as $$
declare
  v_code text;
begin
  select value into v_code from public.app_config
    where key = 'entreprise_master_code';
  if v_code is null then
    v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    insert into public.app_config (key, value)
      values ('entreprise_master_code', v_code);
  end if;
  return v_code;
end;
$$;

-- ─── create_entreprise() : creation bridee par code maitre (#374) ────
-- Remplace l'INSERT direct (policy ins_entreprises fermee ci-dessous).
-- Super admin dispense du code. Le trigger on_entreprise_created (section
-- 7) inscrit ensuite le createur comme admin_entreprise.
create or replace function public.create_entreprise(
  p_cloud_id uuid,
  p_nom text,
  p_siret text default null,
  p_code text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  -- Super admin dispense du code ; sinon le code fourni doit matcher.
  if not public.is_super_admin() then
    if p_code is null or p_code <> public._get_or_init_master_code() then
      raise exception 'INVALID_MASTER_CODE';
    end if;
  end if;
  insert into public.entreprises (cloud_id, nom, siret, created_by)
  values (p_cloud_id, p_nom, p_siret, v_uid);
  return p_cloud_id;
end;
$$;
grant execute on function public.create_entreprise(uuid, text, text, text) to authenticated;

-- Fermer l'INSERT direct sur entreprises : tout passe desormais par la
-- RPC create_entreprise (qui bypasse RLS via SECURITY DEFINER).
drop policy if exists ins_entreprises on public.entreprises;
create policy ins_entreprises on public.entreprises
  for insert with check (false);

-- ─── RPC panel admin (toutes reservees au super admin) ──────────────
-- admin_get_master_code : lit (et init si besoin) le code maitre.
create or replace function public.admin_get_master_code()
returns text language plpgsql security definer set search_path = public as $$
begin
  if not public.is_super_admin() then
    raise exception 'FORBIDDEN';
  end if;
  return public._get_or_init_master_code();
end;
$$;
grant execute on function public.admin_get_master_code() to authenticated;

-- admin_regenerate_master_code : remplace le code par un nouveau aleatoire.
create or replace function public.admin_regenerate_master_code()
returns text language plpgsql security definer set search_path = public as $$
declare
  v_code text;
begin
  if not public.is_super_admin() then
    raise exception 'FORBIDDEN';
  end if;
  v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  insert into public.app_config (key, value, updated_at)
    values ('entreprise_master_code', v_code, now())
    on conflict (key) do update set value = excluded.value, updated_at = now();
  return v_code;
end;
$$;
grant execute on function public.admin_regenerate_master_code() to authenticated;

-- admin_list_entreprises : liste toutes les entreprises (vue super admin).
create or replace function public.admin_list_entreprises()
returns table (
  cloud_id uuid, nom text, siret text, created_by uuid, cree_le timestamptz
) language plpgsql security definer set search_path = public as $$
begin
  if not public.is_super_admin() then
    raise exception 'FORBIDDEN';
  end if;
  return query
    select e.cloud_id, e.nom, e.siret, e.created_by, e.cree_le
    from public.entreprises e
    order by e.cree_le desc;
end;
$$;
grant execute on function public.admin_list_entreprises() to authenticated;

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 11 — Quitter (employé) / Supprimer (admin) une entreprise
-- ═══════════════════════════════════════════════════════════════════
-- Demande Noah 2026-06-01 : il manquait toute sortie d'une entreprise.
-- SECURITY DEFINER pour eviter la recursion RLS (meme raison que
-- create_entrepot). On verifie les droits explicitement dans la fonction.

-- ─── leave_entreprise() : l'utilisateur courant quitte l'entreprise ──
-- Retire son adhesion entreprise + ses adhesions a tous les entrepots de
-- cette entreprise. L'admin/createur NE PEUT PAS quitter (il doit
-- supprimer) -> evite une entreprise orpheline sans admin.
create or replace function public.leave_entreprise(p_entreprise_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_created_by uuid;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  select created_by into v_created_by from public.entreprises
  where cloud_id = p_entreprise_id;
  if v_created_by is null then
    raise exception 'ENTREPRISE_INTROUVABLE';
  end if;
  -- Le createur ne peut pas "quitter" : il supprime ou transfere.
  if v_created_by = v_uid then
    raise exception 'OWNER_CANNOT_LEAVE';
  end if;
  -- Retire les adhesions entrepots de cette entreprise.
  delete from public.entrepot_users eu
  using public.entrepots e
  where eu.entrepot_id = e.cloud_id
    and e.entreprise_id = p_entreprise_id
    and eu.user_id = v_uid;
  -- Retire l'adhesion entreprise.
  delete from public.entreprise_users
  where entreprise_id = p_entreprise_id and user_id = v_uid;
end;
$$;
grant execute on function public.leave_entreprise(uuid) to authenticated;

-- ─── delete_entreprise() : l'admin/createur supprime l'entreprise ────
-- Reserve a l'admin_entreprise (ou super admin). Le ON DELETE CASCADE
-- des FK entrepots/entreprise_users/entreprise_invitations nettoie le
-- reste automatiquement. entrepot_users tombe via cascade entrepots.
create or replace function public.delete_entreprise(p_entreprise_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if not (public.is_admin_entreprise(p_entreprise_id)
          or public.is_super_admin()) then
    raise exception 'FORBIDDEN';
  end if;
  delete from public.entreprises where cloud_id = p_entreprise_id;
end;
$$;
grant execute on function public.delete_entreprise(uuid) to authenticated;

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 12 — Muter un employé (écran "Liste des employés", #361)
-- ═══════════════════════════════════════════════════════════════════
-- Le chef d'entreprise (admin) peut : promouvoir/rétrograder (chef_entrepot
-- <-> employe) ET déplacer un employé d'un entrepôt à un autre.
-- Réservé à l'admin de l'entreprise. SECURITY DEFINER (évite récursion RLS).

-- ─── set_employe_entrepot() : place [p_user_id] dans [p_entrepot_id]
-- avec le rôle [p_role] ('chef_entrepot' | 'employe'). Retire d'abord ses
-- autres adhésions entrepôt DANS la même entreprise (un employé = un seul
-- entrepôt à la fois ici), puis upsert la nouvelle. Garantit aussi qu'il
-- est membre actif de l'entreprise.
create or replace function public.set_employe_entrepot(
  p_entreprise_id uuid,
  p_user_id uuid,
  p_entrepot_id uuid,
  p_role text
) returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if not (public.is_admin_entreprise(p_entreprise_id)
          or public.is_super_admin()) then
    raise exception 'FORBIDDEN';
  end if;
  if p_role not in ('chef_entrepot', 'employe') then
    raise exception 'INVALID_ROLE';
  end if;
  -- L'entrepôt cible doit appartenir à l'entreprise.
  if not exists (
    select 1 from public.entrepots
    where cloud_id = p_entrepot_id and entreprise_id = p_entreprise_id
  ) then
    raise exception 'ENTREPOT_HORS_ENTREPRISE';
  end if;
  -- S'assure que la personne est membre actif de l'entreprise.
  insert into public.entreprise_users (entreprise_id, user_id, role, statut)
  values (p_entreprise_id, p_user_id, 'membre', 'actif')
  on conflict (entreprise_id, user_id)
    do update set statut = 'actif', revoked_at = null;
  -- Retire ses adhésions aux AUTRES entrepôts de cette entreprise.
  delete from public.entrepot_users eu
  using public.entrepots e
  where eu.entrepot_id = e.cloud_id
    and e.entreprise_id = p_entreprise_id
    and eu.user_id = p_user_id
    and eu.entrepot_id <> p_entrepot_id;
  -- Upsert l'adhésion à l'entrepôt cible avec le rôle voulu.
  insert into public.entrepot_users (entrepot_id, user_id, role, statut)
  values (p_entrepot_id, p_user_id, p_role, 'actif')
  on conflict (entrepot_id, user_id)
    do update set role = excluded.role, statut = 'actif', revoked_at = null;
end;
$$;
grant execute on function public.set_employe_entrepot(uuid, uuid, uuid, text) to authenticated;

-- ─── revoke_employe() : révoque un employé de l'entreprise + de tous ses
-- entrepôts (statut='revoque' + revoked_at). Admin only. Le cron J+30
-- (#363) coupe définitivement ensuite.
create or replace function public.revoke_employe(
  p_entreprise_id uuid,
  p_user_id uuid
) returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if not (public.is_admin_entreprise(p_entreprise_id)
          or public.is_super_admin()) then
    raise exception 'FORBIDDEN';
  end if;
  update public.entreprise_users
    set statut = 'revoque', revoked_at = now()
    where entreprise_id = p_entreprise_id and user_id = p_user_id
      and role <> 'admin_entreprise';  -- ne pas se révoquer soi (admin)
  update public.entrepot_users eu
    set statut = 'revoque', revoked_at = now()
    from public.entrepots e
    where eu.entrepot_id = e.cloud_id
      and e.entreprise_id = p_entreprise_id
      and eu.user_id = p_user_id;
end;
$$;
grant execute on function public.revoke_employe(uuid, uuid) to authenticated;

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 13 — Rôle de l'utilisateur courant (entrée de menu adaptée)
-- ═══════════════════════════════════════════════════════════════════
-- Pour afficher dans le menu « Mon entreprise » (chef d'entreprise) ou
-- « Mon entrepôt » (chef d'entrepôt / chauffeur) avec le bon titre.
-- Renvoie 0 ou 1 ligne. role_global = 'admin_entreprise' si l'user est
-- admin d'une entreprise. Sinon role_entrepot = 'chef_entrepot'|'employe'
-- + nom de l'entrepôt principal.
create or replace function public.my_entreprise_role()
returns table (
  entreprise_id   uuid,
  entreprise_nom  text,
  role_global     text,
  entrepot_id     uuid,
  entrepot_nom    text,
  role_entrepot   text
) language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then return; end if;
  -- Priorité 1 : admin d'une entreprise (chef d'entreprise).
  return query
  select e.cloud_id, e.nom, eu.role, null::uuid, null::text, null::text
  from public.entreprise_users eu
  join public.entreprises e on e.cloud_id = eu.entreprise_id
  where eu.user_id = v_uid and eu.statut = 'actif'
    and eu.role = 'admin_entreprise'
  limit 1;
  if found then return; end if;
  -- Priorité 2 : adhésion à un entrepôt (chef_entrepot ou employe).
  return query
  select e.entreprise_id, ent.nom, 'membre'::text,
         e.cloud_id, e.nom, epu.role
  from public.entrepot_users epu
  join public.entrepots e on e.cloud_id = epu.entrepot_id
  join public.entreprises ent on ent.cloud_id = e.entreprise_id
  where epu.user_id = v_uid and epu.statut = 'actif'
  limit 1;
end;
$$;
grant execute on function public.my_entreprise_role() to authenticated;

-- ═══════════════════════════════════════════════════════════════════
-- SECTION 14 — Profil utilisateur (nom affiché) — demande Noah 2026-06-01
-- ═══════════════════════════════════════════════════════════════════
-- Pour afficher un NOM lisible (« Lucas M. ») au lieu de l'email dans la
-- liste des employés. Chacun définit son propre nom.

-- Table profils : 1 ligne par user, son nom d'affichage choisi.
create table if not exists public.user_profiles (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  updated_at   timestamptz not null default now()
);
alter table public.user_profiles enable row level security;

-- RLS : chacun lit/écrit SON profil. La lecture des AUTRES profils passe
-- par la RPC list_entreprise_members (SECURITY DEFINER) qui joint le nom,
-- donc pas besoin d'ouvrir le SELECT à tous.
drop policy if exists sel_own_profile on public.user_profiles;
create policy sel_own_profile on public.user_profiles
  for select using (user_id = auth.uid());
drop policy if exists ins_own_profile on public.user_profiles;
create policy ins_own_profile on public.user_profiles
  for insert with check (user_id = auth.uid());
drop policy if exists upd_own_profile on public.user_profiles;
create policy upd_own_profile on public.user_profiles
  for update using (user_id = auth.uid());

-- set_my_display_name() : upsert le nom du user courant.
create or replace function public.set_my_display_name(p_name text)
returns void language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'AUTH_REQUIRED'; end if;
  insert into public.user_profiles (user_id, display_name, updated_at)
  values (v_uid, nullif(trim(p_name), ''), now())
  on conflict (user_id)
    do update set display_name = nullif(trim(p_name), ''), updated_at = now();
end;
$$;
grant execute on function public.set_my_display_name(text) to authenticated;

-- get_my_display_name() : lit le nom du user courant (null si pas défini).
create or replace function public.get_my_display_name()
returns text language sql security definer set search_path = public as $$
  select display_name from public.user_profiles where user_id = auth.uid();
$$;
grant execute on function public.get_my_display_name() to authenticated;

-- list_entreprise_members : MISE À JOUR pour renvoyer aussi display_name
-- (left join sur user_profiles). Colonne ajoutée en fin pour ne pas
-- casser l'ordre existant côté Dart.
create or replace function public.list_entreprise_members(p_entreprise_id uuid)
returns table (
  user_id uuid,
  email text,
  role text,
  statut text,
  revoked_at timestamptz,
  entrepot_id uuid,
  entrepot_nom text,
  display_name text
) language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from public.entreprise_users eu0
    where eu0.entreprise_id = p_entreprise_id
      and eu0.user_id = auth.uid()
      and eu0.statut = 'actif'
  ) then
    raise exception 'NOT_A_MEMBER';
  end if;

  return query
  select eu.user_id, u.email::text, eu.role, eu.statut, eu.revoked_at,
         null::uuid as entrepot_id, null::text as entrepot_nom,
         p.display_name
  from public.entreprise_users eu
  join auth.users u on u.id = eu.user_id
  left join public.user_profiles p on p.user_id = eu.user_id
  where eu.entreprise_id = p_entreprise_id
  union all
  select epu.user_id, u.email::text, epu.role, epu.statut, epu.revoked_at,
         e.cloud_id as entrepot_id, e.nom as entrepot_nom,
         p.display_name
  from public.entrepot_users epu
  join public.entrepots e on e.cloud_id = epu.entrepot_id
  join auth.users u on u.id = epu.user_id
  left join public.user_profiles p on p.user_id = epu.user_id
  where e.entreprise_id = p_entreprise_id;
end $$;

-- ═════════════════════════════════════════════════════════════════
-- FIN
-- À déployer puis tester :
--   1. Insert entreprise via app (auth user A)
--   2. Vérifier que user B (auth différent) ne voit pas l'entreprise A
--   3. Inviter user B → user B doit voir l'entreprise après acceptation
--   4. Créer un entrepôt via l'app (RPC create_entrepot, plus de 42P17)
-- ═════════════════════════════════════════════════════════════════
