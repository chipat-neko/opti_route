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
