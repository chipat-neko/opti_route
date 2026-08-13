// Tests de la function `cron_lockout_revoked` (audit 2026-06-11).
import {
  assertEquals,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';
import {
  PREFLIGHT_HEADERS,
  timingSafeEqual,
} from '../cron_lockout_revoked/lib.ts';

Deno.test('timingSafeEqual : égalité stricte', () => {
  assertEquals(timingSafeEqual('secret-123', 'secret-123'), true);
  assertEquals(timingSafeEqual('', ''), true);
});

Deno.test('timingSafeEqual : différence sur un seul octet', () => {
  assertEquals(timingSafeEqual('secret-123', 'secret-124'), false);
  assertEquals(timingSafeEqual('Xecret-123', 'secret-123'), false);
});

Deno.test('timingSafeEqual : longueurs différentes', () => {
  assertEquals(timingSafeEqual('secret', 'secret-123'), false);
  assertEquals(timingSafeEqual('secret-123', ''), false);
});

Deno.test('timingSafeEqual : unicode multi-octets', () => {
  assertEquals(timingSafeEqual('clé-éèà', 'clé-éèà'), true);
  assertEquals(timingSafeEqual('clé-éèà', 'cle-eea'), false);
});

// ── CORS : aucune origine autorisée (F39) ────────────────────────────
// La function est appelée par pg_cron (net.http_post), jamais par un
// navigateur : plus d'`Access-Control-Allow-Origin`, ni `*` ni écho.

Deno.test('PREFLIGHT_HEADERS : aucun Access-Control-Allow-Origin', () => {
  const names = Object.keys(PREFLIGHT_HEADERS).map((k) => k.toLowerCase());
  assertEquals(names.includes('access-control-allow-origin'), false);
  // Et surtout plus de wildcard nulle part dans les valeurs.
  assertEquals(Object.values(PREFLIGHT_HEADERS).includes('*'), false);
});

Deno.test('PREFLIGHT_HEADERS : contrat POST + x-cron-secret annoncé', () => {
  // La méthode et l'en-tête du secret cron restent annoncés (contrat de
  // l'endpoint). En revanche, faute d'Access-Control-Allow-Origin, un
  // préflight NAVIGATEUR échoue désormais : voulu, seul pg_cron (ou
  // curl, qui ignore le CORS) appelle cette function.
  assertEquals(PREFLIGHT_HEADERS['Access-Control-Allow-Methods'], 'POST, OPTIONS');
  assertEquals(
    PREFLIGHT_HEADERS['Access-Control-Allow-Headers'],
    'x-cron-secret, content-type',
  );
});
