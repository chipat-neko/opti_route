// Edge Function Supabase : invite un employé à rejoindre un entrepôt
// ou une entreprise.
//
// Carte Trello #363 + #60 (épopée multi-tenant #361).
//
// ⚠️ 2026-06-01 — REFONTE (Option B) : on n'envoie plus de magic link
// Supabase (qui exigeait toute la version web connectée au cloud). À la
// place, on **génère un code à 6 chiffres** (comme l'invitation par code)
// et on l'envoie par email via **Brevo** (transactional API). L'employé
// ouvre l'app (mobile/PC), se connecte par OTP, et saisit le code dans
// « Rejoindre une équipe » → RPC `accept_entreprise_invitation(code)`.
// Marche sur toutes les plateformes sans dépendre du web.
//
// AUTH REQUISE (verify_jwt = true) : le caller doit être connecté + avoir
// le rôle adéquat dans l'entreprise/entrepôt cible.
//
// Workflow :
//   POST /invite_employee
//   Headers: Authorization: Bearer <user JWT>
//   Body: { email, entreprise_id, entrepot_id|null, role }
//   1. Vérifie l'auth + les permissions du caller
//   2. Génère un code à 6 chiffres + insère l'invitation (statut pending,
//      expires_at = now+7d)
//   3. Envoie un email Brevo contenant le code + la marche à suivre
//   4. Retourne { invitation_id, email, code, expires_at, email_sent }
//
// Déploiement :
//   `npx supabase functions deploy invite_employee`
//
// Secrets requis (Dashboard > Edge Functions > Secrets) :
//   SUPABASE_URL              (auto)
//   SUPABASE_SERVICE_ROLE_KEY (auto)
//   BREVO_API_KEY             (clé API v3 Brevo : Settings > SMTP & API > API Keys)
//   BREVO_SENDER_EMAIL        (expéditeur VÉRIFIÉ dans Brevo, ex: ton gmail)
//   BREVO_SENDER_NAME         (optionnel, défaut "opti_route")

import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { buildEmailHtml, corsHeaders, genCode, validateBody } from './lib.ts';

// validateBody / genCode / roleLabel / escapeHtml / buildEmailHtml :
// cf ./lib.ts (extraites pour les tests Deno, audit 2026-06-11).
// corsHeaders : allow-list d'origines navigateur (F39). Les en-têtes
// dépendent de l'Origin de la requête, donc ils se calculent par requête
// et non dans une constante de module.

async function sendBrevoEmail(params: {
  apiKey: string;
  senderEmail: string;
  senderName: string;
  toEmail: string;
  subject: string;
  html: string;
}): Promise<{ ok: boolean; error?: string }> {
  try {
    const resp = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': params.apiKey,
        'content-type': 'application/json',
        'accept': 'application/json',
      },
      body: JSON.stringify({
        sender: { name: params.senderName, email: params.senderEmail },
        to: [{ email: params.toEmail }],
        subject: params.subject,
        htmlContent: params.html,
      }),
    });
    if (!resp.ok) {
      const txt = await resp.text();
      return { ok: false, error: `Brevo ${resp.status}: ${txt}` };
    }
    return { ok: true };
  } catch (e) {
    return { ok: false, error: `Brevo fetch failed: ${e}` };
  }
}

serve(async (req: Request) => {
  const cors = corsHeaders(req);
  const jsonResponse = (body: unknown, status = 200): Response =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, 'content-type': 'application/json' },
    });

  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: cors });
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

  // 4. Génère le code + insère l'invitation
  const code = genCode();
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
      code,
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

  // 5. Récupère le nom entreprise (+ entrepôt) pour personnaliser le mail
  const { data: entRow } = await adminClient
    .from('entreprises')
    .select('nom')
    .eq('cloud_id', entreprise_id)
    .maybeSingle();
  const entrepriseNom = entRow?.nom ?? 'une entreprise';

  let entrepotNom: string | null = null;
  if (entrepot_id) {
    const { data: epotRow } = await adminClient
      .from('entrepots')
      .select('nom')
      .eq('cloud_id', entrepot_id)
      .maybeSingle();
    entrepotNom = epotRow?.nom ?? null;
  }

  // 6. Envoie le mail via Brevo (transactional API)
  const apiKey = Deno.env.get('BREVO_API_KEY');
  const senderEmail = Deno.env.get('BREVO_SENDER_EMAIL');
  const senderName = Deno.env.get('BREVO_SENDER_NAME') ?? 'opti_route';

  let emailSent = false;
  let emailError: string | undefined;
  if (!apiKey || !senderEmail) {
    emailError = 'BREVO_API_KEY ou BREVO_SENDER_EMAIL non configuré';
    console.error(`[invite_employee] ${emailError}`);
  } else {
    const html = buildEmailHtml({ entrepriseNom, entrepotNom, role, code });
    const subject = `Invitation à rejoindre ${entrepriseNom} sur opti_route`;
    const sent = await sendBrevoEmail({
      apiKey, senderEmail, senderName, toEmail: email, subject, html,
    });
    emailSent = sent.ok;
    emailError = sent.error;
    if (!sent.ok) console.error(`[invite_employee] email KO: ${sent.error}`);
  }

  // On retourne TOUJOURS le code : même si le mail échoue (clé Brevo
  // manquante, spam, etc.), le chef peut le communiquer manuellement.
  return jsonResponse(
    {
      invitation_id: inv.cloud_id,
      email,
      code,
      expires_at: inv.expires_at,
      email_sent: emailSent,
      email_error: emailError,
    },
    201,
  );
});
