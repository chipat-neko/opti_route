import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('SavedDestinations.noteStationnement (#288)', () {
    test('default null', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
                adresseDisplay: 'A', lat: 48.0, lng: 1.0),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.noteStationnement, isNull);
    });

    test('set + relisible', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'A',
              lat: 48.0,
              lng: 1.0,
              noteStationnement:
                  const Value('parking sous-sol entree D'),
            ),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.noteStationnement, 'parking sous-sol entree D');
    });
  });
}
