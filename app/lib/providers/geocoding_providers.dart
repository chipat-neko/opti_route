import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ban_geocoding_service.dart';
import '../data/france_geocoding_service.dart';
import '../data/geocode_cache_repository.dart';
import '../data/geocoding_service.dart';
import '../data/photon_service.dart';
import '../data/recherche_entreprises_service.dart';
import '../data/stops_geocode_retry_service.dart';
import 'database_providers.dart';

final geocodeCacheRepositoryProvider = Provider<GeocodeCacheRepository>((ref) {
  return GeocodeCacheRepository(ref.watch(appDatabaseProvider));
});

/// Provider direct pour BAN, expose pour les usages qui ne passent pas
/// par la cascade (ex: reverse geocoding depuis un point GPS).
final banGeocodingServiceProvider = Provider<BanGeocodingService>((ref) {
  final cache = ref.watch(geocodeCacheRepositoryProvider);
  final svc = BanGeocodingService(cache: cache);
  ref.onDispose(svc.close);
  return svc;
});

/// Geocodage hybride 3 sources optimise livraison France :
/// - BAN (cadastre officiel) : adresses postales, tous les numeros.
/// - Recherche-Entreprises (SIRENE) : nom legal des entreprises FR.
/// - Photon (OSM) : enseignes / marques commerciales (Citroen,
///   Carrefour, McDo...) que SIRENE ne connait pas par leur enseigne.
///
/// Aucune cle API requise, aucune CB.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final cache = ref.watch(geocodeCacheRepositoryProvider);

  final service = FranceGeocodingService(
    ban: BanGeocodingService(cache: cache),
    entreprises: RechercheEntreprisesService(cache: cache),
    photon: PhotonService(cache: cache),
  );

  ref.onDispose(service.close);
  return service;
});

/// Service de re-geocodage en batch des arrets sauves en mode
/// hors-ligne (lat/lng null). Utilise par le bouton "Geolocaliser les
/// arrets hors ligne" dans la tournee du jour.
final stopsGeocodeRetryServiceProvider =
    Provider<StopsGeocodeRetryService>((ref) {
  return StopsGeocodeRetryService(
    repo: ref.watch(stopsRepositoryProvider),
    geocoder: ref.watch(geocodingServiceProvider),
  );
});
