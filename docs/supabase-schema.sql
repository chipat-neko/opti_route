-- ══════════════════════════════════════════════════════════════════
-- opti_route — Schema cloud Postgres (Phase 2, sous-jalon 2.A)
-- ══════════════════════════════════════════════════════════════════
--
-- Ce script crée les 4 tables qui reflètent les tables Drift locales
-- de l'app, plus les Row Level Security policies pour que chaque
-- utilisateur Supabase ne voie QUE ses propres lignes.
--
-- Idempotent : ré-exécutable sans casser un schema existant grâce
-- aux `IF NOT EXISTS`, `CREATE OR REPLACE` et `DROP POLICY IF EXISTS`.
--
-- À exécuter dans : Supabase Dashboard > SQL Editor > New query.
--
-- ────────────────────────────────────────────────────────────────
-- Notes de design
-- ────────────────────────────────────────────────────────────────
-- 1. **IDs UUID** au lieu d'autoIncrement int. Indispensable pour
--    sync multi-appareils : 2 phones peuvent générer des IDs en
--    parallèle sans collision (alors que des integers se marcheraient
--    dessus). Les apps Flutter génèrent l'UUID localement avec
--    package `uuid` côté Drift (colonne `cloud_id TEXT` à ajouter
--    plus tard, dans le sous-jalon 2.B).
--
-- 2. **user_id partout** : chaque row porte le user_id de son
--    propriétaire. C'est la clé du RLS. ON DELETE CASCADE : si un
--    user supprime son compte, toutes ses données disparaissent.
--
-- 3. **updated_at + trigger** : sert à la stratégie last-write-wins
--    pour le sync (jalon 2.B). Pas encore utilisé mais le trigger
--    est en place dès maintenant.
--
-- 4. **Pas de photos dans ce jalon** : `preuve_photo_path` est gardé
--    comme TEXT (chemin local). En 2.E on ajoutera une colonne
--    `preuve_photo_storage_path` pour Supabase Storage.
--
-- 5. **Pas de FK cross-app pour saved_destinations** : le carnet
--    n'est pas lié aux tournées (les arrêts ne référencent pas un
--    `saved_destination_id`, ils dupliquent l'adresse). Identique
--    au modèle Drift local.
-- ══════════════════════════════════════════════════════════════════


