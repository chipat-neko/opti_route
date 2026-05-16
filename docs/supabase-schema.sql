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
-- Sous-jalon 3.A : mode équipe live (chef ↔ coéquipiers)
-- ══════════════════════════════════════════════════════════════════
-- Permet au chef (owner) de partager UNE tournée à un coéquipier qui
-- la voit en temps réel et peut modifier les stops (statuts livraison,
-- notes, etc.). Le tout via Supabase Realtime (Postgres Changes).
--
-- Architecture :
-- - `tournee_membres` : (tournee_id, user_id, role) — qui a accès à
--   quelle tournée. Role `owner` ou `member`. La RLS des tables
--   `tournees` / `stops` est élargie pour autoriser tous les membres
--   (pas juste le owner).
-- - `tournee_invitations` : codes courts à 6 chiffres générés par le
--   chef, utilisés par le coéquipier pour rejoindre la tournée.
-- - Fonction RPC `accept_invitation(code)` qui valide + INSERT membre +
--   marque le code comme utilisé, dans une seule transaction sécurisée.
-- - Trigger `tournees_auto_add_owner_membre` : à chaque INSERT dans
--   tournees, crée auto le row owner dans tournee_membres (sinon le
--   chef ne pourrait pas voir SA propre tournée à cause de la RLS
--   modifiée).
-- - Realtime publication `supabase_realtime` étendue aux nouvelles
--   tables pour que les clients reçoivent les events en push.


-- 3.A.1 — Table `tournee_membres` ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.tournee_membres (
  tournee_id  UUID NOT NULL REFERENCES public.tournees(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (role IN ('owner', 'member')),
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tournee_id, user_id)
);

CREATE INDEX IF NOT EXISTS tournee_membres_user_id_idx
  ON public.tournee_membres (user_id);


-- 3.A.2 — Trigger auto-add owner ──────────────────────────────────
-- À l'INSERT d'une tournée, ajoute auto le row owner dans
-- tournee_membres. Sans ce trigger, après le passage en RLS « membre »,
-- le chef perdrait l'accès à sa propre tournée tant qu'il n'a pas
-- aussi inséré son row membre manuellement.
CREATE OR REPLACE FUNCTION public.tournees_auto_add_owner_membre()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.tournee_membres (tournee_id, user_id, role)
    VALUES (NEW.id, NEW.user_id, 'owner')
    ON CONFLICT (tournee_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tournees_auto_add_owner_membre
  ON public.tournees;
CREATE TRIGGER tournees_auto_add_owner_membre
  AFTER INSERT ON public.tournees
  FOR EACH ROW EXECUTE FUNCTION public.tournees_auto_add_owner_membre();

-- Backfill : pour les tournées créées avant ce trigger (sous-jalons
-- 2.A → 2.E), ajoute manuellement les rows owner manquants.
INSERT INTO public.tournee_membres (tournee_id, user_id, role)
  SELECT id, user_id, 'owner' FROM public.tournees
  ON CONFLICT (tournee_id, user_id) DO NOTHING;


-- 3.A.3 — RLS sur `tournee_membres` ───────────────────────────────
ALTER TABLE public.tournee_membres ENABLE ROW LEVEL SECURITY;

-- Un user voit SES adhésions ET celles aux tournées où il est déjà
-- membre (pour voir la liste complète des coéquipiers d'une tournée
-- partagée — utile à l'UI "Tournée partagée avec X, Y").
DROP POLICY IF EXISTS "member_select_tournee_membres"
  ON public.tournee_membres;
CREATE POLICY "member_select_tournee_membres"
  ON public.tournee_membres FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR tournee_id IN (
      SELECT tm.tournee_id FROM public.tournee_membres tm
      WHERE tm.user_id = auth.uid()
    )
  );

-- INSERT : géré par le trigger auto-owner OU la fonction RPC
-- accept_invitation (SECURITY DEFINER, contourne la RLS). Aucun INSERT
-- direct par le client n'est autorisé — donc pas de policy INSERT.

-- UPDATE : aucun cas d'usage (role n'est pas modifiable, joined_at
-- non plus). Pas de policy UPDATE → tout UPDATE est refusé.

-- DELETE : un user peut quitter une tournée (supprimer son row), et
-- l'owner peut éjecter un member. Pas l'inverse (un member ne peut
-- pas éjecter l'owner).
DROP POLICY IF EXISTS "leave_or_kick_tournee_membres"
  ON public.tournee_membres;
CREATE POLICY "leave_or_kick_tournee_membres"
  ON public.tournee_membres FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()  -- je quitte
    OR (
      role = 'member'      -- éjection d'un member par l'owner
      AND EXISTS (
        SELECT 1 FROM public.tournee_membres me
        WHERE me.tournee_id = tournee_membres.tournee_id
        AND me.user_id = auth.uid()
        AND me.role = 'owner'
      )
    )
  );


