// Tests de la function `cron_lockout_revoked` (audit 2026-06-11).
import {
  assertEquals,
} from 'https://deno.land/std@0.208.0/assert/mod.ts';
import { timingSafeEqual } from '../cron_lockout_revoked/lib.ts';

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
