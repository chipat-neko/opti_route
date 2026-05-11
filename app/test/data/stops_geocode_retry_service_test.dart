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

    test('geocoder throw : unresolved, ne casse pas la boucle', () async {
      final id = await seedTourneeWithStops([
        (adr: 'A offline', hasCoords: false),
        (adr: 'B offline', hasCoords: false),
      ]);
      final svc = StopsGeocodeRetryService(
        repo: repo,
        geocoder: _StubGeocoder.alwaysThrow(),
      );
      final res = await svc.retryFor(id);
      expect(res.totalCandidats, 2);
      expect(res.resolved, isEmpty);
      expect(res.unresolved, hasLength(2));
    });
  });
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
