import '../utils/text_normalize.dart';

/// Commande vocale reconnue par le mode mains-libres (carte #273).
/// Resultat de [VoiceCommandParser.parse] sur une transcription brute
/// venue de speech_to_text.
enum VoiceCommand {
  /// "livré", "ok livré", "c'est livré", "j'ai livré"
  livre,

  /// "échec", "echec absent", "personne", "absent"
  echec,

  /// "passer", "passe", "skip", "suivant"
  passer,

  /// "stop", "annuler", "arrête"
  stop,

  /// Aucun motif reconnu dans la transcription.
  unknown,
}

/// Parse une transcription STT brute (texte libre francais) en une
/// commande [VoiceCommand]. Pure, deterministe, testable.
///
/// Strategie : matching keyword-first sur des mots-cles francais
/// frequents, sans recourir a un LLM (zero cle / quota). Tolerant aux
/// variantes courantes :
/// - accents optionnels ("livre" / "livré")
/// - ponctuation/casse ignorees
/// - mots de remplissage ignores ("c'est livré", "ok livré")
///
/// Ordre de priorite : `stop` > `echec` > `livre` > `passer` >
/// `unknown`. `stop` est prioritaire pour permettre d'annuler une
/// commande en cours par "stop" meme si on a dit "ok livré stop".
class VoiceCommandParser {
  VoiceCommandParser._();

  static VoiceCommand parse(String transcript) {
    if (transcript.isEmpty) return VoiceCommand.unknown;
    // normalizeText : minuscules + trim + repli des accents. Garde les
    // espaces internes et la ponctuation, dont _containsWord se sert
    // comme delimiteurs de mots.
    final t = normalizeText(transcript);

    if (_containsWord(t, _stopWords)) return VoiceCommand.stop;
    if (_containsWord(t, _echecWords)) return VoiceCommand.echec;
    if (_containsWord(t, _livreWords)) return VoiceCommand.livre;
    if (_containsWord(t, _passerWords)) return VoiceCommand.passer;
    return VoiceCommand.unknown;
  }

  /// True si la chaine [haystack] contient au moins un des mots-cles
  /// de [needles] comme MOT ENTIER (delimite par espaces/ponctuation
  /// /debut/fin de chaine). Evite que "passer" ne matche "depasser".
  static bool _containsWord(String haystack, List<String> needles) {
    for (final n in needles) {
      final i = haystack.indexOf(n);
      if (i < 0) continue;
      final before = i == 0 ? ' ' : haystack[i - 1];
      final afterIdx = i + n.length;
      final after =
          afterIdx >= haystack.length ? ' ' : haystack[afterIdx];
      if (_isWordBoundary(before) && _isWordBoundary(after)) return true;
    }
    return false;
  }

  static bool _isWordBoundary(String c) => !_wordChars.contains(c);

  static const _wordChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

  static const List<String> _livreWords = [
    'livre',
    'livree',
    'delivre',
    'depose',
  ];
  static const List<String> _echecWords = [
    'echec',
    'absent',
    'absente',
    'refuse',
    'refusee',
    'rate',
    'manque',
  ];
  static const List<String> _passerWords = [
    'passer',
    'passe',
    'skip',
    'suivant',
    'sauter',
    'saute',
  ];
  static const List<String> _stopWords = [
    'stop',
    'annule',
    'annuler',
    'arrete',
    'arreter',
    'cancel',
  ];
}
