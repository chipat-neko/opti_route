import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/eta_calculator.dart';

void main() {
  group('EtaCalculator.computeEtas', () {
    late AppDatabase db;
    late int tourneeId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<Stop>> seedStops(List<String> statuts) async {
      for (var i = 0; i < statuts.length; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tourneeId,
                adresseBrute: 'stop-$i',
                statutLivraison: Value(statuts[i]),
                dureeArretMin: const Value(3),
              ),
            );
      }
      return (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(tourneeId))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();
    }

    test('liste vide : map vide', () {
      final etas = EtaCalculator.computeEtas(
        startAt: DateTime(2026, 5, 12, 8, 0),
        orderedStops: const [],
        dureeTotaleS: 3600,
      );
      expect(etas, isEmpty);
    });

    test('tous deja livres : map vide', () async {
      final stops = await seedStops(['livre', 'livre']);
      final etas = EtaCalculator.computeEtas(
        startAt: DateTime(2026, 5, 12, 8, 0),
        orderedStops: stops,
      );
      expect(etas, isEmpty);
    });

    test('3 a_livrer + dureeTotaleS 3600 : ETA reparties', () async {
      // 3 stops, 3600s = 1h totale. Avg drive = 1200s = 20 min
      // + dureeArretMin = 3 min entre chaque
      // Start 08:00
      // Stop 1 : 08:00 + 20min = 08:20
      // Stop 2 : 08:20 + 3min (arret) + 20min (drive) = 08:43
      // Stop 3 : 08:43 + 3min + 20min = 09:06
      final stops = await seedStops(['a_livrer', 'a_livrer', 'a_livrer']);
      final etas = EtaCalculator.computeEtas(
        startAt: DateTime(2026, 5, 12, 8, 0),
        orderedStops: stops,
        dureeTotaleS: 3600,
      );
      expect(etas.length, 3);
      expect(EtaCalculator.formatEtaHHmm(etas[stops[0].id]!), '08:20');
      expect(EtaCalculator.formatEtaHHmm(etas[stops[1].id]!), '08:43');
      expect(EtaCalculator.formatEtaHHmm(etas[stops[2].id]!), '09:06');
    });

    test('mix livres + a_livrer : ne calcule que pour a_livrer', () async {
      final stops = await seedStops(['livre', 'a_livrer', 'a_livrer']);
      final etas = EtaCalculator.computeEtas(
        startAt: DateTime(2026, 5, 12, 8, 0),
        orderedStops: stops,
        dureeTotaleS: 1800,
      );
      expect(etas.length, 2);
      // Le livre n'est pas dans la map
      expect(etas.containsKey(stops[0].id), isFalse);
    });

    test('dureeTotaleS null : utilise 10 min par defaut entre arrets',
        () async {
      final stops = await seedStops(['a_livrer']);
      final etas = EtaCalculator.computeEtas(
        startAt: DateTime(2026, 5, 12, 8, 0),
        orderedStops: stops,
        // dureeTotaleS absent
      );
      // 08:00 + 10 min (defaut) = 08:10
      expect(EtaCalculator.formatEtaHHmm(etas[stops[0].id]!), '08:10');
    });
  });

  group('EtaCalculator.formatEtaHHmm', () {
    test('format basique', () {
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 5, 12, 8, 5)),
          '08:05');
    });

    test('zero-pad heures et minutes', () {
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 5, 12, 0, 0)),
          '00:00');
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 5, 12, 9, 9)),
          '09:09');
    });

    test('minuit 23:59', () {
      expect(EtaCalculator.formatEtaHHmm(DateTime(2026, 5, 12, 23, 59)),
          '23:59');
    });
  });
}
