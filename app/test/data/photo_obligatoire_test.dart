import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('photoObligatoire (#301)', () {
    test('default false', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
                adresseDisplay: 'A', lat: 48.0, lng: 1.0),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.photoObligatoire, isFalse);
    });
    test('set true', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'A',
              lat: 48.0,
              lng: 1.0,
              photoObligatoire: const Value(true),
            ),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.photoObligatoire, isTrue);
    });
  });
}
