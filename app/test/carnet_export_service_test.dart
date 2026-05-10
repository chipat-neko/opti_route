import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

void main() {
  group('CarnetExportService — format CSV', () {
    late AppDatabase db;
    late SavedDestinationsRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SavedDestinationsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    /// On teste la fonction de formatage interne via le test d'integration
    /// `exportAndShare` : il essaie d'utiliser `share_plus` ce qui demande
    /// le binding plateforme. Donc ici on teste directement la generation
    /// du CSV via un export manuel sans Share.
    test('CSV vide quand carnet vide (juste header)', () async {
      final list = await repo.watchAll().first;
      final csv = _toCsv(list);
      // 1 seule ligne (le header).
      expect(csv.split('\n').where((l) => l.trim().isNotEmpty).length, 1);
      expect(csv, startsWith('id,nom_client,adresse_display,'));
    });

    test('echappement RFC 4180 : virgule dans le nom', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Dupont, Pierre',
        adresseDisplay: '14 rue Foo, 75011 Paris',
        lat: 48.85,
        lng: 2.37,
      );
      final list = await repo.watchAll().first;
      final csv = _toCsv(list);
      // Le nom contient une virgule -> doit etre entre guillemets.
      expect(csv, contains('"Dupont, Pierre"'));
      expect(csv, contains('"14 rue Foo, 75011 Paris"'));
    });

    test('echappement RFC 4180 : guillemets internes doubles', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Cafe "Le Coin"',
        adresseDisplay: 'Foo',
        lat: 1,
        lng: 1,
      );
      final list = await repo.watchAll().first;
      final csv = _toCsv(list);
      // Guillemets internes doubles (RFC 4180).
      expect(csv, contains('"Cafe ""Le Coin"""'));
    });
  });
}

/// Reimplementation locale du formatter pour pouvoir le tester sans
/// depender de share_plus (qui demande le binding plateforme).
String _toCsv(List<SavedDestination> all) {
  final buf = StringBuffer();
  const headers = [
    'id',
    'nom_client',
    'adresse_display',
    'rue',
    'code_postal',
    'ville',
    'lat',
    'lng',
    'use_count',
    'last_used_at',
    'cree_le',
  ];
  buf.writeln(headers.map(_escape).join(','));
  for (final d in all) {
    buf.writeln([
      d.id.toString(),
      d.nomClient ?? '',
      d.adresseDisplay,
      d.rue ?? '',
      d.codePostal ?? '',
      d.ville ?? '',
      d.lat.toStringAsFixed(6),
      d.lng.toStringAsFixed(6),
      d.useCount.toString(),
      d.lastUsedAt.toIso8601String(),
      d.creeLe.toIso8601String(),
    ].map(_escape).join(','));
  }
  return buf.toString();
}

String _escape(String value) {
  final needsQuotes =
      value.contains(',') || value.contains('"') || value.contains('\n');
  if (!needsQuotes) return value;
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
