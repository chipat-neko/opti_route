/// Logique pure du rappel "tournee non terminee" (carte #121).
///
/// Une tournee qui reste en `en_cours` trop longtemps apres son
/// demarrage est probablement un oubli de cloture (ou un crash). On
/// programme une notification locale a `demareeLe + seuil` au moment du
/// demarrage, qu'on annule a la mise en pause / cloture.
///
/// Isole ici (sans dependance au plugin de notifications) pour rester
/// testable sans plateforme.
class TourneeReminderPlan {
  TourneeReminderPlan._();

  /// Au-dela de cette duree depuis le demarrage, on rappelle a Noah de
  /// cloturer la tournee. 8h = une grosse journee de livraison.
  static const Duration seuil = Duration(hours: 8);

  /// Heure a laquelle declencher le rappel pour une tournee demarree a
  /// [demareeLe]. Null si la tournee n'a pas de timestamp de demarrage
  /// (pas encore demarree -> rien a programmer).
  static DateTime? reminderAt(DateTime? demareeLe, {Duration? seuil}) {
    if (demareeLe == null) return null;
    return demareeLe.add(seuil ?? TourneeReminderPlan.seuil);
  }

  /// Vrai si une tournee demarree a [demareeLe] est consideree "en
  /// retard" a l'instant [now] (utile pour un check synchrone / un futur
  /// bandeau). False si jamais demarree.
  static bool isOverdue({
    required DateTime? demareeLe,
    required DateTime now,
    Duration? seuil,
  }) {
    final at = reminderAt(demareeLe, seuil: seuil);
    if (at == null) return false;
    return !now.isBefore(at);
  }
}
