import 'database.dart';
import 'geo_utils.dart';

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

  /// Calcule pour chaque stop (par id) la distance + duree estimee
  /// du segment PRECEDENT (depuis le stop precedent OU depuis le
  /// depot pour le 1er stop).
  ///
  /// Heuristique simple : haversine (vol d'oiseau) + vitesse moyenne
  /// urbaine de 30 km/h (compromise entre boulevard 50 et centre-ville
  /// 15). Pour de la livraison reelle, +20-30% vs reelle. Suffisant
  /// pour donner "ah c'est juste a cote / loin" en un coup d'oeil
  /// dans la liste (style Spoke route planner).
  ///
  /// Skip les stops sans coords (return: pas de cle pour ces ids).
  /// Skip aussi les stops deja livre / echec (segment historique sans
  /// interet maintenant).
  ///
  /// [depotLat] / [depotLng] : point de depart de la tournee, sert au
  /// segment du 1er stop pending. Si null, le 1er stop n'a pas de
  /// segment calcule.
  static Map<int, SegmentInfo> computeSegments({
    required List<Stop> orderedStops,
    required double depotLat,
    required double depotLng,
    double avgSpeedKmh = 30,
  }) {
    final out = <int, SegmentInfo>{};
    // Le point d'origine pour le 1er stop pending = depot.
    var prevLat = depotLat;
    var prevLng = depotLng;
    var primed = false;
    for (final s in orderedStops) {
      if (s.statutLivraison != 'a_livrer') continue;
      if (s.lat == null || s.lng == null) continue;
      // Si on n'a pas encore d'origine valide (premier passage), on
      // utilise depot. Apres on cumule.
      final lat = s.lat!;
      final lng = s.lng!;
      final meters = GeoUtils.haversineMeters(
        lat1: prevLat,
        lon1: prevLng,
        lat2: lat,
        lon2: lng,
      );
      final speed = avgSpeedKmh > 0 ? avgSpeedKmh : 30.0;
      final durationSec = (meters / 1000.0 / speed * 3600).round();
      out[s.id] = SegmentInfo(
        meters: meters.round(),
        duration: Duration(seconds: durationSec),
        fromDepot: !primed,
      );
      prevLat = lat;
      prevLng = lng;
      primed = true;
    }
    return out;
  }
}

/// Info de segment (depuis le stop precedent vers ce stop).
class SegmentInfo {
  const SegmentInfo({
    required this.meters,
    required this.duration,
    required this.fromDepot,
  });

  /// Distance vol d'oiseau en metres.
  final int meters;

  /// Duree estimee a vitesse moyenne urbaine.
  final Duration duration;

  /// Vrai si ce segment part du depot (premier stop pending de la
  /// tournee). Sert a l'UI pour afficher un libelle different
  /// ('Depuis depart' vs 'Depuis stop precedent').
  final bool fromDepot;

  /// Format compact "1.2 km" ou "850 m" pour les courtes distances.
  String get distanceLabel {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Format compact "15 min" ou "1h05" pour les longs trajets.
  String get durationLabel {
    final mins = duration.inMinutes;
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}
