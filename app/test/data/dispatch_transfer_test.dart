import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/dispatch_transfer.dart';

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

  Future<Stop> seed({String statut = 'a_livrer', int? coeq}) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        statutLivraison: Value(statut),
        coequipierId: Value(coeq)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('DispatchTransfer.validate (#333)', () {
    test('livre ou echec -> erreur', () async {
      final s = await seed(statut: 'livre');
      expect(
        DispatchTransfer.validate(stop: s, targetCoequipierId: 1),
        contains('deja valide'),
      );
    });
    test('deja affecte -> erreur', () async {
      final s = await seed(coeq: 5);
      expect(
        DispatchTransfer.validate(stop: s, targetCoequipierId: 5),
        contains('Deja affecte'),
      );
    });
    test('OK -> null', () async {
      final s = await seed(coeq: 3);
      expect(
        DispatchTransfer.validate(stop: s, targetCoequipierId: 5),
        isNull,
      );
    });
  });

  group('DispatchTransfer.countByCoequipier (#333)', () {
    test('groupe + null inclus', () async {
      final s1 = await seed(coeq: 1);
      final s2 = await seed(coeq: 1);
      final s3 = await seed(coeq: 2);
      final s4 = await seed();
      final c = DispatchTransfer.countByCoequipier([s1, s2, s3, s4]);
      expect(c[1], 2);
      expect(c[2], 1);
      expect(c[null], 1);
    });
  });
}
