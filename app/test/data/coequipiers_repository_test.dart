import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/coequipiers_repository.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

void main() {
  group('CoequipiersRepository - CRUD', () {
    late AppDatabase db;
    late CoequipiersRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = CoequipiersRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('count : 0 si vide', () async {
      expect(await repo.count(), 0);
    });

    test('create + getById round-trip', () async {
      final id = await repo.create(
        nom: 'Papa',
        colorTag: 'lime',
        telephone: '0612345678',
      );
      final c = await repo.getById(id);
      expect(c, isNotNull);
      expect(c!.nom, 'Papa');
      expect(c.colorTag, 'lime');
      expect(c.telephone, '0612345678');
      expect(c.actif, isTrue); // defaut
    });

    test('create trim le nom', () async {
      final id = await repo.create(nom: '  Lucas  ');
      final c = await repo.getById(id);
      expect(c!.nom, 'Lucas');
    });

    test('update : modifie un champ sans toucher au reste', () async {
      final id = await repo.create(nom: 'A', telephone: '0111111111');
      await repo.update(id, nom: 'A modifie');
      final c = await repo.getById(id);
      expect(c!.nom, 'A modifie');
      expect(c.telephone, '0111111111');
    });

    test('update telephone vide : retire le numero', () async {
      final id = await repo.create(nom: 'A', telephone: '0111111111');
      await repo.update(id, telephone: '');
      final c = await repo.getById(id);
      expect(c!.telephone, isNull);
    });

    test('toggleActif : true -> false -> true', () async {
      final id = await repo.create(nom: 'A');
      expect((await repo.getById(id))!.actif, isTrue);
      await repo.toggleActif(id);
      expect((await repo.getById(id))!.actif, isFalse);
      await repo.toggleActif(id);
      expect((await repo.getById(id))!.actif, isTrue);
    });

    test('toggleActif sur id inconnu : 0 (no-op)', () async {
      final n = await repo.toggleActif(9999);
      expect(n, 0);
    });

    test('watchActifs : exclut les archives', () async {
      final id1 = await repo.create(nom: 'Actif1');
      final id2 = await repo.create(nom: 'Archive1');
      final id3 = await repo.create(nom: 'Actif2');
      await repo.update(id2, actif: false);

      final list = await repo.watchActifs().first;
      expect(list.length, 2);
      expect(list.map((c) => c.id), containsAll([id1, id3]));
      expect(list.map((c) => c.id), isNot(contains(id2)));
    });

    test('watchAll : inclut tout, actifs en haut', () async {
      final id1 = await repo.create(nom: 'Zoe');
      final id2 = await repo.create(nom: 'Anna');
      await repo.update(id2, actif: false);
      await repo.create(nom: 'Bob');

      final list = await repo.watchAll().first;
      expect(list.length, 3);
      // Zoe + Bob actifs en haut (tries par nom alpha asc) → Bob, Zoe
      // puis Anna archive en bas
      expect(list.first.actif, isTrue);
      expect(list.last.id, id2); // Anna archive en dernier
      expect(list.last.actif, isFalse);
      expect(list[0].nom, 'Bob');
      expect(list[1].nom, 'Zoe');
      expect(list[0].actif, isTrue);
      expect(list[1].id, id1);
    });

    test('getAllActifs : ordre alpha asc', () async {
      await repo.create(nom: 'Zoe');
      await repo.create(nom: 'Anna');
      await repo.create(nom: 'Bob');
      final list = await repo.getAllActifs();
      expect(list.map((c) => c.nom), ['Anna', 'Bob', 'Zoe']);
    });

    test('delete : retire definitivement', () async {
      final id = await repo.create(nom: 'A');
      await repo.delete(id);
      expect(await repo.getById(id), isNull);
      expect(await repo.count(), 0);
    });
  });

  group('StopsRepository.setCoequipier (FK coequipier)', () {
    late AppDatabase db;
    late StopsRepository stopsRepo;
    late CoequipiersRepository coRepo;
    late int stopId;
    late int coId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      stopsRepo = StopsRepository(db);
      coRepo = CoequipiersRepository(db);
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 13),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
            ),
          );
      coId = await coRepo.create(nom: 'Papa');
    });

    tearDown(() async {
      await db.close();
    });

    test('par defaut : coequipierId null', () async {
      final s = await stopsRepo.getById(stopId);
      expect(s!.coequipierId, isNull);
    });

    test('setCoequipier : pose l\'id', () async {
      await stopsRepo.setCoequipier(stopId, coId);
      final s = await stopsRepo.getById(stopId);
      expect(s!.coequipierId, coId);
    });

    test('setCoequipier null : reset a "Moi"', () async {
      await stopsRepo.setCoequipier(stopId, coId);
      await stopsRepo.setCoequipier(stopId, null);
      final s = await stopsRepo.getById(stopId);
      expect(s!.coequipierId, isNull);
    });

    test('setCoequipierForUnassigned : n\'ecrase pas les deja affectes',
        () async {
      final tId = (await stopsRepo.getById(stopId))!.tourneeId;
      // Stop2 deja affecte
      final stop2Id = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'B',
              coequipierId: Value(coId),
            ),
          );
      // Stop3 non affecte
      final stop3Id = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'C',
            ),
          );
      final autreCoId = await coRepo.create(nom: 'Lucas');

      // Bulk affecte tous les non-affectes a "autreCoId" : devrait
      // toucher stop (deja null) + stop3, mais pas stop2.
      await stopsRepo.setCoequipierForUnassigned(tId, autreCoId);

      expect((await stopsRepo.getById(stopId))!.coequipierId, autreCoId);
      expect((await stopsRepo.getById(stop2Id))!.coequipierId, coId);
      expect((await stopsRepo.getById(stop3Id))!.coequipierId, autreCoId);
    });
  });
}
