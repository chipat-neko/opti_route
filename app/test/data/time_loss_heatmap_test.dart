import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/time_loss_heatmap.dart';

void main() {
  late AppDatabase db;
  late int tId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48,
        pointDepartLng: 1,
        pointDepartLabel: 'D'));
  });
  tearDown(() async => db.close());

  Future<Stop> seed(String adr, DateTime? livreLe) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: adr,
        statutLivraison: const Value('livre'),
        livreLe: Value(livreLe)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('TimeLossHeatmap.compute (#322)', () {
    test('vide -> vide', () {
      expect(
        TimeLossHeatmap.compute(stops: const [], etasPrevues: const {}),
        isEmpty,
      );
    });

    test('1 retard +20min sur 28000', () async {
      final s = await seed('28000 X', DateTime(2026, 5, 30, 14, 30));
      final m = TimeLossHeatmap.compute(
        stops: [s],
        etasPrevues: {s.id: DateTime(2026, 5, 30, 14, 10)},
      );
      expect(m['28000'], 20);
    });

    test('en avance -> ignore', () async {
      final s = await seed('28000 X', DateTime(2026, 5, 30, 14, 0));
      final m = TimeLossHeatmap.compute(
        stops: [s],
        etasPrevues: {s.id: DateTime(2026, 5, 30, 14, 30)},
      );
      expect(m, isEmpty);
    });

    test('top trie descendant', () async {
      final s1 = await seed('28000 X', DateTime(2026, 5, 30, 14, 30));
      final s2 = await seed('78250 Y', DateTime(2026, 5, 30, 15, 5));
      final m = TimeLossHeatmap.top(
        [s1, s2],
        {
          s1.id: DateTime(2026, 5, 30, 14, 10), // +20 min
          s2.id: DateTime(2026, 5, 30, 15, 0), // +5 min
        },
      );
      expect(m.first.cp, '28000');
      expect(m.first.minutesLoss, 20);
    });
  });
}
