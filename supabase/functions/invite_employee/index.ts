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

// Code à 6 chiffres, zéro-paddé — identique à generateInvitationCode()
// côté Dart (cloud_sync_helpers.dart) pour une UX cohérente.
//
// ⚠️ Sécurité (durcissement nuit 2026-06-01) : on utilise le CSPRNG
// `crypto.getRandomValues` (Web Crypto, dispo dans Deno) et PAS
// `Math.random()` qui est prédictible — un attaquant pourrait sinon
// deviner/réduire l'espace des codes d'invitation et brute-forcer
// `accept_entreprise_invitation`. Cohérent avec Random.secure() côté Dart.
// Rejection sampling pour éliminer le biais modulo sur [0, 1_000_000).
function genCode(): string {
  const max = 1_000_000;
  // Plus grand multiple de `max` <= 2^32, au-delà on rejette le tirage.
  const limit = Math.floor(0xffffffff / max) * max;
  const buf = new Uint32Array(1);
  let n: number;
  do {
    crypto.getRandomValues(buf);
    n = buf[0];
  } while (n >= limit);
  return (n % max).toString().padStart(6, '0');
}

function roleLabel(role: string): string {
  return role === 'chef_entrepot' ? "chef d'entrepôt" : 'employé';
}

function escapeHtml(s: string): string {
  return s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

function buildEmailHtml(params: {
  entrepriseNom: string;
  entrepotNom: string | null;
  role: string;
  code: string;
}): string {
  const { entrepriseNom, entrepotNom, role, code } = params;
  const lieu = entrepotNom
    ? `${escapeHtml(entrepriseNom)} — entrepôt ${escapeHtml(entrepotNom)}`
    : escapeHtml(entrepriseNom);
  return `
  <div style="font-family:Arial,Helvetica,sans-serif;max-width:520px;margin:auto;color:#0E1410;">
    <h2 style="color:#0E7C5A;">Invitation à rejoindre une équipe</h2>
    <p>Tu as été invité(e) à rejoindre <strong>${lieu}</strong> en tant que
       <strong>${escapeHtml(roleLabel(role))}</strong> sur l'application
       <strong>opti_route</strong>.</p>
    <p>Pour rejoindre l'équipe :</p>
    <ol style="line-height:1.6;">
      <li>Ouvre l'application <strong>opti_route</strong> (mobile ou PC).</li>
      <li>Connecte-toi avec <strong>cette adresse email</strong> (un code de
          connexion te sera envoyé).</li>
      <li>Va dans <strong>« Rejoindre une équipe »</strong> et saisis ce code :</li>
    </ol>
    <p style="text-align:center;margin:24px 0;">
      <span style="display:inline-block;font-size:34px;font-weight:bold;
        letter-spacing:8px;color:#0E7C5A;background:#D5EBE0;padding:14px 24px;
        border-radius:12px;">${code}</span>
    </p>
    <p style="color:#5C6660;font-size:13px;">Ce code est valable 7 jours.
       Si tu n'attendais pas cette invitation, ignore ce message.</p>
  </div>`;
}

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
