// Tests pour TrackingCodesRepository (carte Trello #141).
//
// Couvre l'attribution de codes courts uniques aux stops + l'idempotence
// (re-call genere le meme code), + la construction d'URL.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/app_constants.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';
import 'package:opti_route/data/tracking_codes_repository.dart';

void main() {
  group('TrackingCodesRepository', () {
    late AppDatabase db;
    late TrackingCodesRepository repo;
    late StopsRepository stops;
    late TourneesRepository tournees;
    late int stopId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = TrackingCodesRepository(db);
      stops = StopsRepository(db);
      tournees = TourneesRepository(db);
      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 27),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D',
      ));
      stopId = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '1 rue X',
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('getByStopId : null si jamais genere', () async {
      expect(await repo.getByStopId(stopId), isNull);
    });

    test('generateForStop : cree un code de la longueur attendue', () async {
      final tc = await repo.generateForStop(stopId);
      expect(tc.code.length, kTrackingCodeLength);
      expect(tc.stopId, stopId);
    });

    test('generateForStop : alphabet sans confusion (l/1/o/0 exclus)',
        () async {
      // Tirer N codes pour minimiser le risque de fausse confiance sur
      // un seul tirage chanceux.
      for (var i = 0; i < 50; i++) {
        // Nouveau stop a chaque iteration sinon idempotent retourne le
        // meme.
        final sId = await stops.create(StopsCompanion.insert(
          tourneeId: (await tournees.watchAll().first).first.id,
          adresseBrute: 'iter $i',
        ));
        final tc = await repo.generateForStop(sId);
        for (final ch in tc.code.split('')) {
          expect(
            'l1o0'.contains(ch),
            isFalse,
            reason: 'caractere ambigu "$ch" trouve dans code "${tc.code}"',
          );
          expect(
            ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122 ||
                ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57,
            isTrue,
            reason: 'caractere "$ch" hors alphabet alphanumeric minuscule',
          );
        }
      }
    });

    test('generateForStop : idempotent (re-call retourne le meme code)',
        () async {
      final tc1 = await repo.generateForStop(stopId);
      final tc2 = await repo.generateForStop(stopId);
      expect(tc1.id, tc2.id);
      expect(tc1.code, tc2.code);

      // Et getByStopId retourne le meme.
      final fetched = await repo.getByStopId(stopId);
      expect(fetched!.code, tc1.code);
    });

    test('generateForStop : codes uniques entre 2 stops differents',
        () async {
      final stop2 = await stops.create(StopsCompanion.insert(
        tourneeId: (await tournees.watchAll().first).first.id,
        adresseBrute: '2 rue Y',
      ));
      final tc1 = await repo.generateForStop(stopId);
      final tc2 = await repo.generateForStop(stop2);
      expect(tc1.code, isNot(tc2.code));
    });

    test('buildUrl : forme https://<domaine>/<code>', () {
      // Code de longueur kTrackingCodeLength (4 par defaut) pour
      // respecter la contrainte "URL totale <= 20 chars" de la carte #141.
      final code = 'a' * kTrackingCodeLength;
      final url = TrackingCodesRepository.buildUrl(code);
      expect(url, startsWith('https://'));
      expect(url, endsWith('/$code'));
      expect(url.length, lessThanOrEqualTo(20),
          reason: 'contrainte carte #141 : URL totale <= 20 chars');
    });
  });
}
