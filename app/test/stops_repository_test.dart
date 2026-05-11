import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

void main() {
  group('StopsRepository - statut livraison', () {
    late AppDatabase db;
    late StopsRepository repo;
    late int stopId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = StopsRepository(db);
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: '14 Impasse Bois',
              lat: const Value(48.4),
              lng: const Value(1.5),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('default : statut = a_livrer, raisonEchec = null', () async {
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'a_livrer');
      expect(s.raisonEchec, isNull);
    });

    test('markLivre : statut -> livre, raisonEchec -> null', () async {
      await repo.markEchec(stopId, 'absent'); // setup pour verif reset
      await repo.markLivre(stopId);
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'livre');
      expect(s.raisonEchec, isNull);
    });

    test('markEchec : statut -> echec, raisonEchec persistee', () async {
      await repo.markEchec(stopId, 'refuse');
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'echec');
      expect(s.raisonEchec, 'refuse');
    });

    test('markAaLivrer : reset complet', () async {
      await repo.markEchec(stopId, 'autre');
      await repo.markAaLivrer(stopId);
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'a_livrer');
      expect(s.raisonEchec, isNull);
    });

    test('markLivre avec position GPS : coords + timestamp persistes',
        () async {
      final before = DateTime.now();
      await repo.markLivre(
        stopId,
        position: (lat: 48.4307, lng: 1.4892),
      );
      final s = await repo.getById(stopId);
      expect(s!.livreLat, 48.4307);
      expect(s.livreLng, 1.4892);
      expect(s.livreLe, isNotNull);
      expect(
        s.livreLe!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('markLivre sans position : livreLat/livreLng restent null',
        () async {
      await repo.markLivre(stopId);
      final s = await repo.getById(stopId);
      expect(s!.livreLat, isNull);
      expect(s.livreLng, isNull);
      expect(s.livreLe, isNotNull); // le timestamp est toujours pose
    });

    test('markAaLivrer efface aussi la position + timestamp', () async {
      await repo.markLivre(stopId, position: (lat: 1.0, lng: 2.0));
      await repo.markAaLivrer(stopId);
      final s = await repo.getById(stopId);
      expect(s!.livreLat, isNull);
      expect(s.livreLng, isNull);
      expect(s.livreLe, isNull);
    });

    test('changement de statut n\'affecte pas les autres champs', () async {
      // Donnees significatives sur le stop avant validation.
      await (db.update(db.stops)..where((s) => s.id.equals(stopId))).write(
        const StopsCompanion(
          nbColis: Value(7),
          notes: Value('code 1234B'),
        ),
      );
      await repo.markLivre(stopId);
      final s = await repo.getById(stopId);
      expect(s!.nbColis, 7);
      expect(s.notes, 'code 1234B');
    });
  });
}
