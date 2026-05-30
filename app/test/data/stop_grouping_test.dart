import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stop_grouping.dart';

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
    required String adresse,
    double? lat,
    double? lng,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: adresse,
        lat: lat != null ? Value(lat) : const Value.absent(),
        lng: lng != null ? Value(lng) : const Value.absent()));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('StopGrouping.compute (#282)', () {
    test('liste vide -> vide', () {
      expect(StopGrouping.compute(const []), isEmpty);
    });

    test('memes coords < 50m -> 1 groupe', () async {
      final a = await seed(adresse: 'rue X 1', lat: 48.0, lng: 1.0);
      final b = await seed(adresse: 'rue X 2', lat: 48.00003, lng: 1.0);
      final groups = StopGrouping.compute([a, b]);
      expect(groups, hasLength(1));
      expect(groups.first, hasLength(2));
    });

    test('memes adresses (normalisees) -> 1 groupe', () async {
      final a = await seed(adresse: '12 Rue Aristide Briand');
      final b = await seed(adresse: '  12 RUE   Aristide  Briand  ');
      final groups = StopGrouping.compute([a, b]);
      expect(groups, hasLength(1));
    });

    test('adresses differentes + coords distantes -> n groupes', () async {
      final a = await seed(adresse: 'rue A', lat: 48.0, lng: 1.0);
      final b = await seed(adresse: 'rue B', lat: 48.5, lng: 1.0);
      final c = await seed(adresse: 'rue C', lat: 49.0, lng: 1.0);
      final groups = StopGrouping.compute([a, b, c]);
      expect(groups, hasLength(3));
    });

    test('preserve l\'ordre du 1er stop par groupe', () async {
      final a = await seed(adresse: 'X', lat: 48.0, lng: 1.0);
      final b = await seed(adresse: 'Y', lat: 49.0, lng: 1.0);
      final c = await seed(adresse: 'X bis', lat: 48.0001, lng: 1.0);
      final groups = StopGrouping.compute([a, b, c]);
      expect(groups, hasLength(2));
      expect(groups.first.first.id, a.id);
      expect(groups.first.last.id, c.id, reason: 'c regroupe avec a');
      expect(groups.last.first.id, b.id);
    });
  });
}