-- 0. Extensions ────────────────────────────────────────────────────
-- pgcrypto pour gen_random_uuid(). Activé par défaut sur Supabase
-- mais on l'écrit explicitement pour être portable.
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- 1. Helper : trigger générique updated_at ────────────────────────
-- Sous-jalon 2.D-1c : on ne touche `updated_at` que si le client
-- n'a pas envoyé de valeur explicite (ou a réutilisé la même que
-- précédemment). Ça permet aux apps Flutter de pousser un timestamp
-- *source* (= moment où la modif a été faite sur le device d'origine),
-- préservé tel quel par Postgres. Sert au last-write-wins fin du pull :
-- les autres devices comparent leur local.updated_at vs ce timestamp
-- source. Sans cette logique, le trigger réécrirait toujours à
-- `now()` (= moment du push, pas moment de la modif) → faux conflits.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.updated_at IS NULL OR NEW.updated_at = OLD.updated_at THEN
    NEW.updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- 2. Table coequipiers ────────────────────────────────────────────
-- Créée AVANT tournees/stops car ces deux tables y référencent.
CREATE TABLE IF NOT EXISTS public.coequipiers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nom         TEXT NOT NULL CHECK (char_length(nom) BETWEEN 1 AND 20),
  color_tag   TEXT,
  telephone   TEXT,
  actif       BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS coequipiers_user_id_idx
  ON public.coequipiers (user_id);

DROP TRIGGER IF EXISTS coequipiers_set_updated_at ON public.coequipiers;
CREATE TRIGGER coequipiers_set_updated_at
  BEFORE UPDATE ON public.coequipiers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- 3. Table tournees ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tournees (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nom                      TEXT NOT NULL CHECK (char_length(nom) BETWEEN 1 AND 100),
  date                     TIMESTAMPTZ NOT NULL,
  point_depart_lat         DOUBLE PRECISION NOT NULL,
  point_depart_lng         DOUBLE PRECISION NOT NULL,
  point_depart_label       TEXT NOT NULL,
  vehicule_capacite_colis  INTEGER NOT NULL DEFAULT 0,
  statut                   TEXT NOT NULL DEFAULT 'brouillon',
  distance_totale_m        INTEGER,
  duree_totale_s           INTEGER,
  optimisee_le             TIMESTAMPTZ,
  trace_geojson            TEXT,
  demaree_le               TIMESTAMPTZ,
  is_template              BOOLEAN NOT NULL DEFAULT false,
  profil_ors               TEXT NOT NULL DEFAULT 'driving-car',
  eviter_peages            BOOLEAN NOT NULL DEFAULT false,
  rappel_le                TIMESTAMPTZ,
  pausee_le                TIMESTAMPTZ,
  pausee_seconds           INTEGER NOT NULL DEFAULT 0,
  coequipier_defaut_id     UUID REFERENCES public.coequipiers(id) ON DELETE SET NULL,
  cree_le                  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tournees_user_id_idx
  ON public.tournees (user_id);
CREATE INDEX IF NOT EXISTS tournees_user_date_idx
  ON public.tournees (user_id, date DESC);

DROP TRIGGER IF EXISTS tournees_set_updated_at ON public.tournees;
CREATE TRIGGER tournees_set_updated_at
  BEFORE UPDATE ON public.tournees
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- 4. Table stops ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.stops (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tournee_id          UUID NOT NULL REFERENCES public.tournees(id) ON DELETE CASCADE,
  adresse_brute       TEXT NOT NULL,
  adresse_normalisee  TEXT,
  lat                 DOUBLE PRECISION,
  lng                 DOUBLE PRECISION,
  nb_colis            INTEGER NOT NULL DEFAULT 1,
  priorite            TEXT NOT NULL DEFAULT 'flexible',
  fenetre_debut       TEXT,
  fenetre_fin         TEXT,
  duree_arret_min     INTEGER NOT NULL DEFAULT 3,
  notes               TEXT,
  nom_client          TEXT,
  statut_livraison    TEXT NOT NULL DEFAULT 'a_livrer',
  raison_echec        TEXT,
  livre_lat           DOUBLE PRECISION,
  livre_lng           DOUBLE PRECISION,
  livre_le            TIMESTAMPTZ,
  ordre_optimise      INTEGER,
  ordre_priorite      INTEGER,
  preuve_photo_path   TEXT,
  coequipier_id       UUID REFERENCES public.coequipiers(id) ON DELETE SET NULL,
  cree_le             TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS stops_user_id_idx
  ON public.stops (user_id);
CREATE INDEX IF NOT EXISTS stops_tournee_id_idx
  ON public.stops (tournee_id);

DROP TRIGGER IF EXISTS stops_set_updated_at ON public.stops;
CREATE TRIGGER stops_set_updated_at
  BEFORE UPDATE ON public.stops
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- 5. Table saved_destinations (carnet client) ─────────────────────
CREATE TABLE IF NOT EXISTS public.saved_destinations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nom_client       TEXT,
  adresse_display  TEXT NOT NULL,
  lat              DOUBLE PRECISION NOT NULL,
  lng              DOUBLE PRECISION NOT NULL,
  rue              TEXT,
  code_postal      TEXT,
  ville            TEXT,
  use_count        INTEGER NOT NULL DEFAULT 1,
  last_used_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  cree_le          TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_favori        BOOLEAN NOT NULL DEFAULT false,
  color_tag        TEXT,
  notes_carnet     TEXT,
  tags_json        TEXT,
  photo_path       TEXT,
  code_acces       TEXT,
  etage_batiment   TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS saved_destinations_user_id_idx
  ON public.saved_destinations (user_id);
CREATE INDEX IF NOT EXISTS saved_destinations_user_lastused_idx
  ON public.saved_destinations (user_id, last_used_at DESC);

DROP TRIGGER IF EXISTS saved_destinations_set_updated_at ON public.saved_destinations;
CREATE TRIGGER saved_destinations_set_updated_at
  BEFORE UPDATE ON public.saved_destinations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ══════════════════════════════════════════════════════════════════
-- 6. Row Level Security : chaque user voit/modifie SES rows
-- ══════════════════════════════════════════════════════════════════
-- Sans RLS activée, le schema serait ouvert à toute personne avec
-- l'anon key (donc tout le monde qui a installé l'app). C'est LE
-- garde-fou critique du multi-tenant Supabase.
--
-- Une seule policy `FOR ALL` par table couvre SELECT/INSERT/UPDATE/
-- DELETE. La condition `user_id = auth.uid()` est appliquée à la
-- fois en USING (filtre lecture) et WITH CHECK (validation écriture)
-- pour empêcher un user de réassigner ses rows à un autre user.

ALTER TABLE public.coequipiers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournees             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stops                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_destinations   ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "owner_all_coequipiers"        ON public.coequipiers;
CREATE POLICY "owner_all_coequipiers" ON public.coequipiers
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "owner_all_tournees"           ON public.tournees;
CREATE POLICY "owner_all_tournees" ON public.tournees
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "owner_all_stops"              ON public.stops;
CREATE POLICY "owner_all_stops" ON public.stops
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "owner_all_saved_destinations" ON public.saved_destinations;
CREATE POLICY "owner_all_saved_destinations" ON public.saved_destinations
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ══════════════════════════════════════════════════════════════════
-- 7. Migrations incrémentales
-- ══════════════════════════════════════════════════════════════════
-- Idempotent via `ADD COLUMN IF NOT EXISTS` / `CREATE OR REPLACE`.
-- À ré-exécuter sur les projets Supabase déjà existants pour aligner
-- le schema avec les nouvelles colonnes ajoutées par les jalons.

-- Sous-jalon 2.E : chemin de la photo preuve dans le bucket Storage
-- `preuves` (format `<user_id>/<stop_uuid>.jpg`). Null = pas de photo
-- uploadée. L'upload se fait au push du stop par CloudSyncService.
ALTER TABLE public.stops
  ADD COLUMN IF NOT EXISTS cloud_photo_path TEXT;

-- Sous-jalon 2.D-1c : mise à jour du comportement du trigger
-- `set_updated_at`. AVANT : écrasait toujours `updated_at` à `now()`
-- au moment du push (donc le timestamp source du device d'origine
-- était perdu). MAINTENANT : ne touche `updated_at` que si le client
-- n'a rien envoyé ou a réutilisé la valeur précédente.
--
-- La nouvelle définition est déjà dans la section 1 (CREATE OR REPLACE
-- FUNCTION) — ré-exécuter le script complet la propage automatiquement
-- partout (les triggers la rappellent à chaque UPDATE).
--
-- Sert au last-write-wins fin : les autres devices comparent leur
-- `local.updated_at` vs le timestamp source pour décider d'écraser
-- ou skip. Sans cette logique, le pull rewriterait tout systématique-
-- ment puisque `cloud.updated_at = now() > local.updated_at` toujours.


-- ══════════════════════════════════════════════════════════════════
-- 8. Storage bucket `preuves` (sous-jalon 2.E)
-- ══════════════════════════════════════════════════════════════════
-- Bucket privé pour les photos preuves de livraison. Chaque user n'a
-- accès qu'à son sous-dossier `<user_id>/` via RLS sur storage.objects.
--
-- Quota free tier : 1 GB total Storage + 2 GB transfer/mois → largement
-- assez pour Noah (1 photo ~150 KB × 30 livraisons/j × 30 j = 135 MB/mois).

-- Création du bucket (private, RLS controlée par les policies ci-dessous).
INSERT INTO storage.buckets (id, name, public)
  VALUES ('preuves', 'preuves', false)
  ON CONFLICT (id) DO NOTHING;

-- Policies storage.objects : chaque user lit/écrit/supprime UNIQUEMENT
-- les fichiers dans son sous-dossier `<auth.uid()>/`. L'extraction du
-- premier segment du path se fait via storage.foldername(name)[1].

DROP POLICY IF EXISTS "owner_select_preuves" ON storage.objects;
CREATE POLICY "owner_select_preuves" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'preuves'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "owner_insert_preuves" ON storage.objects;
CREATE POLICY "owner_insert_preuves" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'preuves'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "owner_update_preuves" ON storage.objects;
CREATE POLICY "owner_update_preuves" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'preuves'
    AND auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'preuves'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "owner_delete_preuves" ON storage.objects;
CREATE POLICY "owner_delete_preuves" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'preuves'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );


-- ══════════════════════════════════════════════════════════════════
-- 9. Vérifications post-exécution
-- ══════════════════════════════════════════════════════════════════
-- Ces SELECT sont là pour valider manuellement après exécution. Ils
-- ne lèvent pas d'erreur si tout est OK.

-- Liste les tables créées et leur statut RLS :
-- SELECT tablename, rowsecurity FROM pg_tables
--   WHERE schemaname='public'
--   ORDER BY tablename;

-- Liste les policies actives (incluant storage.objects pour le bucket) :
-- SELECT schemaname, tablename, policyname, cmd
--   FROM pg_policies
--   WHERE schemaname IN ('public','storage')
--   ORDER BY schemaname, tablename;

-- Vérifie que le bucket preuves existe :
-- SELECT id, name, public FROM storage.buckets WHERE id='preuves';
