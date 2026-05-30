import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/client_history_stats.dart';
import 'package:opti_route/data/database.dart';

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
    required String statut,
    DateTime? livreLe,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        statutLivraison: Value(statut),
        livreLe: Value(livreLe)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('ClientHistoryStats (#294)', () {
    test('liste vide -> stats zero', () {
      final s = ClientHistoryStats.compute(const []);
      expect(s.totalPassages, 0);
      expect(s.tauxReussite, 0);
      expect(s.bestHour, isNull);
    });

    test('mix livre/echec -> taux et best hour', () async {
      final livre10 = await seed(
          statut: 'livre', livreLe: DateTime(2026, 5, 1, 10));
      final livre10b = await seed(
          statut: 'livre', livreLe: DateTime(2026, 5, 2, 10));
      final echec18 = await seed(
          statut: 'echec', livreLe: DateTime(2026, 5, 3, 18));
      final pending = await seed(statut: 'a_livrer');
      final s = ClientHistoryStats.compute([livre10, livre10b, echec18, pending]);
      expect(s.totalPassages, 3, reason: 'pending exclu');
      expect(s.livres, 2);
      expect(s.echecs, 1);
      expect(s.tauxReussite, closeTo(2 / 3, 0.001));
      expect(s.bestHour, 10);
      expect(s.worstHour, 18);
    });

    test('aucun acte (que pending) -> stats vides', () async {
      final p = await seed(statut: 'a_livrer');
      final s = ClientHistoryStats.compute([p]);
      expect(s.totalPassages, 0);
      expect(s.bestHour, isNull);
    });
  });
}
