// Edge Function Supabase : resout un code de suivi colis (lien court
// 20 chars, ex https://optr.ro/abcd) en donnees de tracking pour la
// page destinataire `site_doc/suivi.html` (deployee par la CI sur
// GitHub Pages sous /opti_route/site/suivi.html). Carte Trello #81.
//
// PUBLIQUE (verify_jwt = false) : le destinataire n'a pas de compte
// opti_route. Le code 4 chars + expiration 24h tient lieu de secret
// (brute-force ~1.6M combinaisons, expire vite).
//
// Workflow :
//   GET /track?code=abcd  (ou path /track/abcd)
//   -> lookup tracking_codes (code -> stop_id, non expire)
//   -> lookup stops (destination + statut)
//   -> compte les arrets restants avant celui-ci dans la tournee
//   -> retourne JSON pour la page suivi.html
//
// Deploiement : `npx supabase functions deploy track --no-verify-jwt`
//
// PRE-REQUIS schema cloud (a appliquer une fois) :
//   create table tracking_codes (
//     code text primary key,
//     stop_id uuid not null references stops(id) on delete cascade,
//     created_at timestamptz default now(),
//     expires_at timestamptz not null default (now() + interval '24 hours')
//   );
//   alter table tracking_codes enable row level security;
//   -- pas de policy SELECT publique : la function utilise la service
//   -- role key (bypass RLS) cote serveur, jamais exposee au client.
//
// PRE-REQUIS app (a faire) : pousser le code au cloud dans
// TrackingCodesRepository.generateForStop (actuellement local-only).

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
};

interface TrackResponse {
  recipient: string | null;
  status: 'a_livrer' | 'livre' | 'echec';
  status_label: string;
  dest_lat: number | null;
  dest_lng: number | null;
  // Position live du livreur : null tant que live_presence (jalon 3.C)
  // n'est pas branche. La page tombe alors sur la destination seule.
  livreur_lat: number | null;
  livreur_lng: number | null;
  stops_before: number | null;
  eta_time: string | null;
}

function statusLabel(s: string): string {
  switch (s) {
    case 'livre':
      return 'Livré';
    case 'echec':
      return 'Livraison non aboutie';
    default:
      return 'En cours de livraison';
  }
}

// Minimisation RGPD (audit #176) : le code 4 chars est court (contrainte
// URL <= 20 chars client) et l'endpoint est public sans rate-limit ->
// un code devine ne doit PAS reveler une identite complete ni un
// domicile exact. On renvoie donc le prenom + initiale du nom, et des
// coordonnees arrondies (~110 m).
function pseudonymizeName(name: string | null): string | null {
  if (name == null) return null;
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return null;
  if (parts.length === 1) return parts[0];
  // Premier mot complet + initiale du dernier mot ("Jean Dupont" -> "Jean D.").
  return `${parts[0]} ${parts[parts.length - 1][0].toUpperCase()}.`;
}

// Arrondit a 3 decimales (~110 m) : assez precis pour situer le quartier
// sur la carte de suivi, sans pointer le batiment exact (cf #176/#251).
function coarsenCoord(v: number | null): number | null {
  if (v == null) return null;
  return Math.round(v * 1000) / 1000;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  // Code : depuis ?code= ou le dernier segment du path.
  const url = new URL(req.url);
  let code = url.searchParams.get('code');
  if (!code) {
    const seg = url.pathname.split('/').filter(Boolean);
    code = seg.length ? seg[seg.length - 1] : null;
  }
  // Longueur EXACTE attendue (kTrackingCodeLength = 4 cote app, calibre
  // sur la contrainte client "URL <= 20 chars" : https://optr.ro/abcd).
  // On rejette les codes plus courts (ex 3 chars = espace de recherche
  // reduit) -- audit #176.
  if (!code || !/^[a-z0-9]{4}$/.test(code)) {
    return jsonResponse({ error: 'Code invalide.' }, 400);
  }

  // Service role : bypass RLS pour lire tracking_codes + stops cote
  // serveur. La cle n'est JAMAIS renvoyee au client.
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // 1. Resout le code -> stop_id (non expire).
  const { data: tc, error: tcErr } = await supabase
    .from('tracking_codes')
    .select('stop_id, expires_at')
    .eq('code', code)
    .maybeSingle();
  if (tcErr) {
    return jsonResponse({ error: 'Erreur serveur.' }, 500);
  }
  if (!tc) {
    return jsonResponse({ error: 'Suivi introuvable ou expire.' }, 404);
  }
  if (new Date(tc.expires_at as string) < new Date()) {
    return jsonResponse({ error: 'Ce lien de suivi a expire.' }, 410);
  }

  // 2. Charge le stop cible.
  const { data: stop, error: stopErr } = await supabase
    .from('stops')
    .select(
      'id, tournee_id, nom_client, statut_livraison, lat, lng, ordre_optimise',
    )
    .eq('id', tc.stop_id as string)
    .maybeSingle();
  if (stopErr || !stop) {
    return jsonResponse({ error: 'Livraison introuvable.' }, 404);
  }

  // 3. Compte les arrets restants AVANT celui-ci (statut a_livrer +
  // ordre inferieur) dans la meme tournee -> donne "X arrets avant vous".
  // La colonne reelle est `ordre_optimise` (il n'existe pas de colonne
  // `ordre` sur stops) -- cf audit A6 #234.
  let stopsBefore: number | null = null;
  if (stop.ordre_optimise != null) {
    const { count } = await supabase
      .from('stops')
      .select('id', { count: 'exact', head: true })
      .eq('tournee_id', stop.tournee_id as string)
      .eq('statut_livraison', 'a_livrer')
      .lt('ordre_optimise', stop.ordre_optimise as number);
    stopsBefore = count ?? null;
  }

  const body: TrackResponse = {
    // Nom pseudonymise (prenom + initiale) et coords arrondies (~110 m)
    // pour limiter ce qu'un code devine peut reveler -- audit #176.
    recipient: pseudonymizeName(stop.nom_client as string | null),
    status: stop.statut_livraison as TrackResponse['status'],
    status_label: statusLabel(stop.statut_livraison as string),
    dest_lat: coarsenCoord((stop.lat as number | null) ?? null),
    dest_lng: coarsenCoord((stop.lng as number | null) ?? null),
    // Position live livreur : pas encore disponible (jalon 3.C
    // live_presence a brancher). Null -> la page affiche la destination.
    // #177 : QUAND on la branchera, passer OBLIGATOIREMENT les coords par
    // coarsenCoord() (sinon surveillance temps reel du livreur via un
    // code devine) et idealement la conditionner a un opt-in du livreur.
    livreur_lat: null,
    livreur_lng: null,
    stops_before: stopsBefore,
    // ETA : a calculer cote serveur depuis les segments (futur). Null
    // pour l'instant -> la page masque le bloc heure.
    eta_time: null,
  };
  return jsonResponse(body);
});
