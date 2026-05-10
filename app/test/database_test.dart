import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('insertion d une tournee renvoie les valeurs par defaut', () async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Tournee Mardi 12/05',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.8566,
              pointDepartLng: 2.3522,
              pointDepartLabel: 'Depot Paris 11',
            ),
          );

      final t = await (db.select(db.tournees)
            ..where((row) => row.id.equals(tourneeId)))
          .getSingle();

      expect(t.nom, 'Tournee Mardi 12/05');
      expect(t.statut, 'brouillon');
      expect(t.vehiculeCapaciteColis, 0);
      expect(t.creeLe.isBefore(DateTime.now().add(const Duration(seconds: 1))),
          isTrue);
    });

    test('cascade delete: supprimer une tournee supprime ses stops', () async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Test cascade',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 0,
              pointDepartLng: 0,
              pointDepartLabel: 'Depot',
            ),
          );

      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: '1 rue de la Paix',
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: '2 avenue des Tests',
            ),
          );

      expect(await db.select(db.stops).get(), hasLength(2));

      await (db.delete(db.tournees)
            ..where((row) => row.id.equals(tourneeId)))
          .go();

      expect(await db.select(db.stops).get(), isEmpty,
          reason: 'PRAGMA foreign_keys=ON doit etre actif');
    });

    test('valeurs par defaut sur stop : priorite, statut, nb colis, duree',
        () async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime.now(),
              pointDepartLat: 0,
              pointDepartLng: 0,
              pointDepartLabel: 'D',
            ),
          );

      final stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: '12 rue Foo',
            ),
          );

      final stop = await (db.select(db.stops)
            ..where((row) => row.id.equals(stopId)))
          .getSingle();
      expect(stop.priorite, 'flexible');
      expect(stop.statutLivraison, 'a_livrer');
      expect(stop.nbColis, 1);
      expect(stop.dureeArretMin, 3);
      expect(stop.lat, isNull);
      expect(stop.lng, isNull);
    });

    test('parametres utilise la cle comme primary key et supporte upsert',
        () async {
      await db.into(db.parametres).insert(
            ParametresCompanion.insert(cle: 'ors_api_key', valeur: 'abc123'),
          );

      // Re-insert avec la meme cle doit echouer (contrainte primary key)
      await expectLater(
        db.into(db.parametres).insert(
              ParametresCompanion.insert(cle: 'ors_api_key', valeur: 'xyz'),
            ),
        throwsA(isA<Object>()),
      );

      // L'upsert (insertOnConflictUpdate) doit ecraser la valeur existante
      await db.into(db.parametres).insertOnConflictUpdate(
            ParametresCompanion.insert(cle: 'ors_api_key', valeur: 'xyz'),
          );

      final p = await (db.select(db.parametres)
            ..where((row) => row.cle.equals('ors_api_key')))
          .getSingle();
      expect(p.valeur, 'xyz');
    });

    test('sheets : insert + valeurs par defaut', () async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime.now(),
              pointDepartLat: 0,
              pointDepartLng: 0,
              pointDepartLabel: 'D',
            ),
          );
      final stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: '12 rue Foo',
            ),
          );

      final sheetId = await db.into(db.sheets).insert(
            SheetsCompanion.insert(stopId: stopId, expediteur: 'Chronopost'),
          );
      final sheet = await (db.select(db.sheets)
            ..where((s) => s.id.equals(sheetId)))
          .getSingle();

      expect(sheet.expediteur, 'Chronopost');
      expect(sheet.nbColis, 1);
      expect(sheet.statut, 'a_livrer');
      expect(sheet.refCode, isNull);
      expect(sheet.poidsKg, isNull);
    });

    test(
        'sheets : cascade delete supprime les sheets quand on supprime le stop',
        () async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime.now(),
              pointDepartLat: 0,
              pointDepartLng: 0,
              pointDepartLabel: 'D',
            ),
          );
      final stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: '12 rue Foo',
            ),
          );
      await db.into(db.sheets).insert(
            SheetsCompanion.insert(stopId: stopId, expediteur: 'Chronopost'),
          );
      await db.into(db.sheets).insert(
            SheetsCompanion.insert(
              stopId: stopId,
              expediteur: 'La Poste',
              nbColis: const Value(2),
            ),
          );

      expect(await db.select(db.sheets).get(), hasLength(2));

      await (db.delete(db.stops)..where((s) => s.id.equals(stopId))).go();

      expect(await db.select(db.sheets).get(), isEmpty,
          reason: 'cascade delete sheet via stop');
    });

    test('sheets : cascade delete via la tournee parente', () async {
      final tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime.now(),
              pointDepartLat: 0,
              pointDepartLng: 0,
              pointDepartLabel: 'D',
            ),
          );
      final stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'x',
            ),
          );
      await db.into(db.sheets).insert(
            SheetsCompanion.insert(stopId: stopId, expediteur: 'Chronopost'),
          );

      await (db.delete(db.tournees)..where((t) => t.id.equals(tourneeId)))
          .go();

      expect(await db.select(db.sheets).get(), isEmpty);
      expect(await db.select(db.stops).get(), isEmpty);
    });
  });
}
