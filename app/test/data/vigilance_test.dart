import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  group('SavedDestinations.isProblematique (#292)', () {
    test('default false', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
                adresseDisplay: 'A', lat: 48.0, lng: 1.0),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.isProblematique, isFalse);
    });

    test('set true via insert', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'A',
              lat: 48.0,
              lng: 1.0,
              isProblematique: const Value(true),
            ),
          );
      final d = await (db.select(db.savedDestinations)
            ..where((s) => s.id.equals(id)))
          .getSingle();
      expect(d.isProblematique, isTrue);
    });
  });
}
