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
