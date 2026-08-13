-- ═════════════════════════════════════════════════════════════════
-- Supabase schema : job pg_cron `cron_lockout_revoked`
-- Audit v2 — item F31 (le job existait en prod, versionné nulle part)
-- Date : 2026-08-13
-- ═════════════════════════════════════════════════════════════════
--
-- Rôle du job : appeler tous les jours l'Edge Function
-- `cron_lockout_revoked` (supabase/functions/cron_lockout_revoked/),
-- qui fait le ménage des accès périmés :
--   1. entreprise_users : statut 'revoque' → 'expire' après J+30
--      (décision questionnaire #361 Q5 : départ employé = coupure
--       progressive sur 30 jours, carte Trello #363)
--   2. entrepot_users   : idem
--   3. entreprise_invitations : 'pending' → 'expired' si expires_at passé
--
-- Sans ce job, les lignes 'revoque' restent indéfiniment en base et les
-- invitations expirées restent 'pending' : aucun blocage fonctionnel
-- immédiat, mais l'état de la base diverge de la règle métier.
--
-- ⚠️ RECONSTITUTION — à vérifier avant tout rejeu sur la PROD
--    Le job a été créé à la main (Dashboard > Database > Cron) et sa
--    définition exacte n'est archivée nulle part dans le repo. Cette
--    migration est reconstituée depuis l'en-tête de
--    `supabase/functions/cron_lockout_revoked/index.ts` (bloc de
--    commentaire « Planification », vers les lignes 19-24) : c'est la
--    seule trace écrite du job — schedule "0 3 * * *" + net.http_post
--    avec l'en-tête X-Cron-Secret.
--    TODO(F31) : sur le projet prod, exécuter
--      select jobid, jobname, schedule, command from cron.job;
--    et aligner CE fichier sur la définition réellement en place
--    (surtout le `jobname` : s'il diffère de 'cron_lockout_revoked',
--     le bloc d'unschedule ci-dessous ne le verra pas et cette
--     migration créera un SECOND job → double exécution quotidienne).
--
-- ⚠️ Idempotent : rejouable sans casser une install existante
--    (CREATE EXTENSION IF NOT EXISTS, unschedule tolérant à l'absence,
--     cron.schedule qui remplace un job de même nom).
--
-- À déployer : `supabase db push` OU Dashboard > SQL Editor.
--    À jouer APRÈS 20260531000000_multi_tenant.sql (les tables que
--    l'Edge Function met à jour y sont créées ; la dépendance est
--    logique, pas syntaxique — ce fichier ne référence aucune table).

-- ─────────────────────────────────────────────────────────────────
-- 0. EXTENSIONS
--    pg_cron : le planificateur (objets exposés dans le schéma `cron`).
--    pg_net  : appels HTTP asynchrones depuis Postgres (schéma `net`),
--              c'est lui qui fournit net.http_post().
--    Les deux sont normalement déjà activées sur le projet Supabase
--    (Dashboard > Database > Extensions) ; on les écrit quand même pour
--    qu'une base vierge soit reconstructible d'un bloc.
-- ─────────────────────────────────────────────────────────────────
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Droits documentés par Supabase pour pg_cron : l'extension est créée
-- par `supabase_admin`, le rôle `postgres` (celui du SQL Editor et de
-- `supabase db push`) doit pouvoir lire cron.job / cron.job_run_details.
-- Toléré si le rôle n'existe pas (Postgres nu) ou droits insuffisants.
do $$
begin
  grant usage on schema cron to postgres;
  grant all privileges on all tables in schema cron to postgres;
exception
  when others then
    raise warning 'cron_lockout_revoked : grants sur le schéma cron ignorés (%).', sqlerrm;
end;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 1. SECRETS — AUCUN secret en clair dans ce fichier (repo public)
--
--    La commande planifiée lit ses deux paramètres dans Supabase Vault
--    AU MOMENT DE L'EXÉCUTION (pas ici) :
--      • 'project_url' : base de l'API, ex https://<project-ref>.supabase.co
--                        (le <project-ref> est dans supabase/config.toml)
--      • 'cron_secret' : même valeur que le secret CRON_SECRET des Edge
--                        Functions (Dashboard > Edge Functions > Secrets),
--                        comparé à temps constant côté function (lib.ts).
--
--    À renseigner UNE FOIS par projet, hors versionnement :
--      select vault.create_secret('https://<project-ref>.supabase.co',
--                                 'project_url', 'Base URL API Supabase');
--      select vault.create_secret('<valeur de CRON_SECRET>',
--                                 'cron_secret', 'Secret du job pg_cron');
--    (mise à jour ultérieure : vault.update_secret(<uuid>, '<valeur>'))
--
--    Ces deux create_secret NE SONT PAS joués ici volontairement :
--    ils contiendraient un secret en clair dans un fichier versionné.
--    Le bloc ci-dessous se contente d'alerter s'ils manquent.
-- ─────────────────────────────────────────────────────────────────
do $$
declare
  v_manquants text;
begin
  select string_agg(nom, ', ')
    into v_manquants
    from (values ('project_url'), ('cron_secret')) as attendu(nom)
   where not exists (
     select 1 from vault.decrypted_secrets s where s.name = attendu.nom
   );

  if v_manquants is not null then
    raise warning 'cron_lockout_revoked : secret(s) Vault manquant(s) : % — le job sera planifié mais échouera tant qu''ils ne sont pas créés (cf section 1).', v_manquants;
  end if;
exception
  -- Vault absent (Postgres nu hors Supabase) ou droits insuffisants :
  -- on ne bloque pas la migration pour une simple vérification.
  when others then
    raise warning 'cron_lockout_revoked : vérification Vault impossible (%) — vérifier project_url / cron_secret à la main.', sqlerrm;
end;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 2. SUPPRESSION IDEMPOTENTE du job homonyme
--    `perform ... from cron.job` ne fait rien si le job n'existe pas
--    (0 ligne) : pas d'erreur au premier passage sur une base vierge.
--    cron.unschedule(name) lèverait une exception dans ce cas.
-- ─────────────────────────────────────────────────────────────────
do $$
begin
  perform cron.unschedule(jobid)
     from cron.job
    where jobname = 'cron_lockout_revoked';
exception
  when others then
    raise warning 'cron_lockout_revoked : unschedule ignoré (%).', sqlerrm;
end;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 3. PLANIFICATION
--    '0 3 * * *' = tous les jours à 03:00 UTC (heure de la base, pas
--    de Paris) — creux d'activité, le job n'est pas urgent à la minute.
--    La function est publique côté gateway (`verify_jwt = false` sous
--    [functions.cron_lockout_revoked] dans supabase/config.toml, déploiement
--    `--no-verify-jwt`) car net.http_post n'envoie pas de JWT utilisateur :
--    l'authentification du job repose UNIQUEMENT sur l'en-tête X-Cron-Secret.
--    NB : cron.schedule remplace le job s'il existe déjà sous ce nom
--    (double sécurité avec la section 2).
-- ─────────────────────────────────────────────────────────────────
select cron.schedule(
  'cron_lockout_revoked',
  '0 3 * * *',
  $job$
  select net.http_post(
    url := (
      select decrypted_secret from vault.decrypted_secrets
       where name = 'project_url'
    ) || '/functions/v1/cron_lockout_revoked',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'X-Cron-Secret', (
        select decrypted_secret from vault.decrypted_secrets
         where name = 'cron_secret'
      )
    ),
    body := '{}'::jsonb,
    -- 3 UPDATE sur des tables petites : large de reste, mais on laisse
    -- de la marge par rapport au défaut pg_net (5 s) pour un cold start
    -- de l'Edge Function.
    timeout_milliseconds := 20000
  );
  $job$
);

