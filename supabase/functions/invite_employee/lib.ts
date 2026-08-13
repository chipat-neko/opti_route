// Unités pures de la function `invite_employee`, extraites d'index.ts
// pour être testables (audit 2026-06-11, tests dans
// supabase/functions/_tests/invite_employee_test.ts). Aucune dépendance
// réseau : l'appel Brevo et les requêtes Supabase restent dans index.ts.

export interface InviteBody {
  email: string;
  entreprise_id: string;
  entrepot_id: string | null;
  role: 'chef_entrepot' | 'employe';
}

export function validateBody(raw: unknown): InviteBody | string {
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
export function genCode(): string {
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

export function roleLabel(role: string): string {
  return role === 'chef_entrepot' ? "chef d'entrepôt" : 'employé';
}

export function escapeHtml(s: string): string {
  return s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

export function buildEmailHtml(params: {
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

// ── CORS restreint (F39) ─────────────────────────────────────────────
// Remplace l'ancien `Access-Control-Allow-Origin: *`. Le vrai garde-fou
// reste le JWT (`verify_jwt = true` dans supabase/config.toml) + le
// contrôle des droits du caller dans index.ts ; l'allow-list n'est
// qu'une couche de plus, qui empêche une page tierce de faire créer une
// invitation par le navigateur d'un chef connecté.
//
// Origines légitimes (mêmes que ocr-enhance/lib.ts #183 — garder les
// deux listes en phase si un domaine bouge) :
//   - https://chipat-neko.github.io : app Flutter Web + site vitrine
//     publiés par .github/workflows/deploy-web.yml. Le base-href est
//     `/opti_route/` mais une Origin ne contient jamais le chemin :
//     c'est bien le domaine nu qu'envoie le navigateur.
//   - http://localhost(:port) : `flutter run -d chrome` en dev.
// L'appelant réel est `CloudMembresEntrepriseSync.inviteByMail`
// (client.functions.invoke) : sur mobile natif et desktop (MSIX) il n'y
// a pas d'en-tête Origin ni de CORS, donc ces flux ne sont pas touchés.
export const ALLOWED_ORIGINS = [
  'https://chipat-neko.github.io', // app web + site (GitHub Pages)
  'http://localhost', // dev web local (port quelconque)
];

// Origine dans l'allow-list -> on l'écho. Origine inconnue (ou absente,
// cas mobile) -> on renvoie l'origine prod, qui ne matchera pas celle du
// navigateur tiers : c'est lui qui bloquera la lecture de la réponse.
// `Vary: Origin` évite qu'un cache intermédiaire serve la réponse d'une
// origine à une autre.
export function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get('origin') ?? '';
  const allowed = ALLOWED_ORIGINS.some(
    (o) => origin === o || origin.startsWith(`${o}:`),
  );
  return {
    'Access-Control-Allow-Origin': allowed ? origin : ALLOWED_ORIGINS[0],
    // `x-client-info` / `apikey` sont ajoutés par le client Supabase :
    // sans eux dans l'allow-list le préflight échouerait côté web.
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  };
}
