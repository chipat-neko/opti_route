import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/proximity_checker.dart';

void main() {
  late AppDatabase db;
  late int tId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D'));
  });

  tearDown(() async => db.close());

  Future<Stop> seed({
    double? lat,
    double? lng,
    String statut = 'a_livrer',
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        lat: lat != null ? Value(lat) : const Value.absent(),
        lng: lng != null ? Value(lng) : const Value.absent(),
        statutLivraison: Value(statut)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('ProximityChecker.findNearby (#285)', () {
    test('aucun stop proche -> vide', () async {
      final s = await seed(lat: 49.0, lng: 1.0);
      final hits = ProximityChecker.findNearby(
        currentLat: 48.0,
        currentLng: 1.0,
        stops: [s],
      );
      expect(hits, isEmpty);
    });

    test('< 80m -> trouve', () async {
      // ~50 m au nord
      final s = await seed(lat: 48.00045, lng: 1.0);
      final hits = ProximityChecker.findNearby(
        currentLat: 48.0,
        currentLng: 1.0,
        stops: [s],
      );
      expect(hits, hasLength(1));
      expect(hits.first.distanceMeters, lessThan(80));
    });

    test('livres/echecs ignores', () async {
      final livre = await seed(lat: 48.0, lng: 1.0, statut: 'livre');
      final echec = await seed(lat: 48.0, lng: 1.0, statut: 'echec');
      expect(
        ProximityChecker.findNearby(
            currentLat: 48.0, currentLng: 1.0, stops: [livre, echec]),
        isEmpty,
      );
    });

    test('stops sans coords ignores', () async {
      final s = await seed(lat: null, lng: null);
      expect(
        ProximityChecker.findNearby(
            currentLat: 48.0, currentLng: 1.0, stops: [s]),
        isEmpty,
      );
    });

    test('tri par distance croissante', () async {
      final loin = await seed(lat: 48.0005, lng: 1.0);
      final proche = await seed(lat: 48.0001, lng: 1.0);
      final tresProche = await seed(lat: 48.0, lng: 1.0);
      final hits = ProximityChecker.findNearby(
        currentLat: 48.0,
        currentLng: 1.0,
        stops: [loin, proche, tresProche],
      );
      expect(hits.map((h) => h.stop.id),
          [tresProche.id, proche.id, loin.id]);
    });

    test('radius override fonctionne', () async {
      final loin = await seed(lat: 48.001, lng: 1.0); // ~111 m
      expect(
        ProximityChecker.findNearby(
            currentLat: 48.0, currentLng: 1.0, stops: [loin]),
        isEmpty,
      );
      expect(
        ProximityChecker.findNearby(
            currentLat: 48.0,
            currentLng: 1.0,
            stops: [loin],
            radiusMeters: 200),
        hasLength(1),
      );
    });
  });
}
