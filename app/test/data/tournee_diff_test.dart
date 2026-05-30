import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tournee_diff.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<int> mkT({int? dist, int? duree}) {
    return db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48,
        pointDepartLng: 1,
        pointDepartLabel: 'D',
        distanceTotaleM: dist != null ? Value(dist) : const Value.absent(),
        dureeTotaleS: duree != null ? Value(duree) : const Value.absent()));
  }

  Future<Stop> mkS(int tId, String adr, {String statut = 'a_livrer'}) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: adr,
        statutLivraison: Value(statut)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<Tournee> getT(int id) =>
      (db.select(db.tournees)..where((t) => t.id.equals(id))).getSingle();

  group('TourneeDiff.compute (#319)', () {
    test('identique -> tout zero', () async {
      final tA = await mkT(dist: 10000, duree: 3600);
      final tB = await mkT(dist: 10000, duree: 3600);
      final a = await mkS(tA, 'rue X');
      final b = await mkS(tB, 'rue X');
      final d = TourneeDiff.compute(
        a: await getT(tA),
        stopsA: [a],
        b: await getT(tB),
        stopsB: [b],
      );
      expect(d.stopsAddedCount, 0);
      expect(d.distanceDeltaM, 0);
    });

    test('B a 2 stops en plus, +10km, +echec', () async {
      final tA = await mkT(dist: 10000, duree: 3600);
      final tB = await mkT(dist: 20000, duree: 3900);
      final a1 = await mkS(tA, 'rue X');
      final b1 = await mkS(tB, 'rue X', statut: 'echec');
      final b2 = await mkS(tB, 'rue Y');
      final b3 = await mkS(tB, 'rue Z');
      final d = TourneeDiff.compute(
        a: await getT(tA),
        stopsA: [a1],
        b: await getT(tB),
        stopsB: [b1, b2, b3],
      );
      expect(d.stopsAddedCount, 2);
      expect(d.distanceDeltaM, 10000);
      expect(d.dureeDeltaS, 300);
      expect(d.echecDeltaPct, closeTo(33.33, 0.1));
    });

    test('gainSensible si distance < -500m', () async {
      final tA = await mkT(dist: 10000, duree: 3600);
      final tB = await mkT(dist: 9000, duree: 3600);
      final d = TourneeDiff.compute(
        a: await getT(tA),
        stopsA: const [],
        b: await getT(tB),
        stopsB: const [],
      );
      expect(d.gainSensible, isTrue);
    });
  });
}
