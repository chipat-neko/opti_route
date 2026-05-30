import 'database.dart';

/// Mode "ramasse de masse" (carte #303) : ecran dedie qui enchaine
/// rapidement les enlevements chez un meme expediteur. Pure fn pour
/// l'agregation.
class RamasseBulkStats {
  const RamasseBulkStats({
    required this.totalRamasses,
    required this.recoltes,
    required this.colisRecoltes,
  });

  /// Nb total de stops type 'ramasse' dans la tournee.
  final int totalRamasses;

  /// Nb de ramasses marquees 'livre' (= colis effectivement collecte).
  final int recoltes;

  /// Sum des nbColis des ramasses recoltees.
  final int colisRecoltes;

  static RamasseBulkStats compute(List<Stop> stops) {
    final ramasses = stops.where((s) => s.type == 'ramasse').toList();
    final recoltes =
        ramasses.where((s) => s.statutLivraison == 'livre').toList();
    return RamasseBulkStats(
      totalRamasses: ramasses.length,
      recoltes: recoltes.length,
      colisRecoltes:
          recoltes.fold<int>(0, (sum, s) => sum + s.nbColis),
    );
  }
}
