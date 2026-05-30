import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/poi_detour.dart';

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

  Future<Stop> seed({required double lat, required double lng}) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        lat: Value(lat),
        lng: Value(lng)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('PoiDetour.bestInsertionIndex (#299)', () {
    test('aucun pending -> index 0', () async {
      expect(
        PoiDetour.bestInsertionIndex(
          origin: (48, 1),
          pending: const [],
          poi: (48.5, 1),
        ),
        0,
      );
    });

    test('POI proche de l\'origine -> index 0', () async {
      final s1 = await seed(lat: 48.1, lng: 1.0);
      final s2 = await seed(lat: 48.2, lng: 1.0);
      final idx = PoiDetour.bestInsertionIndex(
        origin: (48, 1),
        pending: [s1, s2],
        poi: (48.005, 1), // ~5m de origin
      );
      expect(idx, 0);
    });

    test('POI proche du dernier stop -> index = length', () async {
      final s1 = await seed(lat: 48.1, lng: 1.0);
      final s2 = await seed(lat: 48.2, lng: 1.0);
      final idx = PoiDetour.bestInsertionIndex(
        origin: (48, 1),
        pending: [s1, s2],
        poi: (48.201, 1), // ~100m apres s2
      );
      expect(idx, 2);
    });
  });
}
