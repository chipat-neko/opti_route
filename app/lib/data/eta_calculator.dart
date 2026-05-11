import 'dart:math' as math;

import 'database.dart';

/// Calcule une estimation d'heure d'arrivee (ETA) pour chaque arret
/// **restant a livrer** d'une tournee.
///
/// Pas de migration / pas d'appel API en plus : on utilise les donnees
/// deja en base (haversine + vitesse moyenne deduite de
/// `tournee.distanceTotaleM / tournee.dureeTotaleS` quand dispo, fallback
/// 50 km/h sinon).
///
/// Renvoie une map `stopId -> DateTime` ne contenant que les arrets
/// `statutLivraison == 'a_livrer'`. Les autres arrets sont absents
/// (l'UI affiche rien pour eux).
///
/// Renvoie `{}` si pas assez de donnees (ex: stops sans coords, point
/// de depart non geocode...).
Map<int, DateTime> computeEtaForStops(Tournee tournee, List<Stop> stopsInOrder) {
  final aLivrer = stopsInOrder
      .where((s) => s.statutLivraison == 'a_livrer')
      .toList(growable: false);
  if (aLivrer.isEmpty) return const {};
  // Tous les stops "a_livrer" doivent avoir des coords ; sinon on
  // n'affiche rien plutot que de mentir.
  if (aLivrer.any((s) => s.lat == null || s.lng == null)) return const {};

  // Heure de depart de l'estimation : maintenant. L'ETA repond a la
  // question "quand vais-je arriver sur le prochain arret a partir de
  // l'instant present", peu importe si la tournee est demarree ou pas.
  final now = DateTime.now();

  // Point de depart geographique : on prend le dernier arret livre /
  // echec si on en a un (plus realiste qu'un retour au depot pour les
  // ETA des arrets restants en milieu de tournee). Sinon, le depot.
  final passes = stopsInOrder
      .where((s) =>
          s.statutLivraison == 'livre' || s.statutLivraison == 'echec')
      .toList();
  double startLat = tournee.pointDepartLat;
  double startLng = tournee.pointDepartLng;
  if (passes.isNotEmpty) {
    final last = passes.last;
    if (last.lat != null && last.lng != null) {
      startLat = last.lat!;
      startLng = last.lng!;
    }
  }

  // 1. Distance haversine entre chaque arret (et avec le point de
  //    depart pour le 1er). Sert de base "vol d'oiseau" qu'on corrige
  //    ensuite par un ratio reseau/oiseau si on l'a.
  final legHaversine = <double>[];
  double prevLat = startLat;
  double prevLng = startLng;
  for (final s in aLivrer) {
    legHaversine.add(_haversineMeters(prevLat, prevLng, s.lat!, s.lng!));
    prevLat = s.lat!;
    prevLng = s.lng!;
  }

  // 2. Vitesse moyenne effective :
  //    - si on a `distanceTotaleM` ET `dureeTotaleS`, on en deduit une
  //      vitesse de conduite (en excluant le temps de service total).
  //    - fallback : 50 km/h.
  double driveSpeedMps = 50000.0 / 3600.0;
  if (tournee.distanceTotaleM != null &&
      tournee.dureeTotaleS != null &&
      tournee.distanceTotaleM! > 0) {
    final totalServiceS = stopsInOrder.fold<int>(
      0,
      (sum, s) => sum + s.dureeArretMin * 60,
    );
    final driveS = tournee.dureeTotaleS! - totalServiceS;
    if (driveS > 60) {
      driveSpeedMps = tournee.distanceTotaleM! / driveS;
    }
  }
  // Garde-fou : sous 5 km/h on a un truc cassé (donnees absurdes), on
  // retombe sur 50 km/h pour ne pas afficher d'ETA absurdes.
  if (driveSpeedMps < 5000.0 / 3600.0) {
    driveSpeedMps = 50000.0 / 3600.0;
  }

  // 3. Construction des ETAs : on accumule `elapsed` au fil des arrets.
  //    Pour chaque leg : duree de conduite = leg / vitesse. Puis on
  //    ajoute le temps de service de l'arret atteint avant de passer
  //    au suivant (pour que l'ETA du n+1 reflete le fait que Noah a
  //    deja livre le n).
  final etas = <int, DateTime>{};
  var elapsed = Duration.zero;
  for (var i = 0; i < aLivrer.length; i++) {
    final legSeconds = (legHaversine[i] / driveSpeedMps).round();
    elapsed += Duration(seconds: legSeconds);
    etas[aLivrer[i].id] = now.add(elapsed);
    elapsed += Duration(minutes: aLivrer[i].dureeArretMin);
  }
  return etas;
}

double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _deg2rad(double d) => d * math.pi / 180.0;
