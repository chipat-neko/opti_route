/// Types possibles d'une recherche d'adresse. Permet a la cascade
/// `FranceGeocodingService` de choisir l'ordre optimal des sources
/// selon ce que Noah tape.
enum QueryType {
  /// 14 chiffres consecutifs (espaces / tirets toleres). Court-
  /// circuit direct vers SIRENE.
  siret,

  /// 9 chiffres consecutifs. Court-circuit direct vers SIRENE.
  siren,

  /// 10 chiffres commencant par 0, ou + indicatif. Pas exploite pour
  /// l'instant (skip vers la cascade standard) -- futur : recherche
  /// par tel dans SIRENE.
  phone,

  /// Commence par un nombre + texte : "14 Rue de la Paix" ou
  /// "3bis Boulevard Voltaire". -> cascade BAN d'abord.
  address,

  /// 1-2 mots courts sans chiffres, longueur <= 25 caracteres. Plutot
  /// un nom de ville ("Chartres", "Saint-Etienne") -> cascade BAN
  /// d'abord (type municipality + adresses).
  locality,

  /// Plusieurs mots, ou presence de majuscules, ou keyword commerce
  /// ("SAS", "SARL", "EI", etc.). -> cascade SIRENE d'abord.
  business,

  /// Pas pu trancher (query courte / ambigue). -> cascade standard
  /// (comportement par defaut historique).
  unknown,
}

class QueryTypeDetector {
  const QueryTypeDetector._();

  /// Heuristique pour categoriser la query saisie par Noah.
  ///
  /// L'ordre des checks compte : on prend la categorie la plus
  /// specifique en 1er (SIRET, SIREN, phone), puis on derive du
  /// pattern lexical (commence par chiffre = adresse, court = ville,
  /// long ou MAJ = entreprise).
  static QueryType detect(String query) {
    final q = query.trim();
    if (q.isEmpty) return QueryType.unknown;
    if (q.length < 2) return QueryType.unknown;

    // 1. Identifiants numeriques officiels (SIRET / SIREN). On tolere
    //    espaces, tirets, prefixe textuel.
    final digitsOnly = q.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 14) return QueryType.siret;
    if (digitsOnly.length == 9) return QueryType.siren;

    // 2. Telephone FR : 10 chiffres commencant par 0, ou +33 + 9
    //    chiffres. Heuristique simple, on vise pas l'exhaustivite.
    if (digitsOnly.length == 10 && digitsOnly.startsWith('0')) {
      // Mais on doit etre sur que c'est *que* des chiffres (sinon on
      // capturerait "14 rue 75002 Paris" en faux positif). On verifie
      // que la query brute est essentiellement numerique.
      if (RegExp(r'^[\d\s.\-+]+$').hasMatch(q)) return QueryType.phone;
    }
    if (digitsOnly.length == 11 && digitsOnly.startsWith('33')) {
      if (RegExp(r'^[\d\s.\-+]+$').hasMatch(q)) return QueryType.phone;
    }

    // 3. Commence par un chiffre + espace ou suffixe (bis/ter) : c'est
    //    typiquement un numero de rue. Ex: "14 Rue", "3bis Bd".
    if (RegExp(r'^\s*\d+\s*(?:bis|ter|quater)?\s+\S',
            caseSensitive: false)
        .hasMatch(q)) {
      return QueryType.address;
    }

    // 4. Locality : 1-2 mots, courts, sans chiffres ni MAJ-MAJ
    //    consecutives, longueur totale <= 25. "Chartres",
    //    "Saint-Etienne", "Aix en Provence".
    final words = q.split(RegExp(r'\s+'));
    final hasDigit = RegExp(r'\d').hasMatch(q);
    if (!hasDigit &&
        words.length <= 3 &&
        q.length <= 25 &&
        !_looksLikeBusinessName(q)) {
      return QueryType.locality;
    }

    // 5. Business : signaux commerce (forme juridique, MAJ
    //    consecutives, plus de 3 mots, ou plus de 25 caracteres).
    if (_looksLikeBusinessName(q) || words.length > 3 || q.length > 25) {
      return QueryType.business;
    }

    return QueryType.unknown;
  }

  /// Heuristique "nom d'entreprise" : presence d'une forme juridique
  /// dans la query, ou de plusieurs mots tous en MAJUSCULES.
  static bool _looksLikeBusinessName(String q) {
    final upper = q.toUpperCase();
    const formes = [
      'SAS', 'SARL', 'SA ', 'EURL', 'SCI', 'SCP', 'SELARL', 'SNC',
      'EI ', 'GIE', 'GFA', ' & CIE', 'SASU',
    ];
    for (final f in formes) {
      // Ajoute des espaces pour eviter "SAS" qui matche "BASSE".
      if (upper.contains(' $f') ||
          upper.startsWith(f) ||
          upper.endsWith(' ${f.trim()}')) {
        return true;
      }
    }
    // 2+ mots en MAJUSCULES consecutifs : "GARAGE DUPONT", "ATELIER
    // MENUISERIE", etc. typique des noms d'entreprises.
    final consecutiveUpper = RegExp(
            r'\b[A-Z][A-Z\-]{2,}\s+[A-Z][A-Z\-]{2,}\b')
        .hasMatch(q);
    return consecutiveUpper;
  }
}
