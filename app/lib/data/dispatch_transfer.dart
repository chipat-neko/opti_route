import 'package:drift/drift.dart' show Value;

import 'database.dart';

/// Réassignation live d'un stop d'un coéquipier vers un autre (carte
/// #333). Pure fn pour valider la transition + générer le payload de
/// transfert qui sera push via Supabase Realtime.
class DispatchTransfer {
  DispatchTransfer._();

  /// Valide qu'un transfer peut avoir lieu. Returns null si OK,
  /// sinon une raison textuelle pour le toast d'erreur.
  static String? validate({
    required Stop stop,
    required int? targetCoequipierId,
  }) {
    if (stop.statutLivraison == 'livre' || stop.statutLivraison == 'echec') {
      return 'Arret deja valide, transfer impossible';
    }
    if (targetCoequipierId != null &&
        stop.coequipierId == targetCoequipierId) {
      return 'Deja affecte a ce coequipier';
    }
    return null;
  }

  /// Companion Drift pour appliquer le transfer côté DB locale (le
  /// realtime cloud notifiera le target).
  static StopsCompanion buildCompanion({
    required int newCoequipierId,
  }) {
    return StopsCompanion(
      coequipierId: Value(newCoequipierId),
    );
  }

  /// Stats : nb stops par coequipier dans une tournee. Sert au tableau
  /// "carte vivante" coté chef.
  static Map<int?, int> countByCoequipier(List<Stop> stops) {
    final out = <int?, int>{};
    for (final s in stops) {
      out[s.coequipierId] = (out[s.coequipierId] ?? 0) + 1;
    }
    return out;
  }
}
