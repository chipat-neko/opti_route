import 'database.dart';

/// Ordre de **chargement** du camion calcule depuis l'ordre de livraison.
/// Carte #283 : le 1er livre doit etre **devant** (donc charge en dernier
/// = au fond du hayon). Eviter de fouiller le hayon a chaque arret.
///
/// Convention `frontFirst` (defaut true) :
/// - Le 1er element de la liste retournee = devant du camion (sortira
///   en 1er a la livraison)
/// - Le dernier = au fond
///
/// Strategie : on inverse simplement l'ordre de visite. Le N-ieme stop
/// visite est charge au N-ieme depuis le fond. On filtre les stops
/// livre/echec (deja sortis) pour ne montrer que ce qu'il reste a charger.
class LoadingOrder {
  LoadingOrder._();

  /// Stops dans l'ordre de **chargement** : le 1er devant = sera livre
  /// en premier. Filtre les stops type 'ramasse' (n'occupent pas la
  /// place pendant le trajet aller) et ceux deja livre/echec (sortis
  /// du camion).
  static List<Stop> compute(List<Stop> orderedStops) {
    final remaining = orderedStops.where((s) {
      if (s.type == 'ramasse') return false;
      if (s.statutLivraison == 'livre' || s.statutLivraison == 'echec') {
        return false;
      }
      return true;
    }).toList();
    // Le 1er a livrer doit etre devant -> on garde l'ordre, c'est
    // le LECTEUR qui visualise "devant -> fond". Cote chargement
    // PHYSIQUE, l'inverse : on charge en commencant par le dernier
    // arret (au fond) jusqu'au 1er (devant, dernier carton charge).
    return remaining;
  }

  /// Helper : ordre physique de chargement = inverse de l'ordre de
  /// livraison. Sert si on veut afficher "Charge dans cet ordre" au
  /// depot (premier carton = au fond, dernier = devant).
  static List<Stop> physicalLoadingOrder(List<Stop> orderedStops) {
    return compute(orderedStops).reversed.toList();
  }
}
