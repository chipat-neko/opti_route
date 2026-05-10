import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geocode_cache_repository.dart';
import '../data/geocoding_service.dart';
import '../data/photon_service.dart';
import '../data/tomtom_service.dart';
import 'database_providers.dart';

final geocodeCacheRepositoryProvider = Provider<GeocodeCacheRepository>((ref) {
  return GeocodeCacheRepository(ref.watch(appDatabaseProvider));
});

/// Fournisseur de geocodage selon les parametres :
/// - Si une cle TomTom est configuree -> [TomTomService] (qualite max).
/// - Sinon -> [PhotonService] (fallback gratuit, base OSM).
///
/// Ce provider se reinstancie automatiquement quand la cle change
/// (Riverpod recree le service via `ref.watch(tomtomApiKeyProvider)`).
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final apiKey = ref.watch(tomtomApiKeyProvider).asData?.value;
  final cache = ref.watch(geocodeCacheRepositoryProvider);

  final GeocodingService service;
  if (apiKey != null && apiKey.isNotEmpty) {
    service = TomTomService(apiKey: apiKey, cache: cache);
  } else {
    service = PhotonService(cache: cache);
  }

  ref.onDispose(service.close);
  return service;
});
