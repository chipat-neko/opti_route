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
