import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ban_geocoding_service.dart';
import '../data/france_geocoding_service.dart';
import '../data/geocode_cache_repository.dart';
import '../data/geocoding_service.dart';
import '../data/recherche_entreprises_service.dart';
import 'database_providers.dart';

final geocodeCacheRepositoryProvider = Provider<GeocodeCacheRepository>((ref) {
  return GeocodeCacheRepository(ref.watch(appDatabaseProvider));
});

/// Geocodage officiel France : BAN + Recherche-Entreprises en cascade
/// intelligente (BAN d'abord pour les adresses, Recherche-Entreprises
/// d'abord pour les noms d'entreprise).
///
/// Aucune cle API requise, aucune CB, sources officielles francaises.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final cache = ref.watch(geocodeCacheRepositoryProvider);

  final service = FranceGeocodingService(
    ban: BanGeocodingService(cache: cache),
    entreprises: RechercheEntreprisesService(cache: cache),
  );

  ref.onDispose(service.close);
  return service;
});
