/// Compteur conformite temps de conduite continue (carte #327).
/// Code des transports : 4h30 de conduite = pause 45 min obligatoire.
/// On compte le temps "en route" (entre 2 stops, hors pause auto
/// deja detectee par PauseAutoService).
class DrivingTimeCompliance {
  DrivingTimeCompliance._();

  static const Duration maxContinuous = Duration(hours: 4, minutes: 30);
  static const Duration warningBefore = Duration(minutes: 15);
  static const Duration minPause = Duration(minutes: 45);

  /// Etat actuel : on est en alerte si elapsed >= 4h15.
  static DrivingComplianceState evaluate({
    required Duration elapsedSinceLastPause,
  }) {
    if (elapsedSinceLastPause >= maxContinuous) {
      return DrivingComplianceState.overdue;
    }
    if (elapsedSinceLastPause >= maxContinuous - warningBefore) {
      return DrivingComplianceState.warning;
    }
    return DrivingComplianceState.ok;
  }

  /// True si une pause prise est suffisante pour reset le compteur.
  static bool isPauseSufficient(Duration pauseDuration) =>
      pauseDuration >= minPause;

  /// Phrase TTS pour vocaliser via le FAB mains-libres (#273).
  static String? ttsForState(DrivingComplianceState s) {
    switch (s) {
      case DrivingComplianceState.warning:
        return 'Attention, 4 heures de conduite. Pause obligatoire dans 15 minutes.';
      case DrivingComplianceState.overdue:
        return 'Pause obligatoire dépassée. Trouve un endroit pour t\'arrêter 45 minutes.';
      case DrivingComplianceState.ok:
        return null;
    }
  }
}

enum DrivingComplianceState { ok, warning, overdue }
