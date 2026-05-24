/// Patterns regex partages entre tous les parsers de bordereaux
/// (MESEXP, Chronopost, Colissimo). Centralises ici pour eviter la
/// triple duplication identifiee dans l'audit 2026-05-22 : une regex
/// modifiee dans un parser n'affectait pas les 2 autres.
///
/// Toutes les regex sont `static final` (compiles une fois au 1er acces)
/// et exposees comme membres publics de [BordereauPatterns]. Pas de
/// constructeur : utilisation type `BordereauPatterns.cpRegex`.
abstract final class BordereauPatterns {
  /// CP + ville sur la meme ligne, format flexible :
  /// - `28190 COURVILLE SUR EURE`
  /// - `FR-28190-CHARTRES` (etiquettes France Alliance)
  /// - `FR - 28190 - CHARTRES` (variantes avec espaces)
  ///
  /// Le `\b` en debut evite de matcher au milieu d'un long numero
  /// (cas reel observe : "0237911586 THEODORE CHARTRES" matchait
  /// "11586 THEODORE" sans \b).
  static final cpVilleRegex = RegExp(
    r"\b(\d{5})[\s\-]+([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ\s\-']+)",
  );

  /// CP francais isole (5 chiffres entoures de word boundaries).
  /// Utilise pour les fallbacks quand la ville n'a pas pu etre matchee
  /// sur la meme ligne (OCR fragmente).
  static final cpRegex = RegExp(r'\b(\d{5})\b');

  /// Telephone francais 10 chiffres, tolerant aux separateurs courants
  /// (espace, point, tiret) entre les paires : `06.12.34.56.78`,
  /// `06 12 34 56 78`, `06-12-34-56-78`, `0612345678`.
  static final telRegex = RegExp(
    r'\b(0\d[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2})\b',
  );

  /// Strip les separateurs telephone (apres extraction par [telRegex])
  /// pour stocker en format normalise `0612345678`.
  static final telSepRegex = RegExp(r'[\s.\-]');

  /// Numero de tracking Chronopost : `XR123456789FR` ou `XE123456789FR`.
  /// Sert a detecter le format avant de choisir le parser.
  static final chronopostTrackingRegex = RegExp(
    r'\b[XR][A-Z]\d{9}FR\b',
    caseSensitive: false,
  );

  /// Ligne qui est manifestement une rue numerotee : commence par un
  /// chiffre suivi optionnellement de bis/ter, puis d'un mot de voirie
  /// francais (RUE, AVENUE, BD, etc).
  ///
  /// Sert :
  /// - Au parser pour ignorer les occurrences d'un candidat dans une
  ///   rue (ex: "LOUIS PASTEUR" dans "24 AVENUE LOUIS PASTEUR" est un
  ///   nom de saint, pas un destinataire).
  /// - Au detecteur de rue pour matcher l'adresse extraite.
  static final streetLineRegex = RegExp(
    r"^\d+\s*(?:bis|ter|quater)?\s+(?:RUE|AVENUE|AV\.?|BD|BOULEVARD|CHEMIN|PLACE|IMPASSE|ALL[EÉ]E|VOIE|ROUTE|RTE|QUAI|COURS|PASSAGE|FAUBOURG|FBG)\b",
    caseSensitive: false,
  );

  /// Pattern rue Acceptee comme adresse extraite (avec ALLEE non-accentue
  /// en plus, observe sur certains bordereaux).
  ///
  /// Sprint 2026-05-23 (Noah) : ajout des routes nationales/departementales
  /// "RN \d+" et "RD \d+" (cas reel : "RN 23 AVENUE DE PARIS" doit etre
  /// reconnue comme rue, pas comme nom d'entreprise).
  static final ruePattern = RegExp(
    r"^(?:"
    r"\d+\s*(?:bis|ter|quater)?\s+(?:RUE|AVENUE|AV\.?|BD|BOULEVARD|CHEMIN|PLACE|IMPASSE|ALLEE|ALL[EÉ]E|VOIE|ROUTE|RTE|QUAI|COURS|PASSAGE|FAUBOURG|FBG)"
    r"|"
    r"(?:RN|RD)\s*\d+"
    r")\b",
    caseSensitive: false,
  );

