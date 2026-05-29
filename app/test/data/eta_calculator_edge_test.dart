import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/eta_calculator.dart';

// Complete eta_calculator_test : boundaries des labels distance/duree,
// avgSpeedKmh degenere, edge dates formatEtaHHmm, computeEtas avec
// dureeTotaleS=0, computeSegments avec stops melanges.
void main() {
  group('SegmentInfo.distanceLabel — boundaries', () {
    test('exactement 1000 m -> "1.0 km" (bascule km)', () {
      const s = SegmentInfo(
        meters: 1000,
        duration: Duration(minutes: 2),
        fromDepot: true,
      );
      expect(s.distanceLabel, '1.0 km');
    });

    test('999 m -> "999 m"', () {
      const s = SegmentInfo(
        meters: 999,
        duration: Duration(minutes: 1),
        fromDepot: true,
      );
      expect(s.distanceLabel, '999 m');
    });

    test('1250 m -> "1.3 km" (1 decimale arrondie)', () {
      const s = SegmentInfo(
        meters: 1250,
        duration: Duration(minutes: 3),
        fromDepot: true,
      );
      expect(s.distanceLabel, '1.3 km');
    });

    test('0 m -> "0 m"', () {
      const s = SegmentInfo(
        meters: 0,
        duration: Duration.zero,
        fromDepot: false,
      );
      expect(s.distanceLabel, '0 m');
    });
  });

  group('SegmentInfo.durationLabel — boundaries', () {
    test('exactement 60 min -> "1h00"', () {
      const s = SegmentInfo(
        meters: 30000,
        duration: Duration(minutes: 60),
        fromDepot: true,
      );
      expect(s.durationLabel, '1h00');
    });

    test('59 min -> "59 min"', () {
      const s = SegmentInfo(
        meters: 30000,
        duration: Duration(minutes: 59),
        fromDepot: true,
      );
      expect(s.durationLabel, '59 min');
    });

    test('65 min -> "1h05" (zero-pad minutes)', () {
      const s = SegmentInfo(
        meters: 50000,
        duration: Duration(minutes: 65),
        fromDepot: true,
      );
      expect(s.durationLabel, '1h05');
    });

    test('0 min -> "0 min"', () {
      const s = SegmentInfo(
        meters: 0,
        duration: Duration.zero,
        fromDepot: false,
      );
      expect(s.durationLabel, '0 min');
    });
  });

  group('EtaCalculator.formatEtaHHmm — limites', () {
    test('minuit pile : 00:00', () {
      expect(
        EtaCalculator.formatEtaHHmm(DateTime(2026, 5, 30)),
        '00:00',
      );
    });

    test('23:59:59 -> "23:59" (drop secondes)', () {
      expect(
        EtaCalculator.formatEtaHHmm(DateTime(2026, 5, 30, 23, 59, 59)),
        '23:59',
      );
    });

    test('5:30 (chiffre unique heure) -> "05:30" (zero-pad)', () {
      expect(
        EtaCalculator.formatEtaHHmm(DateTime(2026, 5, 30, 5, 30)),
        '05:30',
      );
    });
  });

  group('EtaCalculator.computeSegments — degeneres', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee() {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 29),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
    }

    Future<Stop> seedStop({
      required int tId,
      double? lat,
      double? lng,
      String statut = 'a_livrer',
    }) async {
      final id = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
              lat: lat != null ? Value(lat) : const Value.absent(),
              lng: lng != null ? Value(lng) : const Value.absent(),
            ),
          );
      if (statut != 'a_livrer') {
        final row = await (db.select(db.stops)
              ..where((s) => s.id.equals(id)))
            .getSingle();
        await db.update(db.stops).replace(
              row.copyWith(statutLivraison: statut),
            );
      }
      return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
    }

    test('avgSpeedKmh = 0 : fallback a 30 km/h (pas de div par 0)',
        () async {
      final t = await seedTournee();
      final s = await seedStop(tId: t, lat: 48.01, lng: 1.0);
      final segs = EtaCalculator.computeSegments(
        orderedStops: [s],
        depotLat: 48.0,
        depotLng: 1.0,
        avgSpeedKmh: 0,
      );
      expect(segs[s.id], isNotNull);
      // ~1.11 km a 30 km/h ~= 133 s
      expect(segs[s.id]!.duration.inSeconds, greaterThan(0));
    });

    test('avgSpeedKmh negatif : fallback a 30 km/h', () async {
      final t = await seedTournee();
      final s = await seedStop(tId: t, lat: 48.01, lng: 1.0);
      final segs = EtaCalculator.computeSegments(
        orderedStops: [s],
        depotLat: 48.0,
        depotLng: 1.0,
        avgSpeedKmh: -100,
      );
      expect(segs[s.id]!.duration.inSeconds, greaterThan(0));
    });

    test('liste vide -> map vide', () {
      final segs = EtaCalculator.computeSegments(
        orderedStops: const [],
        depotLat: 48.0,
        depotLng: 1.0,
      );
      expect(segs, isEmpty);
    });

    test('tous livre/echec -> map vide (rien a livrer)', () async {
      final t = await seedTournee();
      final s1 = await seedStop(tId: t, lat: 48.01, lng: 1.0, statut: 'livre');
      final s2 =
          await seedStop(tId: t, lat: 48.02, lng: 1.0, statut: 'echec');
      final segs = EtaCalculator.computeSegments(
        orderedStops: [s1, s2],
        depotLat: 48.0,
        depotLng: 1.0,
      );
      expect(segs, isEmpty);
    });

    test('mix livre+a_livrer : segment du a_livrer suivant utilise le prev a_livrer',
        () async {
      // ordre : s1 a_livrer (48.01) -> s2 livre (48.02, exclu) ->
      //         s3 a_livrer (48.03). Le segment de s3 doit partir de s1,
      //         PAS de s2 (puisque s2 est skip) -- attention au code :
      //         prevLat/Lng se met a jour SEULEMENT quand on emet un
      //         segment, donc oui, s3 part de s1.
      final t = await seedTournee();
      final s1 = await seedStop(tId: t, lat: 48.01, lng: 1.0);
      final s2 =
          await seedStop(tId: t, lat: 48.02, lng: 1.0, statut: 'livre');
      final s3 = await seedStop(tId: t, lat: 48.03, lng: 1.0);
      final segs = EtaCalculator.computeSegments(
        orderedStops: [s1, s2, s3],
        depotLat: 48.0,
        depotLng: 1.0,
      );
      expect(segs.length, 2);
      expect(segs[s1.id]!.fromDepot, isTrue);
      expect(segs[s3.id]!.fromDepot, isFalse);
      // s3 doit etre proche du s1, pas du depot ni de s2
      // Distance s1->s3 = ~2.2 km, depot->s3 = ~3.3 km
      expect(segs[s3.id]!.meters, lessThan(3000));
    });
  });

  group('EtaCalculator.computeEtas — limites', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee() {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 29),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
    }

    Future<Stop> seedStop({
      required int tId,
      int dureeArretMin = 5,
    }) async {
      final id = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
              dureeArretMin: Value(dureeArretMin),
            ),
          );
      return (db.select(db.stops)..where((s) => s.id.equals(id)))
          .getSingle();
    }

    test('dureeTotaleS=0 : avgDriveS=0 -> ETAs successives + dureeArret',
        () async {
      final t = await seedTournee();
      final s1 = await seedStop(tId: t, dureeArretMin: 5);
      final s2 = await seedStop(tId: t, dureeArretMin: 5);
      final startAt = DateTime(2026, 5, 29, 8, 0);
      final etas = EtaCalculator.computeEtas(
        startAt: startAt,
        orderedStops: [s1, s2],
        dureeTotaleS: 0,
      );
      // avgDriveS = 0 -> ETA s1 = startAt, s2 = startAt + 5 min (l'arret de s1)
      expect(etas[s1.id], startAt);
      expect(etas[s2.id], startAt.add(const Duration(minutes: 5)));
    });
  });
}
