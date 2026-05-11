import 'dart:math' as math;

import '../database.dart';
import 'assistant_rule.dart';
import 'assistant_suggestion.dart';
import 'tour_context.dart';

/// Regle "Livrer au passage" : si pendant la tournee active, la
/// position GPS courante est a moins de `proximityThresholdM` metres
/// (haversine) d'un arret a_livrer **qui n'est pas le prochain prevu
/// dans l'ordre**, on suggere de le livrer avant.
///
/// Filtre :
/// - Tournee doit etre `en_cours` (rien a faire sur brouillon /
///   optimisee / terminee).
/// - Au moins 2 arrets `a_livrer` (sinon pas de switch possible).
/// - Le candidat doit avoir des coordonnees GPS.
/// - On ignore le 1er stop a_livrer (= le prochain prevu, suggerer
///   sa propre proximite n'a pas de sens).
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
    // On ignore le 1er restant (= le prochain prevu) : suggerer sa
    // proximite ne sert a rien.
    Stop? best;
    double bestDistance = double.infinity;
    for (var i = 1; i < remaining.length; i++) {
      final stop = remaining[i];
      if (stop.lat == null || stop.lng == null) continue;
      final d = _haversineMeters(
        pos.latitude, pos.longitude,
        stop.lat!, stop.lng!,
      );
      if (d > ctx.params.proximityThresholdM) continue;
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
    // Priorite augmente quand on est tres proche (plus de chance que
    // l'utilisateur soit interesse). Echelle simple : 80 a 50 metres
    // = 100, 300 m = 60.
    final priority = math.max(50, 100 - (bestDistance / 5).round());

    return AssistantSuggestion(
      kind: kind,
      stop: best,
      message: 'Tu passes a ${bestDistance.round()}m de $label. Le livrer avant ?',
      priority: priority,
      distanceMeters: bestDistance,
    );
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

  static double _deg2rad(double d) => d * math.pi / 180.0;
}
