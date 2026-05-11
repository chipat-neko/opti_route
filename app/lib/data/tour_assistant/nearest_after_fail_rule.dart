import 'dart:math' as math;

import '../database.dart';
import 'assistant_rule.dart';
import 'assistant_suggestion.dart';
import 'tour_context.dart';

/// Regle "Voisin apres echec" : si un arret a ete marque `echec` dans
/// les `failRecentMinutes` dernieres minutes, on propose le stop
/// `a_livrer` le plus proche de la position GPS courante (au lieu de
/// suivre betement l'ordre initial).
///
/// Cas d'usage : Noah arrive chez X qui est absent. Au lieu de
/// continuer vers Y (prochain prevu, peut etre a 10 km), l'assistant
/// suggere de livrer Z qui est juste a cote (200 m).
///
/// Filtres :
/// - Tournee `en_cours`.
/// - Position GPS connue.
/// - Au moins un stop `echec` avec `livreLe` dans les
///   `failRecentMinutes` dernieres minutes.
/// - Au moins un stop `a_livrer` avec coords.
/// - Le voisin propose != le 1er restant (sinon pas de bascule
///   utile).
/// - Voisin priorite != `eviter_si_possible`.
class NearestAfterFailRule extends AssistantRule {
  const NearestAfterFailRule();

  @override
  SuggestionKind get kind => SuggestionKind.nearestAfterFail;

  @override
  AssistantSuggestion? evaluate(TourContext ctx) {
    if (!ctx.params.enabled || !ctx.params.nearestAfterFailEnabled) {
      return null;
    }
    if (ctx.tournee.statut != 'en_cours') return null;
    if (ctx.currentPosition == null) return null;

    // Cherche un echec recent.
    final hasRecentFail = ctx.stops.any((s) {
      if (s.statutLivraison != 'echec') return false;
      if (s.livreLe == null) return false;
      final delta = ctx.now.difference(s.livreLe!).inMinutes;
      return delta >= 0 && delta <= ctx.params.failRecentMinutes;
    });
    if (!hasRecentFail) return null;

    final remaining = ctx.stops
        .where((s) =>
            s.statutLivraison == 'a_livrer' &&
            s.lat != null &&
            s.lng != null &&
            s.priorite != 'eviter_si_possible')
        .toList(growable: false);
    if (remaining.length < 2) return null;

    final pos = ctx.currentPosition!;
    Stop? best;
    double bestDistance = double.infinity;
    for (final stop in remaining) {
      final d = _haversineMeters(
        pos.latitude, pos.longitude,
        stop.lat!, stop.lng!,
      );
      if (d < bestDistance) {
        bestDistance = d;
        best = stop;
      }
    }
    if (best == null) return null;
    // Pas la peine de proposer le 1er prevu : c'est deja ce que Noah va
    // faire en suivant l'ordre.
    if (best.id == remaining.first.id) return null;

    final label =
        best.nomClient != null && best.nomClient!.trim().isNotEmpty
            ? best.nomClient!.trim()
            : best.adresseBrute.split(',').first.trim();

    return AssistantSuggestion(
      kind: kind,
      stop: best,
      message:
          'Echec recent. Plus proche : $label (${bestDistance.round()}m).',
      priority: 80,
      distanceMeters: bestDistance,
    );
  }

  /// Distance haversine en metres.
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
