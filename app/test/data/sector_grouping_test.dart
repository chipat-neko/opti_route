import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/sector_grouping.dart';

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

  Future<Stop> seed(String adresse) async {
    final id = await db
        .into(db.stops)
        .insert(StopsCompanion.insert(tourneeId: tId, adresseBrute: adresse));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('SectorGrouping (#290)', () {
    test('liste vide', () {
      expect(SectorGrouping.groupByPostalCode(const []), isEmpty);
    });

    test('extraction CP simple', () async {
      final a = await seed('12 rue X 28000 Chartres');
      final b = await seed('5 rue Y 28000 Chartres');
      final c = await seed('1 rue Z 78250 Versailles');
      final g = SectorGrouping.groupByPostalCode([a, b, c]);
      expect(g['28000'], hasLength(2));
      expect(g['78250'], hasLength(1));
    });

    test('CP introuvable -> ?', () async {
      final s = await seed('Place sans CP');
      final g = SectorGrouping.groupByPostalCode([s]);
      expect(g['?'], hasLength(1));
    });

    test('isolatedCps : CPs avec 1 seul stop', () async {
      final a = await seed('28000 Chartres');
      final b = await seed('28000 Chartres');
      final c = await seed('78250 Versailles');
      final d = await seed('sans CP');
      final isolated = SectorGrouping.isolatedCps([a, b, c, d]);
      expect(isolated, ['78250'], reason: '? est exclu');
    });
  });
}
