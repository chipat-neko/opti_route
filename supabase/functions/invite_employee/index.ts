// Edge Function Supabase : invite un employé à rejoindre un entrepôt
// ou une entreprise via mail magic link.
//
// Carte Trello #363 (épopée multi-tenant #361).
//
// AUTH REQUISE (verify_jwt = true) : le caller doit être un user
// connecté + posséder le rôle adéquat dans l'entreprise/entrepôt cible.
//
// Workflow :
//   POST /invite_employee
//   Headers: Authorization: Bearer <user JWT>
//   Body:
//     {
//       "email": "marc@exemple.com",
//       "entreprise_id": "uuid",
//       "entrepot_id": "uuid|null",  // null = invité au niveau entreprise
//       "role": "chef_entrepot" | "employe"
//     }
//
//   1. Vérifie l'authentification du caller via le JWT
//   2. Vérifie les permissions :
//      - Si role demandé = "chef_entrepot" → caller doit être admin_entreprise
//      - Si role demandé = "employe" → caller doit être chef_entrepot de
//        l'entrepôt OU admin_entreprise de l'entreprise parente
//   3. Insère une row dans entreprise_invitations (statut pending,
//      expires_at = now+7d)
//   4. Appelle supabase.auth.admin.inviteUserByEmail(email) avec
//      redirectTo qui inclut le token d'invitation pour que l'app
//      détecte au boot
//
// Déploiement :
//   `npx supabase functions deploy invite_employee`
//
// Variables d'environnement requises (Dashboard > Edge Functions > Secrets) :
//   SUPABASE_URL              (auto)
//   SUPABASE_SERVICE_ROLE_KEY (auto)
//   APP_INVITE_REDIRECT_URL   (ex: https://chipat-neko.github.io/opti_route/#/invite)

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface InviteBody {
  email: string;
  entreprise_id: string;
  entrepot_id: string | null;
  role: 'chef_entrepot' | 'employe';
}

interface InviteResponse {
  invitation_id: string;
  email: string;
  expires_at: string;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'content-type': 'application/json' },
  });
}

function validateBody(raw: unknown): InviteBody | string {
  if (!raw || typeof raw !== 'object') return 'Body must be JSON object';
  const b = raw as Record<string, unknown>;
  if (typeof b.email !== 'string' || !b.email.includes('@')) {
    return 'Invalid email';
  }
  if (typeof b.entreprise_id !== 'string' || b.entreprise_id.length < 30) {
    return 'Invalid entreprise_id (expected UUID)';
  }
  if (b.entrepot_id !== null && typeof b.entrepot_id !== 'string') {
    return 'Invalid entrepot_id (expected UUID or null)';
  }
  if (b.role !== 'chef_entrepot' && b.role !== 'employe') {
    return 'Invalid role (expected chef_entrepot or employe)';
  }
  return {
    email: b.email.trim().toLowerCase(),
    entreprise_id: b.entreprise_id,
    entrepot_id: (b.entrepot_id as string | null) ?? null,
    role: b.role,
  };
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method not allowed' }, 405);
  }

  // 1. Auth du caller
  const authHeader = req.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return jsonResponse({ error: 'missing Authorization header' }, 401);
  }
  const jwt = authHeader.replace('Bearer ', '');

  // Client avec service role pour bypass RLS lors des checks permissions
  // et inviteUserByEmail. Le JWT du caller est utilisé séparément pour
  // identifier qui appelle.
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  // Récupère le user_id du caller via le JWT
  const { data: userResult, error: userErr } = await adminClient.auth.getUser(jwt);
  if (userErr || !userResult.user) {
    return jsonResponse({ error: 'invalid token' }, 401);
  }
  const callerId = userResult.user.id;

  // 2. Parse + validation body
  let bodyRaw: unknown;
  try {
    bodyRaw = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid JSON body' }, 400);
  }
  const parsed = validateBody(bodyRaw);
  if (typeof parsed === 'string') {
    return jsonResponse({ error: parsed }, 400);
  }
  const { email, entreprise_id, entrepot_id, role } = parsed;

  // 3. Check permissions du caller
  // Pour inviter en tant que chef_entrepot → admin_entreprise requis
  // Pour inviter en tant qu'employe → chef_entrepot (de l'entrepot cible)
  //   OU admin_entreprise (de l'entreprise parente)
  const { data: callerEntUser } = await adminClient
    .from('entreprise_users')
    .select('role, statut')
    .eq('entreprise_id', entreprise_id)
    .eq('user_id', callerId)
    .eq('statut', 'actif')
    .maybeSingle();

  const isAdmin = callerEntUser?.role === 'admin_entreprise';

  let isChefOfTargetEntrepot = false;
  if (entrepot_id) {
    const { data: callerEpotUser } = await adminClient
      .from('entrepot_users')
      .select('role, statut')
      .eq('entrepot_id', entrepot_id)
      .eq('user_id', callerId)
      .eq('statut', 'actif')
      .maybeSingle();
    isChefOfTargetEntrepot = callerEpotUser?.role === 'chef_entrepot';
  }

  if (role === 'chef_entrepot' && !isAdmin) {
    return jsonResponse(
      { error: 'only admin_entreprise can invite chef_entrepot' },
      403,
    );
  }
  if (role === 'employe' && !isAdmin && !isChefOfTargetEntrepot) {
    return jsonResponse(
      { error: 'only admin_entreprise or chef_entrepot can invite employe' },
      403,
    );
  }

  // 4. Insert invitation
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
  const { data: inv, error: invErr } = await adminClient
    .from('entreprise_invitations')
    .insert({
      entreprise_id,
      entrepot_id,
      email,
      role_target: role,
      invited_by: callerId,
      statut: 'pending',
      expires_at: expiresAt,
    })
    .select('cloud_id, expires_at')
    .single();
  if (invErr || !inv) {
    return jsonResponse(
      { error: `insert invitation failed: ${invErr?.message}` },
      500,
    );
  }

  // 5. Envoie magic link via Supabase Auth admin
  // L'URL de redirect contient l'invitation_id en query pour que l'app
  // détecte au boot et appelle accept_invitation.
  const redirectBase = Deno.env.get('APP_INVITE_REDIRECT_URL') ??
    'https://chipat-neko.github.io/opti_route/';
  const redirectTo = `${redirectBase}?invitation_id=${inv.cloud_id}`;

  const { error: inviteErr } = await adminClient.auth.admin.inviteUserByEmail(
    email,
    { redirectTo },
  );
  if (inviteErr) {
    // Si user existe déjà : Supabase renvoie une erreur mais c'est OK.
    // On garde l'invitation en pending, l'app détectera le redirect au
    // prochain login. Log juste l'info.
    console.warn(`[invite_employee] inviteUserByEmail warning: ${inviteErr.message}`);
  }

  const response: InviteResponse = {
    invitation_id: inv.cloud_id,
    email,
    expires_at: inv.expires_at,
  };
  return jsonResponse(response, 201);
});
