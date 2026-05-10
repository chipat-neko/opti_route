import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geocode_cache_repository.dart';
import '../data/nominatim_service.dart';
import 'database_providers.dart';

final geocodeCacheRepositoryProvider = Provider<GeocodeCacheRepository>((ref) {
  return GeocodeCacheRepository(ref.watch(appDatabaseProvider));
});

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  final service = NominatimService(
    cache: ref.watch(geocodeCacheRepositoryProvider),
  );
  ref.onDispose(service.close);
  return service;
});
