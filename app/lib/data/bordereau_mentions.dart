/// Détection des mentions spéciales dans le texte OCR d'un bordereau
/// (carte #329). Pure fn pour flagguer les contraintes en UI rouge :
/// signature obligatoire, +18 ans, fragile, RDV, ordonnance, etc.
class BordereauMentions {
  BordereauMentions._();

  static const _mentionPatterns = <BordereauMention, List<String>>{
    BordereauMention.signatureRequired: ['SIGN', 'SIGNATURE', 'RECOMMAND'],
    BordereauMention.fragile: ['FRAGILE', 'VERRE', 'CASSANT'],
    BordereauMention.adultRequired: ['+18', 'MAJEUR', '18 ANS'],
    BordereauMention.rendezVous: ['RDV', 'RENDEZ-VOUS', 'SUR RDV'],
    BordereauMention.medication: [
      'ORDONNANCE',
      'PHARMACIE',
      'MEDICAL',
      'MÉDICAL',
    ],
    BordereauMention.refrigerated: ['FRAIS', 'FROID', 'REFRIG'],
  };

  static Set<BordereauMention> detect(String ocrText) {
    final normalized = ocrText.toUpperCase();
    final out = <BordereauMention>{};
    for (final entry in _mentionPatterns.entries) {
      if (entry.value.any(normalized.contains)) {
        out.add(entry.key);
      }
    }
    return out;
  }

  /// Labels UI court pour afficher en badge.
  static String labelFor(BordereauMention m) {
    switch (m) {
      case BordereauMention.signatureRequired:
        return 'SIGN';
      case BordereauMention.fragile:
        return 'FRAGILE';
      case BordereauMention.adultRequired:
        return '+18';
      case BordereauMention.rendezVous:
        return 'RDV';
      case BordereauMention.medication:
        return 'MED';
      case BordereauMention.refrigerated:
        return 'FRAIS';
    }
  }

  /// True si la mention DOIT bloquer un markLivre sans preuve photo.
  static bool requiresProofPhoto(BordereauMention m) {
    return m == BordereauMention.signatureRequired ||
        m == BordereauMention.adultRequired;
  }
}

enum BordereauMention {
  signatureRequired,
  fragile,
  adultRequired,
  rendezVous,
  medication,
  refrigerated,
}
