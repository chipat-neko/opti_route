/// ════════════════════════════════════════════════════════════════
/// Normalisation de texte partagee (F26 volet 2).
/// ════════════════════════════════════════════════════════════════
///
/// Avant ce fichier, sept modules embarquaient chacun leur copie privee
/// d'un `_normalize`, avec des divergences silencieuses : certaines
/// copies depliaient les ligatures `œ`/`æ`, d'autres non ; certaines
/// faisaient un `trim()`, d'autres non ; deux d'entre elles aplatissaient
/// les espaces multiples mais gardaient les accents. Le bug de mojibake
/// corrige en #515 venait exactement de cette derive.
///
/// NB : `RoleService._normalize` porte le meme nom mais n'est PAS un
/// normaliseur de texte (il retourne un `AppRole`, pas une String). Il
/// reste sur place volontairement — ce n'est pas un oubli de migration.
///
/// Deux variantes seulement sont reellement necessaires, et elles ne
/// sont PAS interchangeables :
///
/// - [normalizeText] : minuscules + trim + repli des diacritiques et des
///   ligatures. Pour tout ce qui est confronte a de la saisie humaine
///   (recherche du carnet, filtre des arrets, commandes vocales, fuzzy
///   matching des noms clients).
/// - [normalizeKey] : minuscules + trim + espaces multiples reduits a un
///   seul, mais accents CONSERVES. Pour les cles techniques (cache de
///   geocodage) et la comparaison d'adresses brutes.
///
/// Elles restent separees volontairement :
/// - replier les accents dans [normalizeKey] invaliderait d'un coup
///   toutes les lignes deja ecrites dans `geocode_cache` (la cle est
///   persistee en base) ;
/// - aplatir les espaces dans [normalizeText] changerait le resultat des
///   recherches, ou le foin (`haystack`) est construit en concatenant
///   des champs parfois vides -> des doubles espaces significatifs.
///
/// Les deux fonctions sont pures et sans dependance Flutter.
library;

/// Table de repli caractere -> remplacement ASCII. Couvre le francais
/// (accents, cedille, ligatures `œ`/`æ`) plus quelques voisins
/// espagnols / portugais qui arrivent par les imports de contacts.
///
/// Les ligatures rendent DEUX caracteres (`'œ' -> 'oe'`) : la longueur
/// de la chaine normalisee peut donc differer de celle de l'entree.
const Map<String, String> _folding = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ÿ': 'y', 'ý': 'y',
  'ñ': 'n',
  'œ': 'oe', 'æ': 'ae',
};

/// Suite d'espaces (espace, tabulation, retour ligne...). Compilee une
/// seule fois : [normalizeKey] est appelee dans des boucles O(n^2) du
/// groupage d'arrets.
final RegExp _espacesMultiples = RegExp(r'\s+');

/// Minuscules + trim + repli des diacritiques et des ligatures.
///
/// ```
/// normalizeText('Lucé')      == 'luce'
/// normalizeText('CŒUR')      == 'coeur'
/// normalizeText('  Nogent ') == 'nogent'
/// ```
///
/// Ne touche NI aux espaces internes NI a la ponctuation : les appelants
/// font des `contains` sur des champs concatenes et comptent sur ces
/// separateurs pour delimiter les mots.
String normalizeText(String s) {
  final lower = s.toLowerCase().trim();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(_folding[ch] ?? ch);
  }
  return buf.toString();
}

/// Minuscules + trim + espaces multiples reduits a un seul espace, avec
/// les accents CONSERVES.
///
/// ```
/// normalizeKey('  12 RUE   Aristide  Briand ') == '12 rue aristide briand'
/// normalizeKey('Rue de Lucé')                  == 'rue de lucé'
/// ```
///
/// A utiliser pour les cles stables (cache de geocodage, comparaison
/// d'adresses brutes), PAS pour une recherche utilisateur : voir la doc
/// du module pour la raison du repli d'accents absent ici.
String normalizeKey(String s) =>
    s.trim().toLowerCase().replaceAll(_espacesMultiples, ' ');
