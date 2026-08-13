import 'database.dart';
import 'scan_duplicate_check.dart';
import 'stops_repository.dart';

/// Branchement des controles anti-doublon du scan colis (carte #315).
///
/// Ce service ne contient AUCUNE regle metier : il charge le bon jeu
/// d'arrets via [StopsRepository] puis delegue la decision aux
/// fonctions pures de [ScanDuplicateCheck]. C'est la couche qui manquait
/// entre le module pur (qui prend des listes de `Stop` en entree) et
/// l'ecran de scan (qui ne doit jamais faire de SQL).
class ScanDuplicateService {
  ScanDuplicateService(this._stops);

  final StopsRepository _stops;

  /// Cherche une RE-LIVRAISON : un arret deja marque livre dans les 30
  /// derniers jours (fenetre [ScanDuplicateCheck.windowDuplicate],
  /// toutes tournees confondues) qui porte deja [tracking].
  ///
  /// Retourne null dans le cas nominal (aucune livraison recente de ce
  /// numero). Le resultat est purement informatif : c'est l'UI qui
  /// decide quoi en faire, et elle ne doit jamais bloquer le livreur
  /// (colis reexpedie, numero recycle par le transporteur...).
  Future<Stop?> findRecentDelivered(String tracking, {DateTime? now}) async {
    final code = tracking.trim();
    if (code.isEmpty) return null;
    final t = now ?? DateTime.now();
    final recents = await _stops.getDeliveredSince(
      t.subtract(ScanDuplicateCheck.windowDuplicate),
      trackingNumber: code,
    );
    return ScanDuplicateCheck.findRecentDelivered(
      tracking: code,
      recentStops: recents,
      now: t,
    );
  }

  /// Verifie que [scannedBarcode] correspond bien a [expectedStop] et
  /// pas au colis du voisin. Charge les autres arrets de la meme
  /// tournee pour pouvoir suggerer le bon arret en cas d'erreur.
  ///
  /// N'a de sens que quand le scan se fait AVEC un arret attendu (cf
  /// `ScanColisScreen.expectedStop`) : sans arret attendu, il n'y a pas
  /// de "mauvais arret" a detecter.
  Future<ScanMatch> verifyBarcode({
    required String scannedBarcode,
    required Stop expectedStop,
  }) async {
    final tourneeStops = await _stops.getByTournee(expectedStop.tourneeId);
    return ScanDuplicateCheck.verifyBarcode(
      scannedBarcode: scannedBarcode,
      expectedStop: expectedStop,
      tourneeStops: tourneeStops,
    );
  }
}
