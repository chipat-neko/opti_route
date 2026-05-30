import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/weekly_report.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<Tournee> mkT({int dist = 0}) async {
    final id = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48,
        pointDepartLng: 1,
        pointDepartLabel: 'D',
        distanceTotaleM: Value(dist)));
    return (db.select(db.tournees)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<Stop> mkS(int tId, String statut, {String? raison, int colis = 1}) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        statutLivraison: Value(statut),
        raisonEchec: Value(raison),
        nbColis: Value(colis)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('WeeklyReport.compose (#321)', () {
    test('rapport vide', () {
      final s = WeeklyReport.compose(
        weekStart: DateTime(2026, 5, 25),
        tournees: const [],
        allStops: const [],
      );
      expect(s, contains('25/05/2026'));
      expect(s, contains('Tournees    : 0'));
    });

    test('avec stats + detail echecs', () async {
      final t = await mkT(dist: 50000);
      final livre = await mkS(t.id, 'livre');
      final livre2 = await mkS(t.id, 'livre', colis: 2);
      final absent = await mkS(t.id, 'echec', raison: 'absent');
      final refuse = await mkS(t.id, 'echec', raison: 'refuse');
      final s = WeeklyReport.compose(
        weekStart: DateTime(2026, 5, 25),
        tournees: [t],
        allStops: [livre, livre2, absent, refuse],
      );
      expect(s, contains('Livres      : 2'));
      expect(s, contains('Echecs      : 2'));
      expect(s, contains('Tx reussite : 50.0%'));
      expect(s, contains('Colis total : 5'));
      expect(s, contains('50.0 km'));
      expect(s, contains('absent : 1'));
      expect(s, contains('refuse : 1'));
    });
  });
}
