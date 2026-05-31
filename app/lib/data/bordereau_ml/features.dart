/// Extraction de features ML pour une ligne OCR.
///
/// **Mirroir exact** de `tools/train_classifier.py::compute_features`.
/// Toute modification ici doit etre repercutee la-bas (et inversement)
/// sinon le modele ONNX/JSON exporte produira des predictions fausses.
///
/// Ordre des features (= `FEATURE_NAMES` dans le JSON) :
///   0  length
///   1  n_words
///   2  pct_upper        (% MAJ sur les lettres)
///   3  pct_digit        (% chiffres sur la longueur totale)
///   4  pct_punct
///   5  has_digit
///   6  has_at_sign
///   7  starts_digit
///   8  ends_digit
///   9  n_digits
///   10 has_cp5          (code postal 5 chiffres)
///   11 has_tel_kw
///   12 has_phone
///   13 has_rue_kw
///   14 has_ref_kw
///   15 has_parasite_kw
///   16 relY            (position verticale relative dans le bordereau)
///   17 relX            (position horizontale relative)
///   18 block_height
///   19 block_width
library;

const List<String> kTelKw = ['tel', 'tél', 'port', 'mob', 'fax', 'gsm'];

const List<String> kRueKw = [
  'rue', 'avenue', 'av.', 'bd', 'boulevard', 'impasse', 'imp.',
  'chemin', 'route', 'rte', 'allee', 'allée', 'place', 'pl.',
  'rn', 'rd', 'zone', 'za', 'zi', 'cours', 'quai',
];

const List<String> kRefKw = ['fa ', 'ref', 'tracking', 'n°', 'numero', 'numéro'];

const List<String> kParasiteKw = [
  'destinataire', 'ramasse', 'transporteur', 'expediteur', 'expéditeur',
  'colis', 'poids', 'regime', 'régime', 'instruction', 'fragile',
  'signature', 'date', 'heure', 'page',
];

const String _punct = '.,;:!?-()[]{}/\\|@#&%*+=<>"\'';

final RegExp _cpPattern = RegExp(r'\b\d{5}\b');
final RegExp _phonePattern = RegExp(
    r'(?:\+?33|0)\s?[1-9](?:[\s.-]?\d{2}){4}',
);

/// Calcule le vecteur de features pour une ligne OCR.
///
/// [relY] / [relX] sont des ratios dans [0, 1] (top/max_top et
/// left/max_left dans l'image). [blockHeight] / [blockWidth] sont en
/// pixels bruts (proxy taille texte).
List<double> computeFeatures({
  required String text,
  required double relY,
  required double relX,
  required double blockHeight,
  required double blockWidth,
}) {
  final t = text;
  final tl = t.toLowerCase();
  final length = t.length;
  final words = t.trim().isEmpty ? <String>[] : t.split(RegExp(r'\s+'));
  final nWords = words.length;

  int upperLetters = 0;
  int letters = 0;
  int digits = 0;
  int punct = 0;
  for (final c in t.runes) {
    final ch = String.fromCharCode(c);
    if (_isLetter(ch)) {
      letters++;
      if (_isUpperLetter(ch)) upperLetters++;
    } else if (_isDigit(ch)) {
      digits++;
    } else if (_punct.contains(ch)) {
      punct++;
    }
  }

  final pctUpper = letters > 0 ? upperLetters / letters : 0.0;
  final pctDigit = length > 0 ? digits / length : 0.0;
  final pctPunct = length > 0 ? punct / length : 0.0;

  final firstChar = t.isEmpty ? '' : t.substring(0, 1);
  final lastChar = t.isEmpty ? '' : t.substring(t.length - 1);

  return [
    length.toDouble(),
    nWords.toDouble(),
    pctUpper,
    pctDigit,
    pctPunct,
    digits > 0 ? 1.0 : 0.0,
    t.contains('@') ? 1.0 : 0.0,
    _isDigit(firstChar) ? 1.0 : 0.0,
    _isDigit(lastChar) ? 1.0 : 0.0,
    digits.toDouble(),
    _cpPattern.hasMatch(t) ? 1.0 : 0.0,
    kTelKw.any(tl.contains) ? 1.0 : 0.0,
    _phonePattern.hasMatch(t) ? 1.0 : 0.0,
    kRueKw.any(tl.contains) ? 1.0 : 0.0,
    kRefKw.any(tl.contains) ? 1.0 : 0.0,
    kParasiteKw.any(tl.contains) ? 1.0 : 0.0,
    relY,
    relX,
    blockHeight,
    blockWidth,
  ];
}

bool _isLetter(String c) {
  if (c.isEmpty) return false;
  final code = c.codeUnitAt(0);
  // ASCII a-z A-Z
  return (code >= 0x41 && code <= 0x5A) ||
      (code >= 0x61 && code <= 0x7A) ||
      // Latin-1 supplement accentues (E0-FF sans multiplication/division)
      (code >= 0xC0 && code <= 0xD6) ||
      (code >= 0xD8 && code <= 0xF6) ||
      (code >= 0xF8 && code <= 0xFF);
}

bool _isUpperLetter(String c) {
  if (c.isEmpty) return false;
  final code = c.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5A) ||
      (code >= 0xC0 && code <= 0xD6) ||
      (code >= 0xD8 && code <= 0xDE);
}

bool _isDigit(String c) {
  if (c.isEmpty) return false;
  final code = c.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39;
}
