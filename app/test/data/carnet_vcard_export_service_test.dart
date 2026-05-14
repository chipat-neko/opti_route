import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:opti_route/data/carnet_vcard_export_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
  });

  group('CarnetVcardExportService - serialisation vCard 3.0', () {
    late AppDatabase db;
    late SavedDestinationsRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SavedDestinationsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<SavedDestination>> seedEntries() async {
      await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              nomClient: const Value('Carrefour Dreux'),
              adresseDisplay: '4 av. Gare, 28100 Dreux',
              lat: 48.737,
              lng: 1.366,
              rue: const Value('4 av. Gare'),
              codePostal: const Value('28100'),
              ville: const Value('Dreux'),
              useCount: const Value(5),
              isFavori: const Value(true),
            ),
          );
      await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: '12 rue des Lilas, 28100 Dreux',
              lat: 48.744,
              lng: 1.357,
            ),
          );
      return repo.watchAll().first;
    }

    test('contient BEGIN/END:VCARD et VERSION 3.0 pour chaque entree',
        () async {
      final entries = await seedEntries();
      // ignore: invalid_use_of_visible_for_testing_member
      final vcf = _accessVcard(entries);
      final beginCount = 'BEGIN:VCARD'.allMatches(vcf).length;
      final endCount = 'END:VCARD'.allMatches(vcf).length;
      expect(beginCount, 2);
      expect(endCount, 2);
      expect(vcf, contains('VERSION:3.0'));
    });

    test('FN reflete le nomClient ou un fallback', () async {
      final entries = await seedEntries();
      final vcf = _accessVcard(entries);
      expect(vcf, contains('FN:Carrefour Dreux'));
      // Entree sans nom -> fallback "Adresse opti_route"
      expect(vcf, contains('FN:Adresse opti_route'));
    });

    test('ORG present uniquement quand nomClient renseigne', () async {
      final entries = await seedEntries();
      final vcf = _accessVcard(entries);
      expect(vcf, contains('ORG:Carrefour Dreux'));
      // Pas d'ORG pour l'entree sans nom : on ne match pas "ORG:" suivi
      // de quelque chose qui ne soit pas Carrefour. On compte les ORG.
      final orgCount = 'ORG:'.allMatches(vcf).length;
      expect(orgCount, 1);
    });

    test('ADR rue + ville + cp dans l\'ordre vCard 3.0', () async {
      final entries = await seedEntries();
      final vcf = _accessVcard(entries);
      expect(vcf, contains('ADR;TYPE=WORK:;;4 av. Gare;Dreux;;28100;France'));
    });

    test('GEO contient les coords formatees', () async {
      final entries = await seedEntries();
      final vcf = _accessVcard(entries);
      expect(vcf, contains('GEO:48.737000;1.366000'));
      expect(vcf, contains('GEO:48.744000;1.357000'));
    });

    test('CATEGORIES porte Favori quand isFavori = true', () async {
      final entries = await seedEntries();
      final vcf = _accessVcard(entries);
      expect(vcf, contains('CATEGORIES:opti_route,Favori'));
      expect(vcf, contains('CATEGORIES:opti_route\n'));
    });

    test('escape les virgules et points-virgules', () async {
      await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              nomClient: const Value('Dupont, Jean'),
              adresseDisplay: 'addr',
              lat: 0,
              lng: 0,
              rue: const Value('1 rue ; chose'),
            ),
          );
      final entries = await repo.watchAll().first;
      final vcf = _accessVcard(entries);
      expect(vcf, contains(r'FN:Dupont\, Jean'));
      expect(vcf, contains(r'1 rue \; chose'));
    });
  });
}

/// La methode `toVcard` est annotee `@visibleForTesting` -> appel
/// direct ici, on ne touche pas au filesystem ni a share_plus.
String _accessVcard(List<SavedDestination> entries) {
  return CarnetVcardExportService.toVcard(entries);
}
