import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/carnet_import_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

void main() {
  group('CarnetImportService.importFromText', () {
    late AppDatabase db;
    late SavedDestinationsRepository repo;
    late CarnetImportService importer;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SavedDestinationsRepository(db);
      importer = CarnetImportService(repo);
    });

    tearDown(() async {
      await db.close();
    });

    const csvExport = '''id,nom_client,adresse_display,rue,code_postal,ville,lat,lng,use_count,last_used_at,cree_le
1,Carrosserie Coculo,"1 Rue des Tournesols, 28110 Luce",1 Rue des Tournesols,28110,Luce,48.430700,1.489200,3,2026-05-09T12:00:00.000,2026-04-01T08:00:00.000
2,"Pharmacie Centrale, SARL","12 Place du Marche, 28000 Chartres",12 Place du Marche,28000,Chartres,48.450000,1.490000,1,2026-05-08T15:00:00.000,2026-05-08T15:00:00.000
''';

    test('CSV vide -> erreur explicite', () async {
      final r = await importer.importFromText('');
      expect(r.created, 0);
      expect(r.errors, isNotEmpty);
    });

    test('CSV header invalide -> tout rejete avec erreur', () async {
      final r = await importer.importFromText(
        'foo,bar,baz\n1,2,3',
      );
      expect(r.created, 0);
      expect(r.rejected, 1);
      expect(r.errors.first, contains('adresse_display'));
    });

    test('CSV export classique -> creation', () async {
      final r = await importer.importFromText(csvExport);
      expect(r.created, 2);
      expect(r.merged, 0);
      expect(r.rejected, 0);
      expect(await repo.count(), 2);
    });

    test('echappement RFC 4180 : virgule + guillemets dans nom', () async {
      final r = await importer.importFromText(csvExport);
      expect(r.created, 2);
      final pharma = await repo.search('Pharmacie');
      expect(pharma, isNotEmpty);
      expect(pharma.first.nomClient, 'Pharmacie Centrale, SARL');
      expect(pharma.first.adresseDisplay,
          '12 Place du Marche, 28000 Chartres');
    });

    test('reimport du meme CSV -> tout fusionne, rien cree', () async {
      await importer.importFromText(csvExport);
      final r2 = await importer.importFromText(csvExport);
      expect(r2.created, 0);
      expect(r2.merged, 2);
      expect(await repo.count(), 2); // pas de doublons
    });

    test('ligne avec coords invalides -> rejetee', () async {
      const bad = '''id,nom_client,adresse_display,rue,code_postal,ville,lat,lng,use_count,last_used_at,cree_le
1,Test,addr,r,cp,v,not_a_number,1.5,1,2026,2026
''';
      final r = await importer.importFromText(bad);
      expect(r.created, 0);
      expect(r.rejected, 1);
    });
  });
}
