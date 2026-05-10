import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cascading_geocoding_service.dart';
import '../data/geocode_cache_repository.dart';
import '../data/geocoding_service.dart';
import '../data/photon_service.dart';
import '../data/tomtom_service.dart';
import 'database_providers.dart';

final geocodeCacheRepositoryProvider = Provider<GeocodeCacheRepository>((ref) {
  return GeocodeCacheRepository(ref.watch(appDatabaseProvider));
});

/// Fournisseur de geocodage selon les parametres :
/// - Si une cle TomTom est configuree -> cascade [TomTom] -> [Photon].
///   TomTom en 1er pour la precision (numeros de rue), Photon en
///   fallback automatique si TomTom rate / ne trouve pas / plante.
/// - Sinon -> [PhotonService] seul (gratuit, sans cle).
///
/// Ce provider se reinstancie automatiquement quand la cle TomTom
/// change (Riverpod recree le service via `ref.watch(...)`).
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final apiKey = ref.watch(tomtomApiKeyProvider).asData?.value;
  final cache = ref.watch(geocodeCacheRepositoryProvider);

  final GeocodingService service;
  if (apiKey != null && apiKey.isNotEmpty) {
    service = CascadingGeocodingService([
      TomTomService(apiKey: apiKey, cache: cache),
      PhotonService(cache: cache),
    ]);
  } else {
    service = PhotonService(cache: cache);
  }

  ref.onDispose(service.close);
  return service;
});
