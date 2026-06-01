import 'dart:math' show Random;

/// ════════════════════════════════════════════════════════════════
/// Helpers purs partages par les services de sync cloud.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `cloud_sync_service.dart` (carte Trello #167, etape 1).
/// Aucune dependance a Supabase / Drift -- juste de la logique pure
/// (parsing timestamps, comparaison last-write-wins, generation +
/// traduction des codes d'invitation). Testable sans device.

final _invitationRandom = Random.secure();

/// Genere un code d'invitation a 6 chiffres uniformes (000000-999999)
/// via Random.secure (CSPRNG). Le formatage garde les leading zeros :
/// 47 -> "000047".
///
/// Cf fix bugs jalons 2.D-1c->3.A : l'ancienne implementation basee
/// sur DateTime.now() XOR DateTime.now() renvoyait quasi-toujours 0
/// (les 2 timestamps sont presque identiques), et le retry collision
/// generait le meme code (microsecondes d'ecart).
String generateInvitationCode() {
  final n = _invitationRandom.nextInt(1000000);
  return n.toString().padLeft(6, '0');
}

/// Traduit un message d'erreur technique d'invitation en FR lisible
/// pour l'UI (SnackBar). Les sentinelles (AUTH_REQUIRED, etc.) sont
/// levees par les Edge Functions / RPC Supabase.
String invitationErrorToFr(String raw) {
  if (raw.contains('AUTH_REQUIRED')) {
    return 'Connecte-toi d\'abord (Parametres > Compte cloud).';
  }
  if (raw.contains('CODE_INTROUVABLE')) {
    return 'Ce code n\'existe pas. Verifie avec ton chef.';
  }
  if (raw.contains('CODE_EXPIRE')) {
    return 'Ce code a expire (plus de 24h). Demande un nouveau code.';
  }
  if (raw.contains('CODE_DEJA_UTILISE')) {
    return 'Ce code a deja ete utilise. Demande un nouveau code.';
  }
  if (raw.contains('EMAIL_MISMATCH')) {
    return 'Cette invitation a ete envoyee a une autre adresse email. '
        'Connecte-toi avec l\'adresse qui a recu l\'invitation.';
  }
  return 'Echec acceptation invitation : $raw';
}

/// Parse le champ `updated_at` envoye par Postgres dans le format
/// timestamptz ISO 8601 (ex: `2026-05-16T14:23:45.123+00:00`).
///
/// Fallback `DateTime.fromMillisecondsSinceEpoch(0)` si le champ est
/// null (cas anormal : un push 2.D-1c+ doit toujours envoyer
/// updated_at, mais le schema cloud autorise NULL pour retro-compat
/// avec d'eventuels rows pushes par une vieille version de l'app).
/// Un row sans updated_at est traite comme "infiniment ancien" et
/// sera ecrase par n'importe quel local non-NULL.
DateTime parseCloudUpdatedAt(Object? raw) {
  if (raw is String) {
    return DateTime.parse(raw).toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// True si la version cloud est strictement plus recente que la
/// version locale (donc on doit ecraser local). False sinon (egalite
/// ou local plus recent -> skip pour preserver les modifs locales).
///
/// Tolerance de 1 seconde sur l'egalite : Postgres stocke en
/// microsecondes, SQLite Drift stocke en secondes (truncate). Sans
/// tolerance, un push immediatement suivi d'un pull verrait
/// `cloud.updated_at = floor(local.updated_at) <= local.updated_at`
/// et skip — c'est OK ici puisqu'on push avec le timestamp local
/// brut, mais si Postgres re-touchait la valeur (trigger serveur
/// futur), l'arrondi pourrait creer un faux "cloud plus ancien".
bool cloudIsNewer(DateTime cloud, DateTime local) {
  return cloud.isAfter(local.add(const Duration(seconds: 1)));
}