-- ═════════════════════════════════════════════════════════════════
-- FIN F31. Vérifs après déploiement :
--   -- le job est planifié
--   select jobid, jobname, schedule, active from cron.job
--    where jobname = 'cron_lockout_revoked';
--   -- il n'y a qu'UN seul job qui vise cette function
--   select jobid, jobname from cron.job
--    where command like '%cron_lockout_revoked%';
--   -- dernières exécutions du JOB SQL
--   select status, return_message, start_time from cron.job_run_details
--    where jobid = (select jobid from cron.job
--                    where jobname = 'cron_lockout_revoked')
--    order by start_time desc limit 5;
--   ATTENTION : net.http_post est ASYNCHRONE (il empile la requête et
--   rend aussitôt un identifiant). Un status 'succeeded' ici prouve
--   seulement que la requête a été mise en file, PAS que l'Edge Function
--   a répondu 200 : le code HTTP n'apparaît jamais dans return_message.
--   -- résultat réel de l'appel HTTP (c'est ICI qu'on voit un 401) :
--   select id, status_code, error_msg, content from net._http_response
--    order by id desc limit 5;
-- status_code 401 = le secret Vault 'cron_secret' ne correspond pas au
-- CRON_SECRET déclaré dans Dashboard > Edge Functions > Secrets.
-- (Table de réponses purgée automatiquement : la consulter peu après
--  l'heure de passage du job.)
-- ═════════════════════════════════════════════════════════════════
