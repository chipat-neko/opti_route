import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/batch_scan_commit_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stop_types.dart';
import 'package:opti_route/data/stops_repository.dart';

/// Tests du commit batch scan (carte #119) : deduplication (nom / GPS) +
/// creation en masse des arrets. DB memoire.
void main() {
  group('BatchScanCommitService.isDuplicate (pur)', () {
    test('meme nom (normalise) -> doublon', () {
      expect(
        BatchScanCommitService.isDuplicate(
          const BatchScanItem(adresse: 'A', nomClient: 'Garage Aguilar'),
          const BatchScanItem(adresse: 'B', nomClient: '  garage   aguilar '),
        ),
        isTrue,
      );
    });

    test('noms differents + pas de coords -> pas doublon', () {
      expect(
        BatchScanCommitService.isDuplicate(
          const BatchScanItem(adresse: 'A', nomClient: 'Dupont'),
          const BatchScanItem(adresse: 'B', nomClient: 'Martin'),
        ),
        isFalse,
      );
    });

    test('memes coords (< 50 m) -> doublon meme si noms differents', () {
      expect(
        BatchScanCommitService.isDuplicate(
          const BatchScanItem(
              adresse: 'A', nomClient: 'X', lat: 48.4500, lng: 1.5000),
          const BatchScanItem(
              adresse: 'B', nomClient: 'Y', lat: 48.45005, lng: 1.50005),
        ),
        isTrue,
      );
    });

    test('coords eloignees -> pas doublon', () {
      expect(
        BatchScanCommitService.isDuplicate(
          const BatchScanItem(adresse: 'A', lat: 48.45, lng: 1.50),
          const BatchScanItem(adresse: 'B', lat: 48.46, lng: 1.51),
        ),
        isFalse,
      );
    });

    test('nom vide / null -> pas de match par nom', () {
      expect(
        BatchScanCommitService.isDuplicate(
          const BatchScanItem(adresse: 'A', nomClient: ''),
          const BatchScanItem(adresse: 'B', nomClient: '   '),
        ),
        isFalse,
      );
    });
  });

  group('commit (DB memoire)', () {
    late AppDatabase db;
    late StopsRepository stops;
    late BatchScanCommitService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stops = StopsRepository(db);
      service = BatchScanCommitService(stops);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee() {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 28),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
    }

    test('cree tous les arrets distincts', () async {
      final t = await seedTournee();
      final r = await service.commit(tourneeId: t, items: const [
        BatchScanItem(adresse: '1 rue A', nomClient: 'Dupont'),
        BatchScanItem(adresse: '2 rue B', nomClient: 'Martin'),
        BatchScanItem(adresse: '3 rue C', nomClient: 'Durand'),
      ]);
      expect(r.crees, 3);
      expect(r.doublons, 0);
      expect((await stops.getByTournee(t)).length, 3);
    });

    test('saute les doublons intra-batch (meme nom)', () async {
      final t = await seedTournee();
      final r = await service.commit(tourneeId: t, items: const [
        BatchScanItem(adresse: '1 rue A', nomClient: 'Dupont'),
        BatchScanItem(adresse: '1 rue A bis', nomClient: 'DUPONT'),
      ]);
      expect(r.crees, 1);
      expect(r.doublons, 1);
      expect((await stops.getByTournee(t)).length, 1);
    });

    test('saute les doublons vs arrets deja en base', () async {
      final t = await seedTournee();
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: t,
              adresseBrute: 'existant',
              nomClient: const Value('Dupont'),
            ),
          );
      final r = await service.commit(tourneeId: t, items: const [
        BatchScanItem(adresse: 'x', nomClient: 'dupont'), // doublon
        BatchScanItem(adresse: 'y', nomClient: 'Nouveau'),
      ]);
      expect(r.crees, 1);
      expect(r.doublons, 1);
      expect((await stops.getByTournee(t)).length, 2); // 1 existant + 1 cree
    });

    test('type ramasse pose pour les enlevements', () async {
      final t = await seedTournee();
      await service.commit(tourneeId: t, items: const [
        BatchScanItem(adresse: 'z', nomClient: 'Retour', isEnlevement: true),
      ]);
      final rows = await stops.getByTournee(t);
      expect(rows.single.type, kStopTypeRamasse);
    });
  });
}
