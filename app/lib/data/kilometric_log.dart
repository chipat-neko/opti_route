/// Bareme kilometrique URSSAF (vehicule particulier, 5 CV - valeur
/// fiscale 2024). Carte #291 : convertir un cumul km en montant
/// deductible / a refacturer.
///
/// Source : URSSAF / Bofip 2024. Le bareme depend du nombre de CV
/// et evolue chaque annee : on garde une version simplifiee 5 CV par
/// defaut, parametrable via [computeFromBareme] pour les annees
/// futures.
class KilometricLog {
  KilometricLog._();

  /// Bareme 5 CV 2024 :
  ///   d ≤ 5000          : 0,636 × d
  ///   5000 < d ≤ 20000  : 0,357 × d + 1395
  ///   d > 20000         : 0,427 × d
  static const _bareme5cv2024 = Bareme(
    palier1Max: 5000,
    palier1PerKm: 0.636,
    palier1Forfait: 0,
    palier2Max: 20000,
    palier2PerKm: 0.357,
    palier2Forfait: 1395,
    palier3PerKm: 0.427,
    palier3Forfait: 0,
  );

  /// Montant deductible pour [annualKm] selon le bareme 5 CV 2024.
  /// Retourne 0 si km ≤ 0.
  static double computeAnnual5cv2024(double annualKm) {
    return computeFromBareme(annualKm: annualKm, bareme: _bareme5cv2024);
  }

  static double computeFromBareme({
    required double annualKm,
    required Bareme bareme,
  }) {
    if (annualKm <= 0) return 0;
    if (annualKm <= bareme.palier1Max) {
      return annualKm * bareme.palier1PerKm + bareme.palier1Forfait;
    }
    if (annualKm <= bareme.palier2Max) {
      return annualKm * bareme.palier2PerKm + bareme.palier2Forfait;
    }
    return annualKm * bareme.palier3PerKm + bareme.palier3Forfait;
  }
}

/// Description d'un bareme kilometrique sous forme de 3 paliers.
class Bareme {
  const Bareme({
    required this.palier1Max,
    required this.palier1PerKm,
    required this.palier1Forfait,
    required this.palier2Max,
    required this.palier2PerKm,
    required this.palier2Forfait,
    required this.palier3PerKm,
    required this.palier3Forfait,
  });

  final double palier1Max;
  final double palier1PerKm;
  final double palier1Forfait;
  final double palier2Max;
  final double palier2PerKm;
  final double palier2Forfait;
  final double palier3PerKm;
  final double palier3Forfait;
}
