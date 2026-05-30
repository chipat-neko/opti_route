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

  /// Compare une ETA estimee a la fenetre horaire [fenetreDebut, fenetreFin]
  /// (format "HH:MM") d'un stop pour decider si on est dans les clous,
  /// en avance ou en retard. Carte #276.
  ///
  /// Les heures de fenetre sont rapportees a la meme date que [eta]
  /// pour permettre la comparaison (les fenetres ne contiennent pas de
  /// date dans la base, juste un wall-clock).
  static EtaWindowStatus crossWindow({
    required DateTime eta,
    required String? fenetreDebut,
    required String? fenetreFin,
  }) {
    if ((fenetreDebut == null || fenetreDebut.isEmpty) &&
        (fenetreFin == null || fenetreFin.isEmpty)) {
      return EtaWindowStatus.none;
    }
    final debut = _parseTimeOfDay(fenetreDebut, eta);
    final fin = _parseTimeOfDay(fenetreFin, eta);
    if (fin != null && eta.isAfter(fin)) return EtaWindowStatus.late;
    if (debut != null && eta.isBefore(debut)) return EtaWindowStatus.early;
    return EtaWindowStatus.ok;
  }

  /// Construit un DateTime "wall-clock" en fixant heure/minute parses
  /// depuis "HH:MM" sur la date de [anchor]. Retourne null si parse KO.
  static DateTime? _parseTimeOfDay(String? hhmm, DateTime anchor) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return DateTime(anchor.year, anchor.month, anchor.day, h, m);
  }

  /// Estime l'heure de fin de tournee = ETA du dernier stop pending +
  /// sa duree d'arret. Retourne null si pas de stop pending ou pas
  /// d'ETA calculable. Carte #276.
  ///
  /// Note : `etasParStopProvider` calcule les ETAs depuis demareeLe ou
  /// `now`, donc le resultat se recalibre naturellement au fur et a
  /// mesure des validations (chaque "marquer livre" reduit le pending,
  /// donc la fin estimee diminue).
  static DateTime? computeEndOfTour({
    required List<Stop> orderedStops,
    required Map<int, DateTime> etas,
  }) {
    if (etas.isEmpty) return null;
    Stop? last;
    for (final s in orderedStops) {
      if (etas.containsKey(s.id)) last = s;
    }
    if (last == null) return null;
    final etaLast = etas[last.id];
    if (etaLast == null) return null;
    return etaLast.add(Duration(minutes: last.dureeArretMin));
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

/// Statut du croisement ETA vs fenetre horaire d'un stop (carte #276).
/// - [ok] : eta est dans la fenetre [fenetreDebut, fenetreFin]
/// - [early] : eta < fenetreDebut (on serait sur place trop tot)
/// - [late] : eta > fenetreFin (on va arriver apres la fin de la fenetre)
/// - [none] : pas de fenetre definie sur le stop
enum EtaWindowStatus { ok, early, late, none }

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
