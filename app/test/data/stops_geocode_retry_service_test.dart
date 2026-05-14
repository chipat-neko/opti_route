import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/geocoding_service.dart';
import 'package:opti_route/data/stops_geocode_retry_service.dart';
import 'package:opti_route/data/stops_repository.dart';

void main() {
  group('StopsGeocodeRetryService.retryFor', () {
    late AppDatabase db;
    late StopsRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StopsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTourneeWithStops(
      List<({String adr, bool hasCoords})> specs,
    ) async {
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      for (final s in specs) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: id,
                adresseBrute: s.adr,
                lat: s.hasCoords ? const Value(48.5) : const Value.absent(),
                lng: s.hasCoords ? const Value(1.5) : const Value.absent(),
              ),
            );
      }
      return id;
    }

    test('aucun stop sans coords : retourne 0', () async {
      final id = await seedTourneeWithStops([
        (adr: 'A', hasCoords: true),
        (adr: 'B', hasCoords: true),
      ]);
      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.allResolveTo(48.7, 1.3),
        db: db,
      );
      final res = await svc.retryFor(id);
      expect(res.totalCandidats, 0);
      expect(res.resolved, isEmpty);
      expect(res.unresolved, isEmpty);
    });

    test('1 sans coords + geocoder ok : resolved met a jour la DB',
        () async {
      final id = await seedTourneeWithStops([
        (adr: 'A', hasCoords: true),
        (adr: '12 rue offline, Dreux', hasCoords: false),
      ]);
      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.allResolveTo(48.7372, 1.3661),
        db: db,
      );
      final res = await svc.retryFor(id);
      expect(res.totalCandidats, 1);
      expect(res.resolved, hasLength(1));
      expect(res.unresolved, isEmpty);

      // Verifie la persistance en DB.
      final all = await repo.getByTournee(id);
      final updated =
          all.firstWhere((s) => s.adresseBrute == '12 rue offline, Dreux');
      expect(updated.lat, 48.7372);
      expect(updated.lng, 1.3661);
    });

    test('geocoder ne trouve rien : unresolved', () async {
      final id = await seedTourneeWithStops([
        (adr: 'adresse fantasque', hasCoords: false),
      ]);
      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.alwaysEmpty(),
        db: db,
      );
      final res = await svc.retryFor(id);
      expect(res.totalCandidats, 1);
      expect(res.resolved, isEmpty);
      expect(res.unresolved, hasLength(1));

      final all = await repo.getByTournee(id);
      final stop = all.first;
      expect(stop.lat, isNull);
      expect(stop.lng, isNull);
    });

    test('BatchGeocodeResult conserve les listes resolved/unresolved',
        () async {
      const r = BatchGeocodeResult(
        totalCandidats: 3,
        resolved: [],
        unresolved: [],
      );
      expect(r.totalCandidats, 3);
      expect(r.resolved, isEmpty);
      expect(r.unresolved, isEmpty);
    });

    test('mixed : resolved + unresolved dans le meme batch', () async {
      final id = await seedTourneeWithStops([
        (adr: 'OK adresse Dreux', hasCoords: false),
        (adr: 'XX inexistant', hasCoords: false),
      ]);
      // Stub qui ne resoud que si la query contient "OK"
      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubFiltered(matcher: (q) => q.contains('OK')),
        db: db,
      );
      final r = await svc.retryFor(id);
      expect(r.totalCandidats, 2);
      expect(r.resolved, hasLength(1));
      expect(r.unresolved, hasLength(1));
    });

    test('geocoder throw : unresolved, ne casse pas la boucle', () async {
      final id = await seedTourneeWithStops([
        (adr: 'A offline', hasCoords: false),
        (adr: 'B offline', hasCoords: false),
      ]);
      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.alwaysThrow(),
        db: db,
      );
      final res = await svc.retryFor(id);
      expect(res.totalCandidats, 2);
      expect(res.resolved, isEmpty);
      expect(res.unresolved, hasLength(2));
    });
  });

  group('StopsGeocodeRetryService.retryAllPending + countPending', () {
    late AppDatabase db;
    late StopsRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StopsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee(
      List<({String adr, bool hasCoords})> specs, {
      int? tourneeIdSuffix,
    }) async {
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T${tourneeIdSuffix ?? ""}',
              date: DateTime(2026, 5, 14),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      for (final s in specs) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: id,
                adresseBrute: s.adr,
                lat: s.hasCoords ? const Value(48.5) : const Value.absent(),
                lng: s.hasCoords ? const Value(1.5) : const Value.absent(),
              ),
            );
      }
      return id;
    }

    test('countPending : nombre total de stops sans coords toutes tournees',
        () async {
      await seedTournee([
        (adr: 'A', hasCoords: true),
        (adr: 'B', hasCoords: false),
      ], tourneeIdSuffix: 1);
      await seedTournee([
        (adr: 'C', hasCoords: false),
        (adr: 'D', hasCoords: false),
        (adr: 'E', hasCoords: true),
      ], tourneeIdSuffix: 2);

      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.allResolveTo(48.7, 1.3),
        db: db,
      );
      expect(await svc.countPending(), 3);
    });

    test('retryAllPending : traite TOUS les stops sans coords', () async {
      await seedTournee([
        (adr: 'Tournee 1 - manquant', hasCoords: false),
      ], tourneeIdSuffix: 1);
      await seedTournee([
        (adr: 'Tournee 2 - manquant', hasCoords: false),
        (adr: 'Tournee 2 - OK', hasCoords: true),
      ], tourneeIdSuffix: 2);

      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.allResolveTo(48.7, 1.3),
        db: db,
      );
      final result = await svc.retryAllPending();
      expect(result.totalCandidats, 2,
          reason: '2 stops sans coords trouves entre les 2 tournees');
      expect(result.resolved, hasLength(2));
      // Apres retry, plus rien en attente.
      expect(await svc.countPending(), 0);
    });

    test('retryAllPending : 0 candidats si tout est deja geocode',
        () async {
      await seedTournee([
        (adr: 'A', hasCoords: true),
        (adr: 'B', hasCoords: true),
      ]);
      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.alwaysThrow(), // pas appele
        db: db,
      );
      final result = await svc.retryAllPending();
      expect(result.totalCandidats, 0);
      expect(result.resolved, isEmpty);
      expect(result.unresolved, isEmpty);
    });
  });
}

