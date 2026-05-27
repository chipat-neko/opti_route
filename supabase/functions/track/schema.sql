-- Schema cloud pour le suivi colis destinataire (carte Trello #81).
-- A appliquer UNE FOIS dans le SQL editor Supabase (ou via migration).
--
-- La table tracking_codes mappe un code court (4 chars, genere par
-- TrackingCodesRepository cote app) vers un stop cloud. La fonction
-- Edge `track` la lit (service role) pour resoudre un lien de suivi.

create table if not exists tracking_codes (
  code        text primary key,
  stop_id     uuid not null references stops(id) on delete cascade,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default (now() + interval '24 hours')
);

-- Index pour purger les codes expires (cron futur) + lookup rapide.
create index if not exists tracking_codes_expires_idx
  on tracking_codes (expires_at);

-- RLS : active mais SANS policy SELECT publique. La fonction Edge
-- `track` utilise la service role key (bypass RLS) cote serveur, donc
-- elle lit la table meme sans policy. Aucun acces direct client.
alter table tracking_codes enable row level security;

-- Policy INSERT : un user authentifie peut creer un code pour un stop
-- d'une tournee dont il est membre. (Le push depuis l'app, a brancher
-- dans TrackingCodesRepository.generateForStop.)
create policy "membres inserent codes de leurs stops"
  on tracking_codes for insert
  to authenticated
  with check (
    exists (
      select 1
      from stops s
      join tournee_membres m on m.tournee_id = s.tournee_id
      where s.id = tracking_codes.stop_id
        and m.user_id = auth.uid()
    )
  );
