// Tests pour EtaCalculator : calcul ETA prorata + segments haversine.
// Pas de reseau, pas de DB : logique pure sur des objets Stop construits
// via un helper.

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/eta_calculator.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  late AppDatabase db;
  late StopsRepository stopsRepo;
  late TourneesRepository tournees;
  late int tourneeId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    stopsRepo = StopsRepository(db);
    tournees = TourneesRepository(db);
    tourneeId = await tournees.create(TourneesCompanion.insert(
      nom: 'T',
      date: DateTime(2026, 5, 27),
      pointDepartLat: 48.0,
      pointDepartLng: 1.0,
      pointDepartLabel: 'D',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<Stop> mkStop({
    required double lat,
    required double lng,
    String statut = 'a_livrer',
    int duree = 3,
  }) async {
    final id = await stopsRepo.create(StopsCompanion.insert(
      tourneeId: tourneeId,
      adresseBrute: 'X',
      lat: Value(lat),
      lng: Value(lng),
      dureeArretMin: Value(duree),
    ));
    if (statut == 'livre') {
      await stopsRepo.markLivre(id);
    } else if (statut == 'echec') {
      await stopsRepo.markEchec(id, 'absent');
    }
    return (await stopsRepo.getById(id))!;
  }

  group('EtaCalculator.computeEtas', () {
    test('aucun stop pending : retourne map vide', () {
      final etas = EtaCalculator.computeEtas(
        startAt: DateTime(2026, 5, 27, 8, 0),
        orderedStops: const [],
      );
      expect(etas, isEmpty);
    });

    test('3 stops pending : etalement prorata sans dureeTotale', () async {
      final s1 = await mkStop(lat: 48.0, lng: 1.0, duree: 3);
      final s2 = await mkStop(lat: 48.1, lng: 1.0, duree: 3);
      final s3 = await mkStop(lat: 48.2, lng: 1.0, duree: 3);
      final start = DateTime(2026, 5, 27, 8, 0);

      final etas = EtaCalculator.computeEtas(
        startAt: start,
        orderedStops: [s1, s2, s3],
      );

      expect(etas, hasLength(3));
      // Default 600s = 10 min de roulage entre chaque arret.
      // s1 : +10 min = 8:10
      expect(etas[s1.id], start.add(const Duration(minutes: 10)));
      // s2 : +10 (s1) + 3 (arret s1) + 10 = 8:23
      expect(etas[s2.id], start.add(const Duration(minutes: 23)));
      // s3 : +23 (s2) + 3 (arret s2) + 10 = 8:36
      expect(etas[s3.id], start.add(const Duration(minutes: 36)));
    });

    test('dureeTotaleS fourni : avgDriveS calcule prorata', () async {
      // dureeTotale 1800s sur 3 stops -> avg 600s par stop = 10 min.
      // Identique au cas default mais via le calcul prorata.
      final s1 = await mkStop(lat: 48.0, lng: 1.0, duree: 0);
      final s2 = await mkStop(lat: 48.1, lng: 1.0, duree: 0);
      final s3 = await mkStop(lat: 48.2, lng: 1.0, duree: 0);
      final start = DateTime(2026, 5, 27, 8, 0);

      final etas = EtaCalculator.computeEtas(
        startAt: start,
        orderedStops: [s1, s2, s3],
        dureeTotaleS: 1800,
      );

      expect(etas[s1.id], start.add(const Duration(minutes: 10)));
      expect(etas[s2.id], start.add(const Duration(minutes: 20)));
      expect(etas[s3.id], start.add(const Duration(minutes: 30)));
    });

    test('stops livres/echec exclus du calcul', () async {
      final livre = await mkStop(lat: 48.0, lng: 1.0, statut: 'livre');
      final pending = await mkStop(lat: 48.1, lng: 1.0);
      final start = DateTime(2026, 5, 27, 8, 0);

      final etas = EtaCalculator.computeEtas(
        startAt: start,
        orderedStops: [livre, pending],
      );

      expect(etas, hasLength(1));
      expect(etas.containsKey(livre.id), isFalse);
      expect(etas.containsKey(pending.id), isTrue);
    });
  });

  group('EtaCalculator.formatEtaHHmm', () {
    test('formatage HH:MM avec padding', () {
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 1, 1, 8, 5)),
          '08:05');
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 1, 1, 14, 30)),
          '14:30');
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 1, 1, 0, 0)),
          '00:00');
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 1, 1, 23, 59)),
          '23:59');
    });
  });

  group('EtaCalculator.computeSegments', () {
    test('1er stop : fromDepot=true, distance depuis depot', () async {
      final s = await mkStop(lat: 48.001, lng: 1.0);

      final segments = EtaCalculator.computeSegments(
        orderedStops: [s],
        depotLat: 48.0,
        depotLng: 1.0,
      );

      expect(segments, hasLength(1));
      expect(segments[s.id]!.fromDepot, isTrue);
      // 0.001 deg lat ~= 111 m. Tolerance ronde.
      expect(segments[s.id]!.meters, greaterThan(80));
      expect(segments[s.id]!.meters, lessThan(150));
    });

    test('stops suivants : fromDepot=false', () async {
      final s1 = await mkStop(lat: 48.001, lng: 1.0);
      final s2 = await mkStop(lat: 48.002, lng: 1.0);

      final segments = EtaCalculator.computeSegments(
        orderedStops: [s1, s2],
        depotLat: 48.0,
        depotLng: 1.0,
      );

      expect(segments[s1.id]!.fromDepot, isTrue);
      expect(segments[s2.id]!.fromDepot, isFalse);
    });

    test('stops livres/echec exclus', () async {
      final livre = await mkStop(lat: 48.001, lng: 1.0, statut: 'livre');
      final pending = await mkStop(lat: 48.002, lng: 1.0);

      final segments = EtaCalculator.computeSegments(
        orderedStops: [livre, pending],
        depotLat: 48.0,
        depotLng: 1.0,
      );

      expect(segments, hasLength(1));
      expect(segments.containsKey(livre.id), isFalse);
      // pending devient le 1er pending -> fromDepot=true (origine = depot).
      expect(segments[pending.id]!.fromDepot, isTrue);
    });

    test('stop sans coords : ignore', () async {
      // mkStop requiert lat/lng non-null donc je cree direct.
      final orphanId = await stopsRepo.create(StopsCompanion.insert(
        tourneeId: tourneeId,
        adresseBrute: 'sans GPS',
      ));
      final orphan = (await stopsRepo.getById(orphanId))!;
      final s = await mkStop(lat: 48.001, lng: 1.0);

      final segments = EtaCalculator.computeSegments(
        orderedStops: [orphan, s],
        depotLat: 48.0,
        depotLng: 1.0,
      );

      expect(segments.containsKey(orphan.id), isFalse);
      expect(segments.containsKey(s.id), isTrue);
    });

    test('duration calcule depuis vitesse moyenne', () async {
      // 1 km de distance -> 30 km/h donne 2 min = 120 sec.
      final s = await mkStop(lat: 48.009, lng: 1.0); // ~1 km au nord

      final segments = EtaCalculator.computeSegments(
        orderedStops: [s],
        depotLat: 48.0,
        depotLng: 1.0,
      );

      // Tolerance large : haversine et arrondi.
      expect(segments[s.id]!.duration.inSeconds, greaterThan(90));
      expect(segments[s.id]!.duration.inSeconds, lessThan(180));
    });
  });

  group('SegmentInfo labels', () {
    test('distanceLabel : "X m" si < 1000m, sinon "X.X km"', () {
      const a = SegmentInfo(
        meters: 250,
        duration: Duration(minutes: 1),
        fromDepot: false,
      );
      const b = SegmentInfo(
        meters: 1500,
        duration: Duration(minutes: 5),
        fromDepot: false,
      );
      const c = SegmentInfo(
        meters: 8200,
        duration: Duration(minutes: 15),
        fromDepot: true,
      );
      expect(a.distanceLabel, '250 m');
      expect(b.distanceLabel, '1.5 km');
      expect(c.distanceLabel, '8.2 km');
    });

    test('durationLabel : "X min" si <60, sinon "Xh0Y"', () {
      const a = SegmentInfo(
        meters: 100,
        duration: Duration(minutes: 5),
        fromDepot: false,
      );
      const b = SegmentInfo(
        meters: 100,
        duration: Duration(minutes: 65),
        fromDepot: false,
      );
      const c = SegmentInfo(
        meters: 100,
        duration: Duration(minutes: 120),
        fromDepot: false,
      );
      expect(a.durationLabel, '5 min');
      expect(b.durationLabel, '1h05');
      expect(c.durationLabel, '2h00');
    });
  });
}
