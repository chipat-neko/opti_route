import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/client_window_suggestion.dart';
import 'package:opti_route/data/database.dart';

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

  Future<Stop> seed(String statut, DateTime livreLe) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        statutLivraison: Value(statut),
        livreLe: Value(livreLe)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('ClientWindowSuggestion.compute (#323)', () {
    test('<3 hits -> null', () async {
      final s1 = await seed('livre', DateTime(2026, 5, 1, 10));
      final s2 = await seed('livre', DateTime(2026, 5, 2, 11));
      expect(ClientWindowSuggestion.compute([s1, s2]), isNull);
    });

    test('3 hits 10/11/12 -> 10:00-13:00', () async {
      final s1 = await seed('livre', DateTime(2026, 5, 1, 10));
      final s2 = await seed('livre', DateTime(2026, 5, 2, 11));
      final s3 = await seed('livre', DateTime(2026, 5, 3, 12));
      final out = ClientWindowSuggestion.compute([s1, s2, s3]);
      expect(out, isNotNull);
      expect(out!.fenetreDebut, '10:00');
      expect(out.fenetreFin, '13:00');
      expect(out.basedOnHits, 3);
    });

    test('echecs ignores', () async {
      final s1 = await seed('echec', DateTime(2026, 5, 1, 8));
      final s2 = await seed('livre', DateTime(2026, 5, 2, 14));
      final s3 = await seed('livre', DateTime(2026, 5, 3, 15));
      final s4 = await seed('livre', DateTime(2026, 5, 4, 16));
      final out = ClientWindowSuggestion.compute([s1, s2, s3, s4]);
      expect(out!.fenetreDebut, '14:00');
      expect(out.fenetreFin, '17:00');
    });
  });
}
