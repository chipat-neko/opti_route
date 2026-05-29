import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/frais_repository.dart';

// Premier test pour FraisRepository : CRUD + filtres (mois/tournee) +
// totalCentimes (SQL sum). DB en memoire, schema v37 inchange.
void main() {
  late AppDatabase db;
  late FraisRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FraisRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('FraisRepository.create + getById', () {
    test('create persiste les champs et trim type/libelle/notes', () async {
      final id = await repo.create(
        date: DateTime(2026, 5, 15),
        type: '  carburant  ', // espaces a trimmer
        montantCentimes: 4500,
        libelle: '  Total Auneau  ',
        notes: '  100% diesel  ',
      );
      final f = await repo.getById(id);
      expect(f, isNotNull);
      expect(f!.type, 'carburant', reason: 'type trimmed');
      expect(f.libelle, 'Total Auneau', reason: 'libelle trimmed');
      expect(f.notes, '100% diesel');
      expect(f.montantCentimes, 4500);
      expect(f.tourneeId, isNull);
      expect(f.photoPath, isNull);
    });

    test('getById sur id inconnu : null', () async {
      expect(await repo.getById(99999), isNull);
    });
  });

  group('FraisRepository.update', () {
    test('met a jour seulement les champs fournis', () async {
      final id = await repo.create(
        date: DateTime(2026, 5, 15),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'A11',
      );
      await repo.update(id, montantCentimes: 250);
      final f = await repo.getById(id);
      expect(f!.montantCentimes, 250);
      expect(f.libelle, 'A11', reason: 'libelle non touche');
    });

    test('clearTournee remet tourneeId a null', () async {
      // Cree une vraie tournee FK
      final tid = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 15),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
      final id = await repo.create(
        date: DateTime(2026, 5, 15),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'A11',
        tourneeId: tid,
      );
      await repo.update(id, clearTournee: true);
      final f = await repo.getById(id);
      expect(f!.tourneeId, isNull);
    });

    test('clearPhoto + clearNotes mettent a null', () async {
      final id = await repo.create(
        date: DateTime(2026, 5, 15),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'A11',
        notes: 'note',
        photoPath: '/tmp/p.jpg',
      );
      await repo.update(id, clearPhoto: true, clearNotes: true);
      final f = await repo.getById(id);
      expect(f!.photoPath, isNull);
      expect(f.notes, isNull);
    });

    test('update libelle: trim applique', () async {
      final id = await repo.create(
        date: DateTime(2026, 5, 15),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'A11',
      );
      await repo.update(id, libelle: '  Nouveau  ');
      final f = await repo.getById(id);
      expect(f!.libelle, 'Nouveau');
    });
  });

  group('FraisRepository.delete', () {
    test('supprime et retourne 1', () async {
      final id = await repo.create(
        date: DateTime(2026, 5, 15),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'A11',
      );
      expect(await repo.delete(id), 1);
      expect(await repo.getById(id), isNull);
    });

    test('retourne 0 si id inconnu', () async {
      expect(await repo.delete(99999), 0);
    });
  });

  group('FraisRepository.totalCentimes', () {
    test('somme sur une periode, sans filtre type', () async {
      await repo.create(
        date: DateTime(2026, 5, 1),
        type: 'carburant',
        montantCentimes: 5000,
        libelle: 'Total',
      );
      await repo.create(
        date: DateTime(2026, 5, 15),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'A11',
      );
      await repo.create(
        date: DateTime(2026, 6, 1),
        type: 'peage',
        montantCentimes: 999,
        libelle: 'Hors periode',
      );
      final total = await repo.totalCentimes(
        from: DateTime(2026, 5),
        to: DateTime(2026, 6),
      );
      expect(total, 5200);
    });

    test('filtre type carburant uniquement', () async {
      await repo.create(
        date: DateTime(2026, 5, 1),
        type: 'carburant',
        montantCentimes: 5000,
        libelle: 'Total',
      );
      await repo.create(
        date: DateTime(2026, 5, 15),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'A11',
      );
      final total = await repo.totalCentimes(
        from: DateTime(2026, 5),
        to: DateTime(2026, 6),
        type: 'carburant',
      );
      expect(total, 5000);
    });

    test('periode vide -> 0 (pas null)', () async {
      final total = await repo.totalCentimes(
        from: DateTime(2026, 5),
        to: DateTime(2026, 6),
      );
      expect(total, 0);
    });
  });

  group('FraisRepository.watchByMonth', () {
    test('filtre les frais hors du mois cible', () async {
      await repo.create(
        date: DateTime(2026, 5, 1),
        type: 'peage',
        montantCentimes: 100,
        libelle: 'Dans mai',
      );
      await repo.create(
        date: DateTime(2026, 5, 31),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'Dans mai',
      );
      await repo.create(
        date: DateTime(2026, 6, 1),
        type: 'peage',
        montantCentimes: 999,
        libelle: 'Juin',
      );
      final mai = await repo.watchByMonth(2026, 5).first;
      expect(mai, hasLength(2));
      expect(mai.map((f) => f.libelle), everyElement('Dans mai'));
    });

    test('tri date desc (plus recent en premier)', () async {
      await repo.create(
        date: DateTime(2026, 5, 1),
        type: 'peage',
        montantCentimes: 100,
        libelle: 'Ancien',
      );
      await repo.create(
        date: DateTime(2026, 5, 20),
        type: 'peage',
        montantCentimes: 200,
        libelle: 'Recent',
      );
      final mai = await repo.watchByMonth(2026, 5).first;
      expect(mai.first.libelle, 'Recent');
    });
  });
}
