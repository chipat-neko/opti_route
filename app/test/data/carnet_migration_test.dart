import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

/// Tests de la couche migration carnet local -> cloud (carte #365,
/// épopée multi-tenant #361).
void main() {
  late AppDatabase db;
  late SavedDestinationsRepository repo;
  late ParametresRepository params;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedDestinationsRepository(db);
    params = ParametresRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // Compteur pour garantir des coords UNIQUES par adresse : sinon deux
  // noms de meme longueur tomberaient sur les memes lat/lng et
  // `upsertFromValidatedStop` dedupliquerait par proximite GPS (~11 m).
  var seedCounter = 0;

  /// Crée une entrée carnet et retourne son id local.
  Future<int> seed(String nom) async {
    seedCounter++;
    await repo.upsertFromValidatedStop(
      nomClient: nom,
      adresseDisplay: '$nom, 28000 Chartres',
      lat: 48.44 + seedCounter * 0.01,
      lng: 1.49 + seedCounter * 0.01,
    );
    final entry = await repo.findByNomClient(nom);
    return entry!.id;
  }

  group('Portée carnet (#365)', () {
    test('une adresse fraîche est privée (entrepriseId null)', () async {
      await seed('Garage Aguilar');
      expect(await repo.watchCountPrivees().first, 1);
      final privees = await repo.watchPrivees().first;
      expect(privees, hasLength(1));
      expect(privees.first.entrepriseId, isNull);
      expect(privees.first.entrepotId, isNull);
    });

    test('setPortee entreprise seule retire l\'adresse des privées',
        () async {
      final id = await seed('Boulangerie Martin');
      await repo.setPortee(id, entrepriseId: 'ent-1');

      expect(await repo.watchCountPrivees().first, 0);
      final row = await repo.getById(id);
      expect(row!.entrepriseId, 'ent-1');
      expect(row.entrepotId, isNull);
    });

    test('setPortee entrepôt renseigne entreprise + entrepôt', () async {
      final id = await seed('Pharmacie Centrale');
      await repo.setPortee(id, entrepriseId: 'ent-1', entrepotId: 'epot-9');

      final row = await repo.getById(id);
      expect(row!.entrepriseId, 'ent-1');
      expect(row.entrepotId, 'epot-9');
      expect(await repo.watchCountPrivees().first, 0);
    });

    test('setPortee bump updatedAt (déclenche l\'auto-push)', () async {
      final id = await seed('Tabac du Coin');
      final before = (await repo.getById(id))!.updatedAt;
      // Drift stocke les DateTime en SECONDES : il faut > 1 s pour voir
      // une difference. En usage reel le wizard agit sur des adresses
      // anciennes (ecart >> 1 s), donc l'auto-push detecte bien le
      // changement de portee. Ce delai rend le test fidele a ce stockage.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await repo.setPortee(id, entrepriseId: 'ent-1');
      final after = (await repo.getById(id))!.updatedAt;
      expect(after.isAfter(before), isTrue);
    });

    test('setPorteeBulk partage plusieurs adresses d\'un coup', () async {
      final id1 = await seed('Client A');
      final id2 = await seed('Client B');
      await seed('Client C'); // reste privé

      final n = await repo.setPorteeBulk([id1, id2], entrepriseId: 'ent-1');
      expect(n, 2);
      expect(await repo.watchCountPrivees().first, 1); // Client C
    });

    test('setPorteeBulk [] = no-op', () async {
      await seed('Solo');
      final n = await repo.setPorteeBulk([], entrepriseId: 'ent-1');
      expect(n, 0);
      expect(await repo.watchCountPrivees().first, 1);
    });

    test('repasser une adresse partagée en privé', () async {
      final id = await seed('Reversible');
      await repo.setPortee(id, entrepriseId: 'ent-1', entrepotId: 'epot-1');
      expect(await repo.watchCountPrivees().first, 0);
      // Retour privé
      await repo.setPortee(id);
      final row = await repo.getById(id);
      expect(row!.entrepriseId, isNull);
      expect(row.entrepotId, isNull);
      expect(await repo.watchCountPrivees().first, 1);
    });
  });

  group('Flag migration carnet (#365)', () {
    test('défaut false', () async {
      expect(await params.getCarnetMigrationDone(), isFalse);
    });

    test('set true persiste', () async {
      await params.setCarnetMigrationDone(true);
      expect(await params.getCarnetMigrationDone(), isTrue);
    });

    test('watch émet la valeur courante', () async {
      await params.setCarnetMigrationDone(true);
      expect(await params.watchCarnetMigrationDone().first, isTrue);
    });
  });
}
