import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/road_sheet.dart';

void main() {
  late AppDatabase db;
  late int tId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'Lundi 30/05',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'Depot Chartres'));
  });

  tearDown(() async => db.close());

  Future<Tournee> getTournee() async =>
      (db.select(db.tournees)..where((t) => t.id.equals(tId))).getSingle();

  Future<Stop> seed(String adresse,
      {String? nom, String? notes, int colis = 1}) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
          tourneeId: tId,
          adresseBrute: adresse,
          nomClient: Value(nom),
          notes: Value(notes),
          nbColis: Value(colis),
        ));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('RoadSheetGenerator.compose (#298)', () {
    test('en-tete + section vide si pas de stops', () async {
      final t = await getTournee();
      final s = RoadSheetGenerator.compose(tournee: t, orderedStops: const []);
      expect(s, contains('Lundi 30/05'));
      expect(s, contains('30/05/2026'));
      expect(s, contains('Depot Chartres'));
    });

    test('lignes par arret avec cases a cocher', () async {
      final a = await seed('12 rue X', nom: 'M. A', colis: 3);
      final b = await seed('5 rue Y', notes: 'sonner 3 fois');
      final t = await getTournee();
      final s = RoadSheetGenerator.compose(tournee: t, orderedStops: [a, b]);
      expect(s, contains('12 rue X'));
      expect(s, contains('5 rue Y'));
      expect(s, contains('client: M. A'));
      expect(s, contains('notes: sonner 3 fois'));
      expect(s, contains('[ ]'),
          reason: 'cases a cocher livre/echec');
    });

    test('adresse trop longue : tronquee', () async {
      final long = 'a' * 80;
      final s = await seed(long);
      final t = await getTournee();
      final str = RoadSheetGenerator.compose(tournee: t, orderedStops: [s]);
      expect(str, contains('...'));
    });
  });
}
