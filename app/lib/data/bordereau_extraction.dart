/// Resultat de l'extraction automatique d'un bordereau de livraison.
///
/// Tous les champs sont optionnels : selon la qualite de l'OCR et le
/// format du bordereau, certains peuvent manquer.
class BordereauExtraction {
  const BordereauExtraction({
    this.nomDestinataire,
    this.rue,
    this.codePostal,
    this.ville,
    this.telephone,
    this.nbColis,
    this.confidence = ExtractionConfidence.high,
  });

  /// Niveau de confiance dans le parsing.
  /// - high : tous les marqueurs trouves, donnees cross-verifiees.
  /// - low : on a trouve quelque chose mais c'est ambigu, l'utilisateur
  ///   doit verifier (UI affichera une carte orange).
  /// - none : on n'a rien de fiable a proposer (UI cachera la carte).
  final ExtractionConfidence confidence;

  /// Nom de l'entreprise / personne destinataire.
  final String? nomDestinataire;

  /// Ligne(s) d'adresse de rue (peut inclure BP, complement, etc.).
  final String? rue;

  final String? codePostal;
  final String? ville;
  final String? telephone;
  final int? nbColis;

  /// Vrai si on a au moins de quoi pre-remplir le formulaire.
  bool get hasUsefulData =>
      nomDestinataire != null ||
      rue != null ||
      codePostal != null ||
      ville != null;

  /// Adresse postale composee, utilisable comme fallback geocodage.
  /// Ex: "42 RUE DE LA BEAUCE, 28110 LUCE".
  String? get adressePostale {
    final parts = <String>[
      if (rue != null && rue!.isNotEmpty) rue!,
      if (codePostal != null && codePostal!.isNotEmpty)
        ville != null && ville!.isNotEmpty
            ? '$codePostal $ville'
            : codePostal!,
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  /// Recherche par nom d'entreprise + ville, utile pour interroger
  /// SIRENE en priorite (Noah a explicitement demande "essayer le nom
  /// d'entreprise d'abord, fallback sur l'adresse").
  String? get rechercheParNom {
    if (nomDestinataire == null || nomDestinataire!.isEmpty) return null;
    if (ville != null && ville!.isNotEmpty) {
      return '$nomDestinataire $ville';
    }
    return nomDestinataire;
  }
}

enum ExtractionConfidence { high, low, none }
