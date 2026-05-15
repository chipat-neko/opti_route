import 'package:drift/drift.dart' show countAll;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ban_geocoding_service.dart';
import '../data/france_geocoding_service.dart';
import '../data/geocode_cache_repository.dart';
import '../data/geocoding_service.dart';
import '../data/offline_geocode_automation.dart';
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
/// Aucune cle API requise, aucune CB. **Reutilise l'instance BAN
/// existante** (cf banGeocodingServiceProvider) plutot que d'en
/// instancier une 2e -- evite de dupliquer le connection pool HTTP
/// et de surcharger la BAN avec 2x les User-Agents.
final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  final cache = ref.watch(geocodeCacheRepositoryProvider);
  final ban = ref.watch(banGeocodingServiceProvider);

  final entreprises = RechercheEntreprisesService(cache: cache);
  final photon = PhotonService(cache: cache);

  final service = FranceGeocodingService(
    ban: ban,
    entreprises: entreprises,
    photon: photon,
  );

  // Note : `service.close()` fermerait aussi `ban`, qui est partage
  // avec banGeocodingServiceProvider. Pour eviter le double-close, on
  // ne libere ici QUE entreprises + photon ; ban est dispose par son
  // propre Provider quand l'app se termine.
  ref.onDispose(() {
    entreprises.close();
    photon.close();
  });
  return service;
});

/// Service de re-geocodage en batch des arrets sauves en mode
/// hors-ligne (lat/lng null). Utilise par :
/// - le bouton "Geolocaliser les arrets hors ligne" dans la tournee
///   du jour (manuel, [StopsGeocodeRetryService.retryFor])
/// - [offlineGeocodeAutomationProvider] qui surveille la connectivite
///   et appelle [StopsGeocodeRetryService.retryAllPending] au retour
///   du reseau.
final stopsGeocodeRetryServiceProvider =
    Provider<StopsGeocodeRetryService>((ref) {
  return StopsGeocodeRetryService(
    repo: ref.watch(stopsRepositoryProvider),
    geocoder: ref.watch(geocodingServiceProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

/// Automate qui declenche le retry geocodage au retour de connectivite.
/// **Auto-start a la 1ere lecture** : il suffit qu'un Consumer
/// `ref.read(offlineGeocodeAutomationProvider)` quelque part dans
/// l'arbre (typiquement HomeScreen ou main) pour que l'observation
/// demarre. Stop au dispose du Provider (fin d'app).
final offlineGeocodeAutomationProvider =
    Provider<OfflineGeocodeAutomation>((ref) {
  final automation = OfflineGeocodeAutomation(
    retryService: ref.watch(stopsGeocodeRetryServiceProvider),
  );
  automation.start();
  ref.onDispose(automation.stop);
  return automation;
});

/// Compteur live du nombre d'arrets en attente de geocodage (lat null).
/// Watche par les badges UI pour afficher "N arrets sans GPS".
/// Stream Drift -> mise a jour instantanee a chaque add/edit/delete.
///
/// COUNT(*) cote SQLite plutot que .map(.length) sur la liste des
/// stops : evite de charger toutes les rows en RAM a chaque tick
/// (sur 5000 stops sans GPS, ca devient sensible).
final pendingGeocodeCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final col = countAll();
  final query = db.selectOnly(db.stops)
    ..addColumns([col])
    ..where(db.stops.lat.isNull());
  return query.watchSingle().map((row) => row.read(col) ?? 0);
});
