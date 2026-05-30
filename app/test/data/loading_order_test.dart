import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/loading_order.dart';

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
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        type: Value(type),
        statutLivraison: Value(statut)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('LoadingOrder (#283)', () {
    test('compute : filtre livre/echec + type ramasse', () async {
      final s1 = await seed();
      final s2 = await seed(statut: 'livre');
      final s3 = await seed(type: 'ramasse');
      final s4 = await seed(statut: 'echec');
      final s5 = await seed();
      final out = LoadingOrder.compute([s1, s2, s3, s4, s5]);
      expect(out.map((s) => s.id), [s1.id, s5.id]);
    });

    test('physicalLoadingOrder = inverse de compute', () async {
      final s1 = await seed();
      final s2 = await seed();
      final s3 = await seed();
      final phys = LoadingOrder.physicalLoadingOrder([s1, s2, s3]);
      expect(phys.map((s) => s.id), [s3.id, s2.id, s1.id]);
    });

    test('liste vide -> vide', () {
      expect(LoadingOrder.compute(const []), isEmpty);
      expect(LoadingOrder.physicalLoadingOrder(const []), isEmpty);
    });
  });
}
