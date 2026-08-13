// Tests de la garde de sécurité de `accept_invitation`
// (audit 2026-06-11).
import {
  assertEquals,
  assertNotEquals,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';
import {
  ALLOWED_ORIGINS,
  checkInvitation,
  corsHeaders,
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

// ── CORS restreint (F39) ─────────────────────────────────────────────

function reqWithOrigin(origin?: string): Request {
  const headers = origin ? { origin } : undefined;
  return new Request('https://x.test/accept_invitation', { headers });
}

Deno.test('corsHeaders : plus de wildcard `*` (F39)', () => {
  for (const origin of [undefined, 'https://chipat-neko.github.io', 'https://evil.example.com']) {
    const h = corsHeaders(reqWithOrigin(origin));
    assertEquals(h['Access-Control-Allow-Origin'] === '*', false);
  }
});

Deno.test('corsHeaders : origine prod autorisée renvoyée telle quelle', () => {
  const h = corsHeaders(reqWithOrigin('https://chipat-neko.github.io'));
  assertEquals(h['Access-Control-Allow-Origin'], 'https://chipat-neko.github.io');
  assertEquals(h['Vary'], 'Origin');
});

Deno.test('corsHeaders : localhost avec port autorisé (dev web)', () => {
  const h = corsHeaders(reqWithOrigin('http://localhost:8080'));
  assertEquals(h['Access-Control-Allow-Origin'], 'http://localhost:8080');
});

Deno.test('corsHeaders : origine inconnue -> pas d\'écho', () => {
  const h = corsHeaders(reqWithOrigin('https://evil.example.com'));
  // Jamais l'origine du tiers : le navigateur bloquera la lecture.
  assertNotEquals(h['Access-Control-Allow-Origin'], 'https://evil.example.com');
  assertEquals(h['Access-Control-Allow-Origin'], ALLOWED_ORIGINS[0]);
});

Deno.test('corsHeaders : un préfixe du domaine prod ne suffit pas', () => {
  const h = corsHeaders(reqWithOrigin('https://chipat-neko.github.io.evil.com'));
  assertEquals(h['Access-Control-Allow-Origin'], ALLOWED_ORIGINS[0]);
});

Deno.test('corsHeaders : sans en-tête Origin (mobile/desktop) -> réponse valide', () => {
  // Un client natif n'envoie pas d'Origin et n'est pas soumis au CORS :
  // la restriction ne doit pas casser ce flux (en-têtes bien formés,
  // méthode POST toujours annoncée).
  const h = corsHeaders(reqWithOrigin());
  assertEquals(h['Access-Control-Allow-Origin'], ALLOWED_ORIGINS[0]);
  assertEquals(h['Access-Control-Allow-Methods'], 'POST, OPTIONS');
});

Deno.test('corsHeaders : préflight accepte les en-têtes du client Supabase', () => {
  const h = corsHeaders(reqWithOrigin('https://chipat-neko.github.io'));
  for (const name of ['authorization', 'x-client-info', 'apikey', 'content-type']) {
    assertEquals(h['Access-Control-Allow-Headers'].includes(name), true, name);
  }
});
