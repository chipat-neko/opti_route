// Unités pures de la function `cron_lockout_revoked`, extraites
// d'index.ts pour être testables (audit 2026-06-11, tests dans
// supabase/functions/_tests/cron_lockout_test.ts).

// Comparaison à temps constant (durcissement sécu nuit 2026-06-01).
// Une comparaison `a !== b` standard court-circuite au premier octet
// différent : le temps de réponse révèle combien de caractères de tête
// sont corrects, ce qui permet de reconstituer le CRON_SECRET octet par
// octet (timing attack). On XOR tous les octets pour un temps constant.
export function timingSafeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  if (ea.length !== eb.length) return false;
  let diff = 0;
  for (let i = 0; i < ea.length; i++) {
    diff |= ea[i] ^ eb[i];
  }
  return diff === 0;
}

// ── CORS : AUCUNE origine autorisée (F39) ────────────────────────────
// Remplace l'ancien `Access-Control-Allow-Origin: *`. Cette function est
// appelée par pg_cron côté serveur (`net.http_post`, cf en-tête
// d'index.ts) : aucune page web ne l'appelle, ni l'app (aucune référence
// à `cron_lockout_revoked` dans app/lib/). Elle n'a donc besoin
// d'AUCUNE origine autorisée, et on ne renvoie plus du tout
// d'`Access-Control-Allow-Origin` : un navigateur ne peut plus lire la
// réponse, quelle que soit l'origine de la page.
//
// Les clients non-navigateur (pg_cron, curl, tests manuels en ligne de
// commande) ignorent totalement le CORS : le flux cron n'est pas
// impacté. On garde Allow-Methods / Allow-Headers pour documenter le
// contrat de l'endpoint, mais attention : sans
// `Access-Control-Allow-Origin` un préflight NAVIGATEUR échoue
// désormais, quelle que soit l'origine. C'est voulu (aucun appel
// navigateur n'est supporté), ce n'est donc PAS un comportement OPTIONS
// inchangé. Pas de `Vary: Origin` non plus : la réponse ne dépend plus
// de l'Origin.
export const PREFLIGHT_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Headers': 'x-cron-secret, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
