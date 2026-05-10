import 'database.dart';

/// Resultat d'une optimisation de tournee.
class OptimizationResult {
  const OptimizationResult({
    required this.orderedStopIds,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  /// Ids des stops dans l'ordre optimal de visite.
  final List<int> orderedStopIds;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
}

/// Interface commune pour les fournisseurs d'optimisation de tournee.
/// Permet de basculer entre OpenRouteService, Google OR-Tools, etc.
abstract class OptimizationService {
  /// Optimise l'ordre des `stops` au depart de `tournee.pointDepart*`,
  /// en respectant priorites + fenetres horaires + duree d'arret.
  ///
  /// Lance [OptimizationException] en cas d'erreur API ou de payload
  /// invalide.
  Future<OptimizationResult> optimize({
    required Tournee tournee,
    required List<Stop> stops,
  });

  void close();
}

class OptimizationException implements Exception {
  const OptimizationException(this.message);
  final String message;

  @override
  String toString() => 'OptimizationException: $message';
}