  /// Boite postale en debut de ligne : `BP 12345` ou `BP12345`. Souvent
  /// adjacente a l'adresse rue dans les bordereaux MESEXP.
  static final bpPattern = RegExp(r"^BP\s*\d+", caseSensitive: false);

  /// Label "ENLEVEMENT" en majuscules entoure de word boundaries.
  /// Sert a detecter le format ENLEVEMENT (vs LIVRAISON) du bordereau.
  static final enlevementLabelRegex = RegExp(r'\bENLEVEMENT\b');

  /// Sequence de mots en MAJUSCULES adjacents (>= 2 mots), candidat
  /// typique pour un nom d'entreprise destinataire (ex: "GARAGE
  /// LANCTIN DAMIEN", "GUILLERY MOTOCULTURE").
  static final upperCaseSequenceRegex = RegExp(
    r"([A-Z][A-Z\-']+(?:\s+[A-Z][A-Z\-']+)+)",
  );

  /// CP + ville plus simple (ASCII only, sans accents). Utilise dans
  /// le fallback de [BordereauParser._findReceiverCp].
  static final cpVilleSimpleRegex = RegExp(
    r"(\d{5})\s+([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ\s\-']+)",
  );

  /// Match "total colis : 3" ou "colis: 3" sur la meme ligne (format
  /// LIVRAISON MESEXP / Colissimo).
  ///
  /// Sprint OCR B-3 (2026-05-24) : `[:.\s]+` au lieu de `\s*:?\s*`
  /// pour autoriser separateurs variables ("colis : 3", "colis. 3",
  /// "colis  3"). `(?!\d)` empeche de capturer un prefixe de nombre
  /// plus long (ex CP "28190" -> capturer "281" serait faux).
  static final colisSameLineRegex = RegExp(
    r'(?:total\s+colis|nb\s+colis|colis)\s*[:.\s]+\s*(\d{1,3})(?!\d)',
    caseSensitive: false,
  );

  /// Sprint OCR B-3 (2026-05-24) : cas inverse "COLIS TOTAUX: 1"
  /// observe sur les bordereaux Eure-et-Loir (page_33 / page_34 batch
  /// eval). `colisSameLineRegex` ne match pas car "TOTAUX" s'intercale
  /// entre "colis" et le chiffre.
  static final colisTotauxRegex = RegExp(
    r'colis\s+totaux\s*[:.\s]+\s*(\d{1,3})(?!\d)',
    caseSensitive: false,
  );

  /// Sprint OCR B-3 (2026-05-24) : fallback format ENLEVEMENT MESEXP
  /// avec "UM: 1/3" -> total colis = denominateur. Quand l'OCR ne
  /// retrouve pas un nombre seul dans les 12 lignes apres "u.m.",
  /// on scanne pour ce pattern UM X/Y.
  static final umFractionRegex = RegExp(
    r'\bu\.?\s*m\.?\s*[:.\s]*\s*\d+\s*/\s*(\d+)',
    caseSensitive: false,
  );

  /// Entier ou decimal X.0 isole sur sa ligne, 1-99 (format ENLEVEMENT
  /// U.M. ou la valeur colis est `1`, `1.0`, `2,0`...).
  static final unitColisLineRegex = RegExp(r'^\s*(\d{1,2})(?:[.,]0+)?\s*$');

  /// Match alphanumeric digit-letter adjacent (caracteristique des
  /// codes de tracking type "270521 /6552AGNCMVZ04L"). Sert a rejeter
  /// ces codes du choix de nom destinataire.
  static final trackingCodeRegex = RegExp(r'[A-Z]\d|\d[A-Z]');

  /// Sequence de chiffres dans une chaine (pour compter combien le
  /// candidat contient de chiffres). Sert au filtre "reject if no space
  /// + 4+ digits" qui elimine les numeros de reference (FA28...).
  static final digitsOnlyRegex = RegExp(r'[^0-9]');

  /// Whitespace : 1 ou plusieurs espaces / tabulations.
  static final whitespaceRegex = RegExp(r'\s+');
}
