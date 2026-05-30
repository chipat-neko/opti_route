import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tournee_share_payload.dart';

void main() {
  late AppDatabase db;
  late int tId;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'Lundi',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D'));
  });
  tearDown(() async => db.close());

  Future<Tournee> getT() async =>
      (db.select(db.tournees)..where((t) => t.id.equals(tId))).getSingle();

  Future<Stop> seed({
    String? nom,
    double? lat,
    double? lng,
    int colis = 1,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '1 rue X',
        nomClient: Value(nom),
        lat: lat != null ? Value(lat) : const Value.absent(),
        lng: lng != null ? Value(lng) : const Value.absent(),
        nbColis: Value(colis)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('TourneeSharePayload (#308)', () {
    test('compose + parse round-trip', () async {
      final s1 = await seed(nom: 'M. A', lat: 48.1, lng: 1.1, colis: 3);
      final s2 = await seed();
      final t = await getT();
      final raw = TourneeSharePayload.compose(
          tournee: t, orderedStops: [s1, s2]);
      expect(raw, contains('"v":1'));
      expect(raw, contains('"n":"Lundi"'));
      expect(raw, contains('"a":"1 rue X"'));
      expect(raw, contains('"n":"M. A"'));
      expect(raw, contains('"c":3'));
      final back = TourneeSharePayload.parse(raw);
      expect(back, isNotNull);
      expect(back!.nom, 'Lundi');
      expect(back.stops, hasLength(2));
      expect(back.stops.first.nomClient, 'M. A');
      expect(back.stops.first.nbColis, 3);
    });

    test('parse JSON invalide -> null', () {
      expect(TourneeSharePayload.parse('not json'), isNull);
      expect(TourneeSharePayload.parse('{"v":99}'), isNull);
    });

    test('compose omet les sensibles : photos, COD, telephones', () async {
      final s = await seed();
      final t = await getT();
      final raw =
          TourneeSharePayload.compose(tournee: t, orderedStops: [s]);
      expect(raw, isNot(contains('preuvePhotoPath')));
      expect(raw, isNot(contains('montantCod')));
      expect(raw, isNot(contains('telephone')));
    });
  });
}
