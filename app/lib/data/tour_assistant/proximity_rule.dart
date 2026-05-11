import 'dart:math' as math;

import '../database.dart';
import 'assistant_rule.dart';
import 'assistant_suggestion.dart';
import 'tour_context.dart';

/// Regle "Livrer au passage" : si pendant la tournee active, la
/// position GPS courante est a moins de `proximityThresholdM` metres
/// (haversine) d'un arret `a_livrer` qui n'est **pas** le prochain
/// prevu, on suggere de le livrer avant.
///
/// Filtres anti-faux-positifs :
/// - Tournee `en_cours` uniquement.
/// - >= 2 stops `a_livrer` (sinon rien a swap).
/// - Stop avec coords GPS.
/// - Stop != le 1er restant (= le prochain deja prevu).
/// - Priorite != `eviter_si_possible` (Noah a explicitement dit
///   "evite ce client si tu peux", on ne lui propose pas un crochet).
/// - Fenetre horaire compatible : on ne propose pas un stop dont
///   `fenetreDebut` est dans plus de `fenetreEarlyMinutes` minutes
///   (pas encore l'heure), ni un stop dont `fenetreFin` est deja
///   passe (de toute facon foutu).
/// - Cap GPS coherent : si la vitesse est >= `minSpeedForHeadingMs`,
///   le stop doit etre dans un cone de `2 * directionToleranceDeg`
///   degres devant nous. Evite de proposer un detour vers l'arriere.
class ProximityRule extends AssistantRule {
  const ProximityRule();

  @override
  SuggestionKind get kind => SuggestionKind.proximity;

  @override
  AssistantSuggestion? evaluate(TourContext ctx) {
    if (!ctx.params.enabled || !ctx.params.proximityEnabled) return null;
    if (ctx.tournee.statut != 'en_cours') return null;
    if (ctx.currentPosition == null) return null;

    final remaining = ctx.stops
        .where((s) => s.statutLivraison == 'a_livrer')
        .toList(growable: false);
    if (remaining.length < 2) return null;

    final pos = ctx.currentPosition!;

    // Cap GPS connu ? heading fiable uniquement si on bouge assez vite.
    // Geolocator retourne heading = -1.0 quand inconnu, ou >= 0 sinon.
    final hasReliableHeading = ctx.params.useDirectionFilter &&
        pos.heading >= 0 &&
        pos.speed >= ctx.params.minSpeedForHeadingMs;

    Stop? best;
    double bestDistance = double.infinity;
    for (var i = 1; i < remaining.length; i++) {
      final stop = remaining[i];
      if (stop.lat == null || stop.lng == null) continue;
      if (stop.priorite == 'eviter_si_possible') continue;
      if (!_isFenetreHoraireOk(stop, ctx.now, ctx.params.fenetreEarlyMinutes)) {
        continue;
      }

      final d = _haversineMeters(
        pos.latitude, pos.longitude,
        stop.lat!, stop.lng!,
      );
      if (d > ctx.params.proximityThresholdM) continue;

      if (hasReliableHeading) {
        final bearing = _bearingDegrees(
          pos.latitude, pos.longitude,
          stop.lat!, stop.lng!,
        );
        final angleDiff = _angleDifference(pos.heading, bearing);
        if (angleDiff > ctx.params.directionToleranceDeg) continue;
      }

      if (d < bestDistance) {
        bestDistance = d;
        best = stop;
      }
    }
    if (best == null) return null;

    final label =
        best.nomClient != null && best.nomClient!.trim().isNotEmpty
            ? best.nomClient!.trim()
            : best.adresseBrute.split(',').first.trim();
    // Priorite : plus on est proche, plus la suggestion est urgente.
    // Echelle : 50 m -> 90, 300 m -> 60, 800 m -> 30.
    final priority = math.max(30, 100 - (bestDistance / 8).round());

    return AssistantSuggestion(
      kind: kind,
      stop: best,
      message:
          'Tu passes a ${bestDistance.round()}m de $label. Le livrer avant ?',
      priority: priority,
      distanceMeters: bestDistance,
    );
  }

  /// Filtre fenetre horaire :
  /// - Si pas de fenetre definie -> OK.
  /// - Si on est avant `fenetreDebut - earlyMinutes` -> KO (trop tot).
  /// - Si on est apres `fenetreFin` -> KO (trop tard, deja foutu).
  /// - Sinon -> OK.
  ///
  /// `fenetreDebut` / `fenetreFin` sont stockes en format "HH:mm" et
  /// s'interpretent dans la journee courante (`now`).
  static bool _isFenetreHoraireOk(Stop stop, DateTime now, int earlyMinutes) {
    if (stop.fenetreDebut == null && stop.fenetreFin == null) return true;
    final debut = _parseHHmm(stop.fenetreDebut, now);
    final fin = _parseHHmm(stop.fenetreFin, now);

    if (debut != null) {
      final earlyLimit = debut.subtract(Duration(minutes: earlyMinutes));
      if (now.isBefore(earlyLimit)) return false;
    }
    if (fin != null && now.isAfter(fin)) return false;
    return true;
  }

  /// Parse "HH:mm" en DateTime aujourd'hui. Retourne null si format
  /// invalide ou champ vide.
  static DateTime? _parseHHmm(String? hhmm, DateTime now) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(now.year, now.month, now.day, h, m);
  }

  /// Distance haversine (en metres) entre 2 coords decimales.
  static double _haversineMeters(
      double lat1, double lon1, double lat2, double lon2) {
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

  /// Bearing initial (cap a prendre) en degres 0-360 depuis le point
  /// 1 vers le point 2. 0 = nord, 90 = est, 180 = sud, 270 = ouest.
  /// Formule classique de navigation orthodromique.
  static double _bearingDegrees(
      double lat1, double lon1, double lat2, double lon2) {
    final phi1 = _deg2rad(lat1);
    final phi2 = _deg2rad(lat2);
    final lambda1 = _deg2rad(lon1);
    final lambda2 = _deg2rad(lon2);
    final y = math.sin(lambda2 - lambda1) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(lambda2 - lambda1);
    final theta = math.atan2(y, x);
    return (theta * 180 / math.pi + 360) % 360;
  }

  /// Difference absolue entre 2 angles en degres, en tenant compte
  /// du wraparound (175° vs 5° = 170° et non 170° non plus, ah si
  /// en fait c'est bien 170° pour cette paire ; mais 350° vs 10° = 20°
  /// et pas 340°). Retour : [0, 180].
  static double _angleDifference(double a, double b) {
    final diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;
}
