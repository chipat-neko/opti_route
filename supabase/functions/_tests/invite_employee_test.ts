// Tests des unités pures de la function `invite_employee`
// (audit 2026-06-11).
import {
  assert,
  assertEquals,
  assertMatch,
  assertStringIncludes,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';
import {
  buildEmailHtml,
  escapeHtml,
  genCode,
  roleLabel,
  validateBody,
} from '../invite_employee/lib.ts';

const kUuid = '123e4567-e89b-12d3-a456-426614174000';

Deno.test('validateBody : body valide normalisé (email lowercase + trim)', () => {
  const r = validateBody({
    email: '  Noah.Trillon@Example.COM ',
    entreprise_id: kUuid,
    entrepot_id: null,
    role: 'employe',
  });
  assert(typeof r !== 'string');
  assertEquals(r.email, 'noah.trillon@example.com');
  assertEquals(r.entrepot_id, null);
});

Deno.test('validateBody : rejets', () => {
  assertEquals(validateBody(null), 'Body must be JSON object');
  assertEquals(validateBody('x'), 'Body must be JSON object');
  assertEquals(
    validateBody({ email: 'pas-un-email', entreprise_id: kUuid, entrepot_id: null, role: 'employe' }),
    'Invalid email',
  );
  assertEquals(
    validateBody({ email: 'a@b.fr', entreprise_id: 'court', entrepot_id: null, role: 'employe' }),
    'Invalid entreprise_id (expected UUID)',
  );
  assertEquals(
    validateBody({ email: 'a@b.fr', entreprise_id: kUuid, entrepot_id: 42, role: 'employe' }),
    'Invalid entrepot_id (expected UUID or null)',
  );
  assertEquals(
    validateBody({ email: 'a@b.fr', entreprise_id: kUuid, entrepot_id: null, role: 'admin' }),
    'Invalid role (expected chef_entrepot or employe)',
  );
});

Deno.test('genCode : 6 chiffres zéro-paddés, codes variés (CSPRNG)', () => {
  const seen = new Set<string>();
  for (let i = 0; i < 200; i++) {
    const c = genCode();
    assertMatch(c, /^\d{6}$/);
    seen.add(c);
  }
  // 200 tirages CSPRNG sur 1M de codes : collision quasi impossible,
  // un set quasi plein détecte un générateur cassé (toujours pareil).
  assert(seen.size > 190, `seulement ${seen.size} codes distincts sur 200`);
});

Deno.test('roleLabel : libellés FR', () => {
  assertEquals(roleLabel('chef_entrepot'), "chef d'entrepôt");
  assertEquals(roleLabel('employe'), 'employé');
});

Deno.test('escapeHtml : neutralise les balises', () => {
  assertEquals(
    escapeHtml('<script>alert("x")&co'),
    '&lt;script&gt;alert("x")&amp;co',
  );
});

Deno.test('buildEmailHtml : contient le code + entreprise échappée', () => {
  const html = buildEmailHtml({
    entrepriseNom: 'Trans<b>Port & Co',
    entrepotNom: null,
    role: 'employe',
    code: '042137',
  });
  assertStringIncludes(html, '042137');
  // Le nom est échappé : pas de <b> brut injectable dans le mail.
  assertStringIncludes(html, 'Trans&lt;b&gt;Port &amp; Co');
  assertEquals(html.includes('Trans<b>Port'), false);
  assertStringIncludes(html, 'employé');
});

Deno.test('buildEmailHtml : entrepôt mentionné quand fourni', () => {
  const html = buildEmailHtml({
    entrepriseNom: 'ACME',
    entrepotNom: 'Chartres Nord',
    role: 'chef_entrepot',
    code: '000001',
  });
  assertStringIncludes(html, 'entrepôt Chartres Nord');
  assertStringIncludes(html, "chef d'entrepôt");
});
