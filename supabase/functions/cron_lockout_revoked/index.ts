// Edge Function Supabase planifiée (cron) : passe les entreprise_users
// et entrepot_users de statut='revoque' à 'expire' après J+30.
//
// Carte Trello #363 (épopée multi-tenant #361). Décision questionnaire
// #361 Q5 : départ employé = accès coupé progressif 30 jours.
//
// PUBLIQUE pour Supabase Cron (mais protégée par CRON_SECRET en header
// pour éviter exécution par tiers).
//
// Workflow :
//   POST /cron_lockout_revoked
//   Headers: X-Cron-Secret: <secret partagé>
//
//   1. Update entreprise_users SET statut='expire'
//      WHERE statut='revoque' AND revoked_at < now() - interval '30 days'
//   2. Update entrepot_users : idem
//   3. Retourne {expired_count: N}
//
// Planification (Supabase Dashboard > Database > Cron) :
//   schedule: "0 3 * * *"  (tous les jours à 03:00 UTC)
//   sql: select net.http_post(
//     url := 'https://<project>.supabase.co/functions/v1/cron_lockout_revoked',
//     headers := '{"X-Cron-Secret": "<secret>"}'::jsonb
//   );
//
// Déploiement :
//   `npx supabase functions deploy cron_lockout_revoked --no-verify-jwt`

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'x-cron-secret, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
  });
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method not allowed' }, 405);
  }

  // Auth via secret partagé (configuré dans Dashboard > Edge Functions > Secrets)
  const expectedSecret = Deno.env.get('CRON_SECRET');
  const providedSecret = req.headers.get('X-Cron-Secret');
  if (!expectedSecret || providedSecret !== expectedSecret) {
    return jsonResponse({ error: 'unauthorized' }, 401);
  }

  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  // 30 jours en arrière
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  // Expire entreprise_users
  const { data: entUpdated, error: entErr } = await adminClient
    .from('entreprise_users')
    .update({ statut: 'expire' })
    .eq('statut', 'revoque')
    .lt('revoked_at', cutoff)
    .select('cloud_id');

  if (entErr) {
    return jsonResponse(
      { error: `entreprise_users update failed: ${entErr.message}` },
      500,
    );
  }

  // Expire entrepot_users
  const { data: epotUpdated, error: epotErr } = await adminClient
    .from('entrepot_users')
    .update({ statut: 'expire' })
    .eq('statut', 'revoque')
    .lt('revoked_at', cutoff)
    .select('cloud_id');

  if (epotErr) {
    return jsonResponse(
      { error: `entrepot_users update failed: ${epotErr.message}` },
      500,
    );
  }

  // Aussi : expire les invitations pending dont expires_at est passé
  const { data: invExpired } = await adminClient
    .from('entreprise_invitations')
    .update({ statut: 'expired' })
    .eq('statut', 'pending')
    .lt('expires_at', new Date().toISOString())
    .select('cloud_id');

  return jsonResponse({
    entreprise_users_expired: entUpdated?.length ?? 0,
    entrepot_users_expired: epotUpdated?.length ?? 0,
    invitations_expired: invExpired?.length ?? 0,
    cutoff,
  });
});