-- 3.A.4 — RLS sur `tournees` (split FOR ALL en SELECT/INSERT/UPDATE/DELETE)
-- Remplace la policy `owner_all_tournees` de la section 6. Le split
-- permet de DIFFERENCIER les permissions par operation :
-- - SELECT : tout membre (owner + member) voit la tournee
-- - INSERT : seulement avec user_id = auth.uid() (creation de SA tournee).
--   Le trigger auto-add-owner remplit ensuite tournee_membres.
-- - UPDATE : tout membre peut modifier (statuts, demareeLe, etc). Le
--   changement de user_id est bloque par le trigger
--   `tournees_protect_user_id` ci-dessous (sinon Lucas pourrait voler
--   la tournee de Noah en re-pushant avec son propre user_id).
-- - DELETE : OWNER UNIQUEMENT. Un member ne peut pas supprimer la
--   tournee du chef (perte de donnees catastrophique pour Noah).
DROP POLICY IF EXISTS "owner_all_tournees"        ON public.tournees;
DROP POLICY IF EXISTS "member_all_tournees"       ON public.tournees;
DROP POLICY IF EXISTS "member_select_tournees"    ON public.tournees;
DROP POLICY IF EXISTS "owner_insert_tournees"     ON public.tournees;
DROP POLICY IF EXISTS "member_update_tournees"    ON public.tournees;
DROP POLICY IF EXISTS "owner_delete_tournees"     ON public.tournees;

CREATE POLICY "member_select_tournees" ON public.tournees
  FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT tournee_id FROM public.tournee_membres
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "owner_insert_tournees" ON public.tournees
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "member_update_tournees" ON public.tournees
  FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT tournee_id FROM public.tournee_membres
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    id IN (
      SELECT tournee_id FROM public.tournee_membres
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "owner_delete_tournees" ON public.tournees
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.tournee_membres
      WHERE tournee_id = tournees.id
      AND user_id = auth.uid()
      AND role = 'owner'
    )
  );


-- 3.A.4b — Trigger anti-vol user_id sur tournees ──────────────────
-- Empeche tout UPDATE qui tenterait de changer la colonne user_id
-- (proprietaire). Sans ce trigger, un member d'une tournee partagee
-- pourrait re-pusher un row avec user_id = lui-meme et voler la
-- tournee du chef. Le client est aussi protege au niveau Dart (ne
-- pas envoyer user_id apres le 1er push) mais le serveur est la
-- ligne de defense ultime contre les clients malveillants / bugges.
CREATE OR REPLACE FUNCTION public.tournees_protect_user_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN
    RAISE EXCEPTION 'USER_ID_IMMUTABLE';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tournees_protect_user_id ON public.tournees;
CREATE TRIGGER tournees_protect_user_id
  BEFORE UPDATE ON public.tournees
  FOR EACH ROW EXECUTE FUNCTION public.tournees_protect_user_id();


