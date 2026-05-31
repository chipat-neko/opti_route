// Edge Function Supabase : accepte une invitation entreprise/entrepôt.
//
// Carte Trello #363 (épopée multi-tenant #361).
//
// AUTH REQUISE (verify_jwt = true). Appelée par l'app après que
// l'utilisateur clique sur le magic link reçu par mail. Le mail le
// renvoie sur l'app avec `?invitation_id=<uuid>` qui déclenche cet
// endpoint au boot.
//
// Workflow :
//   POST /accept_invitation
//   Headers: Authorization: Bearer <user JWT>
//   Body: { "invitation_id": "uuid" }
//
//   1. Vérifie le JWT et récupère user_id
//   2. Charge l'invitation (statut=pending, pas expirée)
//   3. Vérifie que l'email de l'invitation correspond à celui du
//      compte connecté (sécurité : éviter qu'un user prenne une
//      invitation destinée à un autre)
//   4. Insère row entreprise_users (statut=actif, role=membre OU
//      admin si role_target=admin_entreprise)
//   5. Si entrepot_id non null : insère row entrepot_users avec le
//      role_target (chef_entrepot ou employe)
//   6. Marque l'invitation statut=accepted
//
// Déploiement :
//   `npx supabase functions deploy accept_invitation`

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface AcceptBody {
  invitation_id: string;
}

interface AcceptResponse {
  entreprise_id: string;
  entrepot_id: string | null;
  role: string;
}

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

  const authHeader = req.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return jsonResponse({ error: 'missing Authorization header' }, 401);
  }
  const jwt = authHeader.replace('Bearer ', '');

  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  const { data: userResult, error: userErr } = await adminClient.auth.getUser(jwt);
  if (userErr || !userResult.user) {
    return jsonResponse({ error: 'invalid token' }, 401);
  }
  const callerId = userResult.user.id;
  const callerEmail = userResult.user.email?.toLowerCase();

  let body: AcceptBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid JSON body' }, 400);
  }
  if (typeof body.invitation_id !== 'string') {
    return jsonResponse({ error: 'missing invitation_id' }, 400);
  }

  // Charge l'invitation
  const { data: inv, error: invErr } = await adminClient
    .from('entreprise_invitations')
    .select('*')
    .eq('cloud_id', body.invitation_id)
    .maybeSingle();
  if (invErr || !inv) {
    return jsonResponse({ error: 'invitation introuvable' }, 404);
  }
  if (inv.statut !== 'pending') {
    return jsonResponse(
      { error: `invitation déjà ${inv.statut}` },
      410,
    );
  }
  if (new Date(inv.expires_at) < new Date()) {
    // Auto-expire
    await adminClient
      .from('entreprise_invitations')
      .update({ statut: 'expired' })
      .eq('cloud_id', body.invitation_id);
    return jsonResponse({ error: 'invitation expirée' }, 410);
  }
  // Sécurité : email match
  if (inv.email.toLowerCase() !== callerEmail) {
    return jsonResponse(
      { error: 'email mismatch (invitation destinée à un autre compte)' },
      403,
    );
  }

  // Insère entreprise_users si pas déjà membre
  const { data: existing } = await adminClient
    .from('entreprise_users')
    .select('cloud_id')
    .eq('entreprise_id', inv.entreprise_id)
    .eq('user_id', callerId)
    .maybeSingle();

  // Détermine le role entreprise : admin_entreprise si role_target l'est,
  // sinon membre (rôle générique entreprise, le rôle fin est sur entrepot_users)
  const entRole = inv.role_target === 'admin_entreprise' ? 'admin_entreprise' : 'membre';

  if (!existing) {
    const { error: euErr } = await adminClient
      .from('entreprise_users')
      .insert({
        entreprise_id: inv.entreprise_id,
        user_id: callerId,
        role: entRole,
        statut: 'actif',
      });
    if (euErr) {
      return jsonResponse(
        { error: `insert entreprise_users failed: ${euErr.message}` },
        500,
      );
    }
  }

  // Si entrepot_id : insère entrepot_users
  if (inv.entrepot_id) {
    const { data: existingEpot } = await adminClient
      .from('entrepot_users')
      .select('cloud_id')
      .eq('entrepot_id', inv.entrepot_id)
      .eq('user_id', callerId)
      .maybeSingle();
    if (!existingEpot) {
      const { error: epuErr } = await adminClient
        .from('entrepot_users')
        .insert({
          entrepot_id: inv.entrepot_id,
          user_id: callerId,
          role: inv.role_target,
          statut: 'actif',
        });
      if (epuErr) {
        return jsonResponse(
          { error: `insert entrepot_users failed: ${epuErr.message}` },
          500,
        );
      }
    }
  }

  // Marque invitation accepted
  await adminClient
    .from('entreprise_invitations')
    .update({ statut: 'accepted' })
    .eq('cloud_id', body.invitation_id);

  const response: AcceptResponse = {
    entreprise_id: inv.entreprise_id,
    entrepot_id: inv.entrepot_id,
    role: inv.role_target,
  };
  return jsonResponse(response, 200);
});
