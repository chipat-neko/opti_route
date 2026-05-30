import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/recap_depot.dart';

void main() {
  late AppDatabase db;
  late int tourneeId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tourneeId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 5, 30),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Stop> seed({
    required String type,
    required String statutLivraison,
    int nbColis = 1,
  }) async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'A',
            type: Value(type),
            nbColis: Value(nbColis),
            statutLivraison: Value(statutLivraison),
          ),
        );
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('RecapDepot.compute', () {
    test('aucun stop -> tout vide + rien a rapporter', () {
      final r = RecapDepot.compute(const []);
      expect(r.echecsARendre, isEmpty);
      expect(r.ramassesRecuperees, isEmpty);
      expect(r.totalColis, 0);
      expect(r.aQuelqueChose, isFalse);
    });

    test('livraison echec -> echecsARendre', () async {
      final s = await seed(
        type: 'livraison',
        statutLivraison: 'echec',
        nbColis: 3,
      );
      final r = RecapDepot.compute([s]);
      expect(r.echecsARendre, hasLength(1));
      expect(r.ramassesRecuperees, isEmpty);
      expect(r.totalColis, 3);
      expect(r.aQuelqueChose, isTrue);
    });

    test('ramasse livre -> ramassesRecuperees', () async {
      final s = await seed(
        type: 'ramasse',
        statutLivraison: 'livre',
        nbColis: 2,
      );
      final r = RecapDepot.compute([s]);
      expect(r.echecsARendre, isEmpty);
      expect(r.ramassesRecuperees, hasLength(1));
      expect(r.totalColis, 2);
    });

    test('livraison livre -> ignore (deja remis au client)', () async {
      final s = await seed(
        type: 'livraison',
        statutLivraison: 'livre',
        nbColis: 5,
      );
      final r = RecapDepot.compute([s]);
      expect(r.aQuelqueChose, isFalse);
      expect(r.totalColis, 0);
    });

    test('ramasse echec -> ignore (n\'a pas ete pris)', () async {
      final s = await seed(
        type: 'ramasse',
        statutLivraison: 'echec',
        nbColis: 5,
      );
      final r = RecapDepot.compute([s]);
      expect(r.aQuelqueChose, isFalse);
    });

    test('a_livrer -> ignore (pas valide donc pas dans le camion)',
        () async {
      final s = await seed(
        type: 'livraison',
        statutLivraison: 'a_livrer',
      );
      final r = RecapDepot.compute([s]);
      expect(r.aQuelqueChose, isFalse);
    });

    test('mix : echecs + ramasses + livres + a_livrer', () async {
      final e1 = await seed(
          type: 'livraison', statutLivraison: 'echec', nbColis: 2);
      final e2 = await seed(
          type: 'livraison', statutLivraison: 'echec', nbColis: 1);
      final r1 = await seed(
          type: 'ramasse', statutLivraison: 'livre', nbColis: 4);
      final r2 = await seed(
          type: 'ramasse', statutLivraison: 'livre', nbColis: 1);
      final ignored1 =
          await seed(type: 'livraison', statutLivraison: 'livre', nbColis: 99);
      final ignored2 =
          await seed(type: 'livraison', statutLivraison: 'a_livrer');
      final r = RecapDepot.compute([e1, e2, r1, ignored1, r2, ignored2]);
      expect(r.echecsARendre, hasLength(2));
      expect(r.ramassesRecuperees, hasLength(2));
      expect(r.totalColis, 2 + 1 + 4 + 1, reason: '99 livre + 1 a_livrer exclus');
    });
  });
}
