import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/openroute_optimization_service.dart';
import '../data/optimization_service.dart';
import 'database_providers.dart';

/// Stream de la cle API OpenRouteService (null si non configuree).
final orsApiKeyProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchOrsApiKey();
});

/// Service d'optimisation. Null tant que l'utilisateur n'a pas saisi
/// sa cle ORS dans les parametres.
final optimizationServiceProvider = Provider<OptimizationService?>((ref) {
  final apiKey = ref.watch(orsApiKeyProvider).asData?.value;
  if (apiKey == null || apiKey.isEmpty) return null;

  final service = OpenRouteOptimizationService(apiKey: apiKey);
  ref.onDispose(service.close);
  return service;
});