-- 3.A.5 — RLS sur `stops` (split + DELETE owner-only) ─────────────
-- Meme split que tournees, avec DELETE reserve a l'owner de la
-- tournee parente. Un member peut INSERT/UPDATE un stop (livraison
-- legitime) mais pas en supprimer un (risque d'erreur destructrice).
DROP POLICY IF EXISTS "owner_all_stops"        ON public.stops;
DROP POLICY IF EXISTS "member_all_stops"       ON public.stops;
DROP POLICY IF EXISTS "member_select_stops"    ON public.stops;
DROP POLICY IF EXISTS "member_insert_stops"    ON public.stops;
DROP POLICY IF EXISTS "member_update_stops"    ON public.stops;
DROP POLICY IF EXISTS "owner_delete_stops"     ON public.stops;

CREATE POLICY "member_select_stops" ON public.stops
  FOR SELECT TO authenticated
  USING (
    tournee_id IN (
      SELECT tournee_id FROM public.tournee_membres
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "member_insert_stops" ON public.stops
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND tournee_id IN (
      SELECT tournee_id FROM public.tournee_membres
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "member_update_stops" ON public.stops
  FOR UPDATE TO authenticated
  USING (
    tournee_id IN (
      SELECT tournee_id FROM public.tournee_membres
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    tournee_id IN (
      SELECT tournee_id FROM public.tournee_membres
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "owner_delete_stops" ON public.stops
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.tournee_membres
      WHERE tournee_id = stops.tournee_id
      AND user_id = auth.uid()
      AND role = 'owner'
    )
  );


-- 3.A.5b — Trigger anti-vol user_id sur stops ─────────────────────
CREATE OR REPLACE FUNCTION public.stops_protect_user_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN
    RAISE EXCEPTION 'USER_ID_IMMUTABLE';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS stops_protect_user_id ON public.stops;
CREATE TRIGGER stops_protect_user_id
  BEFORE UPDATE ON public.stops
  FOR EACH ROW EXECUTE FUNCTION public.stops_protect_user_id();


-- 3.A.6 — Table `tournee_invitations` ─────────────────────────────
-- Codes courts 6 chiffres générés par le chef pour inviter un
-- coéquipier. Un code = une tournée, expire après 24h, usage unique.
CREATE TABLE IF NOT EXISTS public.tournee_invitations (
  code        TEXT PRIMARY KEY
              CHECK (code ~ '^[0-9]{6}$'),
  tournee_id  UUID NOT NULL REFERENCES public.tournees(id) ON DELETE CASCADE,
  created_by  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at  TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours'),
  used_by     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  used_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS tournee_invitations_tournee_id_idx
  ON public.tournee_invitations (tournee_id);

ALTER TABLE public.tournee_invitations ENABLE ROW LEVEL SECURITY;

-- L'owner d'une tournée peut créer + voir + révoquer les invitations
-- de SA tournée. Aucun autre user (même les members) ne peut.
DROP POLICY IF EXISTS "owner_all_invitations"
  ON public.tournee_invitations;
CREATE POLICY "owner_all_invitations"
  ON public.tournee_invitations FOR ALL TO authenticated
  USING (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.tournee_membres
      WHERE tournee_id = tournee_invitations.tournee_id
      AND user_id = auth.uid()
      AND role = 'owner'
    )
  )
  WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.tournee_membres
      WHERE tournee_id = tournee_invitations.tournee_id
      AND user_id = auth.uid()
      AND role = 'owner'
    )
  );


-- 3.A.7 — Fonction RPC `accept_invitation(code)` ──────────────────
-- Permet à un user de rejoindre une tournée en saisissant un code.
-- SECURITY DEFINER : contourne la RLS sur tournee_invitations (que le
-- client appelant ne peut pas SELECT car il n'est ni created_by ni
-- owner). On lit, vérifie, insère membre, marque utilisé — tout
-- atomique côté serveur.
--
-- Retourne :
-- - `tournee_id` (UUID) si succès → l'app pull la tournée + stops
-- - Throw `EXCEPTION` si code invalide / expiré / déjà utilisé / déjà
--   membre. Le client catch et affiche un toast d'erreur.
CREATE OR REPLACE FUNCTION public.accept_invitation(p_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tournee_id UUID;
  v_expires_at TIMESTAMPTZ;
  v_used_at TIMESTAMPTZ;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  SELECT tournee_id, expires_at, used_at
    INTO v_tournee_id, v_expires_at, v_used_at
    FROM public.tournee_invitations
    WHERE code = p_code;

  IF v_tournee_id IS NULL THEN
    RAISE EXCEPTION 'CODE_INTROUVABLE';
  END IF;
  IF v_expires_at < now() THEN
    RAISE EXCEPTION 'CODE_EXPIRE';
  END IF;
  IF v_used_at IS NOT NULL THEN
    RAISE EXCEPTION 'CODE_DEJA_UTILISE';
  END IF;

  -- Insère le membre (idempotent si déjà membre — pas une erreur, juste
  -- on continue pour marquer le code utilisé et l'app peut pull).
  INSERT INTO public.tournee_membres (tournee_id, user_id, role)
    VALUES (v_tournee_id, v_user_id, 'member')
    ON CONFLICT (tournee_id, user_id) DO NOTHING;

  UPDATE public.tournee_invitations
    SET used_by = v_user_id, used_at = now()
    WHERE code = p_code;

  RETURN v_tournee_id;
END;
$$;

-- Autoriser l'invocation par les users authentifiés.
GRANT EXECUTE ON FUNCTION public.accept_invitation(TEXT) TO authenticated;


-- 3.A.8 — Realtime publication ────────────────────────────────────
-- Supabase Realtime utilise la publication PG `supabase_realtime`
-- pour pousser les CHANGES en WebSocket. On y ajoute nos tables.
-- Idempotent grâce au DO block qui catch l'erreur "already member".
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.stops;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tournees;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tournee_membres;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END
$$;


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
