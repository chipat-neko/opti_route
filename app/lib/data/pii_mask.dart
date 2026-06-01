// Helpers de masquage de données personnelles (PII) pour l'affichage.
//
// Fonctions PURES (pas de dépendance Flutter) -> testables. Servent à
// ne JAMAIS exposer une donnée personnelle complète dans un écran
// susceptible d'être capturé/partagé (ex: écran Diagnostic copié au
// support). Cf RGPD + audit sécu nuit 2026-06-01.

/// Masque le milieu d'un email : `lucas@gmail.com` -> `l***@gmail.com`.
///
/// Garanties (verrouillées par tests) :
/// - null / vide -> `—` (rien à révéler).
/// - partie locale d'1 seul caractère (ou email commençant par `@`, ou
///   sans `@`) -> AUCUN caractère de la partie locale n'est révélé
///   (`***` + domaine si présent).
/// - sinon : seule la 1re lettre de la partie locale est révélée, suivie
///   de `***` puis du domaine (le domaine n'est pas un secret).
String maskEmailForDisplay(String? email) {
  if (email == null || email.isEmpty) return '—';
  final at = email.indexOf('@');
  if (at <= 1) return '***${at >= 0 ? email.substring(at) : ''}';
  return '${email[0]}***${email.substring(at)}';
}

/// Masque les secrets susceptibles d'apparaître dans une exception/log
/// brut(e) avant affichage utilisateur :
/// - JWT (`eyJ...` en 3 segments base64url) -> token de session, le plus
///   dangereux (vol de session via capture d'écran).
/// - en-tête `Bearer <token>` / `apikey=<...>` / `access_token=<...>`.
///
/// Défensif : si rien ne matche, la chaîne est renvoyée inchangée. Cf
/// audit sécurité nuit 2026-06-01 (information disclosure). Fonction PURE,
/// partagée par le humanizer cloud ET les helpers de sync (qui doivent
/// rester sans dépendance Supabase).
String scrubSecrets(String input) {
  var out = input;
  // JWT : 3 segments base64url separes par des points. On masque tout.
  out = out.replaceAll(
    RegExp(r'eyJ[A-Za-z0-9_=-]+\.[A-Za-z0-9_=-]+\.[A-Za-z0-9_=.-]*'),
    '***',
  );
  // Bearer <token>
  out = out.replaceAll(
    RegExp(r'[Bb]earer\s+[A-Za-z0-9._~+/=-]+'),
    'Bearer ***',
  );
  // apikey=... / access_token=... / refresh_token=... dans une URL/query
  out = out.replaceAll(
    RegExp(
      r'(apikey|access_token|refresh_token|token)=[A-Za-z0-9._~+/=-]+',
      caseSensitive: false,
    ),
    r'$1=***',
  );
  return out;
}
