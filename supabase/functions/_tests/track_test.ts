// Tests des unités pures de la function `track` (audit 2026-06-11).
// Lancer : deno test supabase/functions/_tests/
import {
  assertEquals,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';
import {
  coarsenCoord,
  kTrackingCodeRegex,
  pseudonymizeName,
  statusLabel,
} from '../track/lib.ts';

Deno.test('kTrackingCodeRegex : exactement 4 chars [a-z0-9]', () => {
  assertEquals(kTrackingCodeRegex.test('abcd'), true);
  assertEquals(kTrackingCodeRegex.test('a1b2'), true);
  // Trop court = espace de brute-force réduit (audit #176).
  assertEquals(kTrackingCodeRegex.test('abc'), false);
  assertEquals(kTrackingCodeRegex.test('abcde'), false);
  assertEquals(kTrackingCodeRegex.test('ABCD'), false);
  assertEquals(kTrackingCodeRegex.test('ab-d'), false);
  assertEquals(kTrackingCodeRegex.test(''), false);
});

Deno.test('statusLabel : les 3 statuts + fallback', () => {
  assertEquals(statusLabel('livre'), 'Livré');
  assertEquals(statusLabel('echec'), 'Livraison non aboutie');
  assertEquals(statusLabel('a_livrer'), 'En cours de livraison');
  assertEquals(statusLabel('inconnu'), 'En cours de livraison');
});

Deno.test('pseudonymizeName : prénom + initiale (RGPD #176)', () => {
  assertEquals(pseudonymizeName('Jean Dupont'), 'Jean D.');
  assertEquals(pseudonymizeName('Marie-Claire de la Tour'), 'Marie-Claire T.');
  // Un seul mot : renvoyé tel quel.
  assertEquals(pseudonymizeName('GARAGE'), 'GARAGE');
  // L'initiale est mise en majuscule.
  assertEquals(pseudonymizeName('jean dupont'), 'jean D.');
  assertEquals(pseudonymizeName('  Jean   Dupont  '), 'Jean D.');
  assertEquals(pseudonymizeName(null), null);
  assertEquals(pseudonymizeName('   '), null);
});

Deno.test('coarsenCoord : arrondi à ~110 m, null préservé', () => {
  assertEquals(coarsenCoord(48.456789), 48.457);
  assertEquals(coarsenCoord(1.2), 1.2);
  assertEquals(coarsenCoord(-0.0004), -0);
  assertEquals(coarsenCoord(null), null);
});
