import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/failure_heatmap.dart';

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
    String statut = 'echec',
    DateTime? livreLe,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: adresse,
        statutLivraison: Value(statut),
        livreLe: Value(livreLe)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('FailureHeatmap (#302)', () {
    test('liste vide -> vide', () {
      expect(FailureHeatmap.compute(const []), isEmpty);
    });

    test('compte par (cp, hour) ; ignore livre', () async {
      final a = await seed(
          adresse: '28000 X', livreLe: DateTime(2026, 5, 1, 10));
      final b = await seed(
          adresse: '28000 Y', livreLe: DateTime(2026, 5, 2, 10));
      final c = await seed(
          adresse: '78250 Z', livreLe: DateTime(2026, 5, 3, 14));
      final livre = await seed(
          adresse: '28000 OK',
          statut: 'livre',
          livreLe: DateTime(2026, 5, 4, 10));
      final m = FailureHeatmap.compute([a, b, c, livre]);
      expect(m[(cp: '28000', hour: 10)], 2);
      expect(m[(cp: '78250', hour: 14)], 1);
      expect(m.length, 2, reason: 'livre exclu');
    });

    test('top limite + tri descendant', () async {
      // 3 echecs a 28000-10h, 1 a 78250-14h
      for (var i = 0; i < 3; i++) {
        await seed(adresse: '28000', livreLe: DateTime(2026, 5, i + 1, 10));
      }
      await seed(adresse: '78250', livreLe: DateTime(2026, 5, 10, 14));
      final top = FailureHeatmap.top([
        ...await (db.select(db.stops)).get(),
      ]);
      expect(top.first.count, 3);
      expect(top.first.cp, '28000');
    });
  });
}
