// Unités pures de la function `accept_invitation`, extraites d'index.ts
// pour être testables (audit 2026-06-11, tests dans
// supabase/functions/_tests/accept_invitation_test.ts).

export interface InvitationRow {
  statut: string;
  expires_at: string;
  email: string;
  role_target: string;
}

export type InvitationCheck =
  | { ok: true }
  | { ok: false; error: string; status: number; autoExpire?: boolean };

// Garde de sécurité de l'acceptation : statut pending, non expirée, et
// email de l'invitation == email du compte connecté (sinon n'importe
// quel user authentifié pourrait consommer une invitation destinée à un
// autre). `autoExpire` signale au handler qu'il doit marquer
// l'invitation 'expired' en base avant de répondre.
export function checkInvitation(
  inv: InvitationRow,
  callerEmail: string | undefined,
  now: Date,
): InvitationCheck {
  if (inv.statut !== 'pending') {
    return { ok: false, error: `invitation déjà ${inv.statut}`, status: 410 };
  }
  if (new Date(inv.expires_at) < now) {
    return {
      ok: false,
      error: 'invitation expirée',
      status: 410,
      autoExpire: true,
    };
  }
  if (inv.email.toLowerCase() !== callerEmail) {
    return {
      ok: false,
      error: 'email mismatch (invitation destinée à un autre compte)',
      status: 403,
    };
  }
  return { ok: true };
}

// Détermine le role entreprise : admin_entreprise si role_target l'est,
// sinon membre (rôle générique entreprise, le rôle fin est sur
// entrepot_users).
export function deriveEntrepriseRole(roleTarget: string): string {
  return roleTarget === 'admin_entreprise' ? 'admin_entreprise' : 'membre';
}

// ── CORS restreint (F39) ─────────────────────────────────────────────
// Remplace l'ancien `Access-Control-Allow-Origin: *`. Le vrai garde-fou
// reste le JWT (`verify_jwt = true` dans supabase/config.toml) + la
// garde `checkInvitation` ci-dessus ; l'allow-list n'est qu'une couche
// de plus, qui empêche une page tierce de faire appeler l'endpoint par
// le navigateur d'un utilisateur connecté.
//
// Origines légitimes (mêmes que ocr-enhance/lib.ts #183 — garder les
// deux listes en phase si un domaine bouge) :
//   - https://chipat-neko.github.io : app Flutter Web + site vitrine
//     publiés par .github/workflows/deploy-web.yml. Le base-href est
//     `/opti_route/` mais une Origin ne contient jamais le chemin :
//     c'est bien le domaine nu qu'envoie le navigateur.
//   - http://localhost(:port) : `flutter run -d chrome` en dev.
// Mobile natif et desktop (MSIX) n'envoient PAS d'en-tête Origin et ne
// sont pas soumis au CORS : la restriction ne peut pas casser ces
// appels, qui sont aujourd'hui la seule voie réelle vers cet endpoint.
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
    // `x-client-info` / `apikey` sont ajoutés par le client Supabase JS :
    // sans eux dans l'allow-list le préflight échouerait côté web.
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Vary': 'Origin',
  };
}
