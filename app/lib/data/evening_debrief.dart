/// Debrief vocal fin de tournée (carte #318) : 5 questions guidées
/// TTS+STT pour récolter à chaud les "micro-infos" qui s'évaporent
/// (changement code interphone, gardien sympa, nouveau chien, etc.).
///
/// Pure fn : compose les questions + parse une réponse texte STT
/// pour décider si elle doit être pushée comme `memoVocal` sur un stop.
class EveningDebrief {
  EveningDebrief._();

  /// Génère les 5 questions à poser au pointage fin service.
  /// Indépendant du contexte tournée pour rester pure.
  static List<DebriefQuestion> questions({
    required int echecsCount,
    required int sansContactCount,
  }) {
    return [
      const DebriefQuestion(
        id: 'rues_difficiles',
        prompt:
            'Y a-t-il des rues ou des adresses qui t\'ont posé problème '
            'aujourd\'hui ?',
      ),
      const DebriefQuestion(
        id: 'codes_changes',
        prompt:
            'Est-ce qu\'un code interphone a changé ? Dis "non" si rien.',
      ),
      if (echecsCount > 0)
        const DebriefQuestion(
          id: 'echec_recidive',
          prompt:
              'Un client absent à recontacter en priorité demain ?',
        ),
      if (sansContactCount > 0)
        const DebriefQuestion(
          id: 'depot_safe',
          prompt:
              'Les dépôts sans contact se sont-ils bien passés ?',
        ),
      const DebriefQuestion(
        id: 'meteo_ressenti',
        prompt:
            'Comment était la journée ? Stress, fatigue ou tout va bien ?',
      ),
    ];
  }

  /// Détecte si une transcription STT est "rien à signaler" (skip).
  /// Tolère "non", "rien", "pas de soucis", etc.
  static bool isNothingToReport(String transcript) {
    final t = transcript.trim().toLowerCase();
    if (t.isEmpty) return true;
    const skipPatterns = [
      'non',
      'rien',
      'pas de souci',
      'pas de probleme',
      'pas de problème',
      'rien a signaler',
      'tout va bien',
      'tout ok',
      'rien de special',
    ];
    return skipPatterns.any(t.contains);
  }
}

class DebriefQuestion {
  const DebriefQuestion({required this.id, required this.prompt});
  final String id;
  final String prompt;
}
