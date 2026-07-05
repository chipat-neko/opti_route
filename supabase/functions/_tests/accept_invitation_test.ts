// Tests de la garde de sécurité de `accept_invitation`
// (audit 2026-06-11).
import {
  assertEquals,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';
import {
  checkInvitation,
  deriveEntrepriseRole,
  type InvitationRow,
} from '../accept_invitation/lib.ts';

const kNow = new Date('2026-06-11T12:00:00Z');

function inv(overrides: Partial<InvitationRow> = {}): InvitationRow {
  return {
    statut: 'pending',
    expires_at: '2026-06-18T12:00:00Z',
    email: 'noah@example.com',
    role_target: 'employe',
    ...overrides,
  };
}

Deno.test('checkInvitation : invitation valide -> ok', () => {
  const r = checkInvitation(inv(), 'noah@example.com', kNow);
  assertEquals(r.ok, true);
});

Deno.test('checkInvitation : email insensible à la casse côté invitation', () => {
  // Le handler lowercase l'email du caller ; l'email de l'invitation est
  // lowercasé par la garde elle-même.
  const r = checkInvitation(
    inv({ email: 'Noah@Example.COM' }),
    'noah@example.com',
    kNow,
  );
  assertEquals(r.ok, true);
});

Deno.test('checkInvitation : déjà acceptée -> 410', () => {
  const r = checkInvitation(inv({ statut: 'accepted' }), 'noah@example.com', kNow);
  assertEquals(r.ok, false);
  if (!r.ok) {
    assertEquals(r.status, 410);
    assertEquals(r.error, 'invitation déjà accepted');
    assertEquals(r.autoExpire, undefined);
  }
});

Deno.test('checkInvitation : expirée -> 410 + autoExpire', () => {
  const r = checkInvitation(
    inv({ expires_at: '2026-06-10T12:00:00Z' }),
    'noah@example.com',
    kNow,
  );
  assertEquals(r.ok, false);
  if (!r.ok) {
    assertEquals(r.status, 410);
    assertEquals(r.autoExpire, true);
  }
});

Deno.test('checkInvitation : email mismatch -> 403 (vol d\'invitation)', () => {
  const r = checkInvitation(inv(), 'autre@example.com', kNow);
  assertEquals(r.ok, false);
  if (!r.ok) assertEquals(r.status, 403);
});

Deno.test('checkInvitation : caller sans email -> 403', () => {
  const r = checkInvitation(inv(), undefined, kNow);
  assertEquals(r.ok, false);
  if (!r.ok) assertEquals(r.status, 403);
});

Deno.test('checkInvitation : le statut est vérifié AVANT l\'email (pas d\'oracle)', () => {
  // Une invitation déjà consommée répond 410 même à un email mismatch :
  // l'ordre des gardes ne doit pas révéler à un tiers si son email
  // correspond.
  const r = checkInvitation(
    inv({ statut: 'accepted' }),
    'autre@example.com',
    kNow,
  );
  assertEquals(r.ok, false);
  if (!r.ok) assertEquals(r.status, 410);
});

Deno.test('deriveEntrepriseRole : admin passe, le reste -> membre', () => {
  assertEquals(deriveEntrepriseRole('admin_entreprise'), 'admin_entreprise');
  assertEquals(deriveEntrepriseRole('chef_entrepot'), 'membre');
  assertEquals(deriveEntrepriseRole('employe'), 'membre');
});
