import 'database.dart';

/// Calcule des temps d'arrivee estimes (ETA) pour chaque arret restant
/// d'une tournee.
///
/// Strategie simple (pas d'appel API) :
/// - Duree totale tournee (`dureeTotaleS`) repartie au prorata du
///   nombre d'arrets restants
/// - + duree d'arret (`dureeArretMin`) cumulee
/// - + cumul des pauses (`pauseeSeconds`) si applicable
///
/// Pour une vraie ETA precise il faudrait re-appeler /directions ORS
/// a chaque transition, mais ca coute des appels API. Le calcul prorata
/// est "good enough" pour un livreur qui veut savoir "vers 14h30 j'y
/// suis" sans surcharger le quota.
class EtaCalculator {
  EtaCalculator._();

  /// Pour chaque stop pas encore livre/echec (`a_livrer`), retourne
  /// une estimation `DateTime` d'arrivee a destination.
  ///
  /// [startAt] : moment a partir duquel on calcule (typiquement maintenant
  /// si la tournee est en cours, sinon `demareeLe` si renseigne).
  /// [orderedStops] : tous les stops dans l'ordre de la tournee.
  /// [dureeTotaleS] : duree totale estimee (depuis ORS, exclut les
  /// arrets). Peut etre null -> on prend une moyenne 10 min entre arrets.
  static Map<int, DateTime> computeEtas({
    required DateTime startAt,
    required List<Stop> orderedStops,
    int? dureeTotaleS,
  }) {
    final pending = orderedStops
        .where((s) => s.statutLivraison == 'a_livrer')
        .toList(growable: false);
    if (pending.isEmpty) return const {};

    // Duree moyenne de roulage entre 2 arrets, en secondes.
    final int avgDriveS;
    if (dureeTotaleS != null && orderedStops.isNotEmpty) {
      avgDriveS = (dureeTotaleS / orderedStops.length).round();
    } else {
      avgDriveS = 600; // 10 min defaut
    }

    final out = <int, DateTime>{};
    var cursor = startAt;
    for (var i = 0; i < pending.length; i++) {
      final s = pending[i];
      // Roulage jusqu'a cet arret
      cursor = cursor.add(Duration(seconds: avgDriveS));
      out[s.id] = cursor;
      // Temps passe sur place
      cursor = cursor.add(Duration(minutes: s.dureeArretMin));
    }
    return out;
  }

  /// Formate une ETA en "HH:MM" (local time, pas de TZ).
  static String formatEtaHHmm(DateTime eta) {
    final h = eta.hour.toString().padLeft(2, '0');
    final m = eta.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