/// Stub qui resoud uniquement les queries qui matchent un predicat.
class _StubFiltered implements GeocodingService {
  _StubFiltered({required this.matcher});

  final bool Function(String query) matcher;

  @override
  String get providerKey => 'stub_filtered';

  @override
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 10,
    String acceptLanguage = 'fr-FR',
  }) async {
    if (!matcher(query)) return const [];
    return [
      const AddressSuggestion(
        displayName: 'resolved',
        lat: 48.7,
        lon: 1.3,
      ),
    ];
  }

  @override
  void close() {}
}

class _StubGeocoder implements GeocodingService {
  _StubGeocoder._({this.resolveTo, this.throws = false});

  factory _StubGeocoder.allResolveTo(double lat, double lon) =>
      _StubGeocoder._(resolveTo: AddressSuggestion(
        displayName: '$lat,$lon',
        lat: lat,
        lon: lon,
      ));

  factory _StubGeocoder.alwaysEmpty() => _StubGeocoder._();

  factory _StubGeocoder.alwaysThrow() => _StubGeocoder._(throws: true);

  final AddressSuggestion? resolveTo;
  final bool throws;

  @override
  String get providerKey => 'stub';

  @override
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 10,
    String acceptLanguage = 'fr-FR',
  }) async {
    if (throws) throw const GeocodingException('stub error');
    if (resolveTo == null) return const [];
    return [resolveTo!];
  }

  @override
  void close() {}
}
