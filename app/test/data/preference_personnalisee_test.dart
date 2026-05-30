import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('preferencePersonnalisee (#335)', () {
    test('default null', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
                adresseDisplay: 'A', lat: 48, lng: 1),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.preferencePersonnalisee, isNull);
    });

    test('set + relisible', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'A',
              lat: 48,
              lng: 1,
              preferencePersonnalisee:
                  const Value('Sonner 2 fois, attendre 30s'),
            ),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.preferencePersonnalisee, 'Sonner 2 fois, attendre 30s');
    });
  });
}
