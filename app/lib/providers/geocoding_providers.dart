import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geocode_cache_repository.dart';
import '../data/geocoding_service.dart';
import '../data/photon_service.dart';
import 'database_providers.dart';

final geocodeCacheRepositoryProvider = Provider<GeocodeCacheRepository>((ref) {
  return GeocodeCacheRepository(ref.watch(appDatabaseProvider));
});

/// Fournisseur de geocodage actuellement utilise par l'app.
///
/// Photon (Komoot) : gratuit, sans cle API, base OSM avec un meilleur
/// ranker que Nominatim direct. Pour basculer vers un autre fournisseur
/// (TomTom, Mapbox, Google), changer ici sans toucher au widget.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final service = PhotonService(
    cache: ref.watch(geocodeCacheRepositoryProvider),
  );
  ref.onDispose(service.close);
  return service;
});
