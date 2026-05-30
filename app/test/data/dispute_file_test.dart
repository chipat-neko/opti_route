import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/dispute_file.dart';

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
    String statut = 'livre',
    String? raison,
    DateTime? livreLe,
    double? livreLat,
    double? livreLng,
    String? photo,
    bool sansContact = false,
    String? tracking,
    String? nom,
  }) async {
    final id = await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '1 rue X',
        nomClient: Value(nom),
        statutLivraison: Value(statut),
        raisonEchec: Value(raison),
        livreLe: Value(livreLe),
        livreLat: Value(livreLat),
        livreLng: Value(livreLng),
        preuvePhotoPath: Value(photo),
        deposeSansContact: Value(sansContact),
        trackingNumbers: Value(tracking)));
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('DisputeFile.compose (#311)', () {
    test('contenu minimal + hash stable', () async {
      final s = await seed(
        statut: 'livre',
        livreLe: DateTime(2026, 5, 30, 14, 7),
        livreLat: 48.123,
        livreLng: 1.456,
      );
      final t = DateTime(2026, 5, 30, 18);
      final d1 = DisputeFile.compose(stop: s, now: t);
      final d2 = DisputeFile.compose(stop: s, now: t);
      expect(d1.body, contains('DOSSIER LITIGE'));
      expect(d1.body, contains('30/05/2026 14:07'));
      expect(d1.body, contains('48.12300,1.45600'));
      expect(d1.hash.length, 64);
      expect(d1.isOpposable, isTrue);
      expect(d1.hash, d2.hash, reason: 'hash deterministe');
    });

    test('echec + raison + photo + sans contact', () async {
      final s = await seed(
        statut: 'echec',
        raison: 'absent',
        livreLe: DateTime(2026, 5, 1, 9),
        photo: '/app_documents/preuves/1_xxx.jpg',
        sansContact: true,
        tracking: '["FA1","FA2"]',
        nom: 'M. Dupont',
      );
      final d = DisputeFile.compose(
          stop: s, now: DateTime(2026, 5, 1, 10));
      expect(d.body, contains('Statut     : echec'));
      expect(d.body, contains('Raison     : absent'));
      expect(d.body, contains('M. Dupont'));
      expect(d.body, contains('FA1'));
      expect(d.body, contains('DEPOSE SANS CONTACT'));
      expect(d.body, contains('preuves/1_xxx.jpg'));
    });

    test('pas de livreLe -> mention non livre', () async {
      final s = await seed(statut: 'a_livrer');
      final d = DisputeFile.compose(
          stop: s, now: DateTime(2026, 5, 30));
      expect(d.body, contains('(non livre)'));
      expect(d.body, contains('GPS indisponible'));
    });

    test('hash change si stop change', () async {
      final s1 = await seed(
        statut: 'livre',
        livreLe: DateTime(2026, 5, 30, 14),
        livreLat: 48,
        livreLng: 1,
      );
      final s2 = await seed(
        statut: 'livre',
        livreLe: DateTime(2026, 5, 30, 14),
        livreLat: 49,
        livreLng: 1,
      );
      final t = DateTime(2026, 5, 30, 18);
      final d1 = DisputeFile.compose(stop: s1, now: t);
      final d2 = DisputeFile.compose(stop: s2, now: t);
      expect(d1.hash, isNot(d2.hash));
    });
  });
}
