import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/ramasse_bulk.dart';

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
    String type = 'livraison',
    String statut = 'a_livrer',
    int colis = 1,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        type: Value(type),
        statutLivraison: Value(statut),
        nbColis: Value(colis)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('RamasseBulkStats.compute (#303)', () {
    test('liste vide', () {
      final r = RamasseBulkStats.compute(const []);
      expect(r.totalRamasses, 0);
      expect(r.colisRecoltes, 0);
    });
    test('compte ramasses + recoltes + colis', () async {
      final r1 = await seed(type: 'ramasse', statut: 'livre', colis: 3);
      final r2 = await seed(type: 'ramasse', statut: 'livre', colis: 2);
      final r3 = await seed(type: 'ramasse', statut: 'a_livrer');
      final r4 = await seed(type: 'ramasse', statut: 'echec');
      final l = await seed(type: 'livraison', statut: 'livre', colis: 99);
      final r = RamasseBulkStats.compute([r1, r2, r3, r4, l]);
      expect(r.totalRamasses, 4);
      expect(r.recoltes, 2);
      expect(r.colisRecoltes, 5);
    });
  });
}
