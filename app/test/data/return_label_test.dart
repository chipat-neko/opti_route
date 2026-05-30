import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/return_label.dart';

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
    String? raison,
    String? nom,
    String? tracking,
    int colis = 1,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '1 rue X 28000',
        statutLivraison: const Value('echec'),
        raisonEchec: Value(raison),
        nomClient: Value(nom),
        trackingNumbers: Value(tracking),
        nbColis: Value(colis)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('ReturnLabel.compose (#306)', () {
    test('contenu minimal', () async {
      final s = await seed();
      final label = ReturnLabel.compose(
        stop: s,
        when: DateTime(2026, 5, 30, 14, 7),
      );
      expect(label, contains('RETOUR DEPOT'));
      expect(label, contains('30/05/2026 14:07'));
      expect(label, contains('1 rue X 28000'));
      expect(label, contains('Colis  : 1'));
    });

    test('avec raison + nom + tracking', () async {
      final s = await seed(
        raison: 'absent',
        nom: 'M. A',
        tracking: '["FA1","FA2"]',
        colis: 2,
      );
      final label = ReturnLabel.compose(
          stop: s, when: DateTime(2026, 5, 1, 9, 0));
      expect(label, contains('ABSENT'));
      expect(label, contains('M. A'));
      expect(label, contains('FA1'));
      expect(label, contains('FA2'));
      expect(label, contains('Colis  : 2'));
    });

    test('raison defaut si null', () async {
      final s = await seed(raison: null);
      final label = ReturnLabel.compose(stop: s, when: DateTime(2026, 1, 1));
      expect(label, contains('NON DISTRIBUE'));
    });
  });
}
