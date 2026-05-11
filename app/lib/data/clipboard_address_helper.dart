/// Helpers d'extraction d'adresse depuis le presse-papier ou un texte
/// partage par une app externe (typiquement Google Maps).
///
/// Format typique partage depuis Google Maps :
/// ```
/// Mairie de Chartres
/// 1 Place des Halles, 28000 Chartres, France
/// https://maps.app.goo.gl/abc123
/// ```
///
/// On veut isoler la ligne d'adresse (`1 Place des Halles, 28000
/// Chartres`) en virant le nom du POI (premiere ligne) et l'URL
/// Google.
class ClipboardAddressHelper {
  /// Code postal francais (5 chiffres consecutifs).
  static final _frenchPostcodeRegex = RegExp(r'\b\d{5}\b');

  /// URL de partage Google Maps (court ou long).
  static final _googleMapsUrlRegex = RegExp(
    r'https?://(?:www\.)?(?:maps|goo)\.(?:app\.)?gl[^\s]*|'
    r'https?://(?:www\.)?google\.com/maps[^\s]*',
    caseSensitive: false,
  );

  /// Mots-cles courants de voie francaise.
  static const _streetKeywords = [
    'rue', 'avenue', 'boulevard', 'av.', 'bd', 'impasse', 'place',
    'chemin', 'route', 'allee', 'allée', 'voie', 'cours', 'quai',
    'passage', 'faubourg', 'fbg', 'rte',
  ];

  /// Vrai si `text` ressemble a une adresse francaise (contient un CP
  /// OU un mot-cle de voie OU le mot "France"). Heuristique large pour
  /// minimiser les faux negatifs : on prefere proposer "coller" a tort
  /// (l'utilisateur peut ignorer) que rater une vraie adresse.
  static bool looksLikeAddress(String text) {
    if (text.trim().isEmpty) return false;
    if (_frenchPostcodeRegex.hasMatch(text)) return true;
    final lower = text.toLowerCase();
    if (lower.contains('france')) return true;
    for (final kw in _streetKeywords) {
      // On cherche le mot-cle entoure d'espaces / debut de ligne pour
      // eviter de matcher "BoutiqueRue" par exemple.
      final pattern = RegExp(r'(?:^|\s)' + RegExp.escape(kw) + r'\s',
          caseSensitive: false);
      if (pattern.hasMatch(' $lower ')) return true;
    }
    return false;
  }

  /// Extrait une adresse propre depuis le texte du presse-papier.
  ///
  /// Strategie :
  /// 1. Retire les URLs Google Maps.
  /// 2. Cherche la ligne contenant un CP francais : c'est l'adresse
  ///    la plus probable.
  /// 3. Si pas de CP trouve mais texte court et contient un mot-cle
  ///    rue : on prend tout le texte (sans les URLs).
  /// 4. Sinon retourne null (l'utilisateur fera la saisie manuelle).
  ///
  /// Toujours `trim()` le resultat.
  static String? extractAddress(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;

    // Etape 1 : virer les URLs Google Maps.
    text = text.replaceAll(_googleMapsUrlRegex, '').trim();
    if (text.isEmpty) return null;

    // Etape 2 : ligne contenant un CP francais.
    final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).toList();
    for (final line in lines) {
      if (_frenchPostcodeRegex.hasMatch(line)) {
        // Si la ligne contient ", France" en fin, on le vire (geocoding
        // BAN est francais, pas besoin du marqueur pays).
        return line.replaceAll(RegExp(r',?\s*France\s*$'), '').trim();
      }
    }

    // Etape 3 : pas de CP -- fallback si l'unique ligne est courte et
    // ressemble a une adresse.
    if (lines.length <= 3 && looksLikeAddress(text) && text.length <= 200) {
      // Concatene les lignes restantes pour avoir une string propre.
      return lines.where((l) => l.isNotEmpty).join(', ');
    }

    return null;
  }
}
