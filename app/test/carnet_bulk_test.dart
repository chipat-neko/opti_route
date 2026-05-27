import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

/// Tests des operations en masse du carnet (carte #104) :
/// setColorTagBulk / setFavoriBulk / deleteBulk.
void main() {
  late AppDatabase db;
  late SavedDestinationsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedDestinationsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seed(String nom) {
    return db.into(db.savedDestinations).insert(
          SavedDestinationsCompanion.insert(
            nomClient: Value(nom),
            adresseDisplay: '$nom addr',
            lat: 48.0,
            lng: 1.0,
          ),
        );
  }

  test('setFavoriBulk marque plusieurs fiches favori', () async {
    final a = await seed('A');
    final b = await seed('B');
    final c = await seed('C');

    final n = await repo.setFavoriBulk([a, b], true);
    expect(n, 2);

    final rows = await db.select(db.savedDestinations).get();
    expect(rows.firstWhere((r) => r.id == a).isFavori, isTrue);
    expect(rows.firstWhere((r) => r.id == b).isFavori, isTrue);
    expect(rows.firstWhere((r) => r.id == c).isFavori, isFalse);
  });

  test('setColorTagBulk applique puis retire une etiquette', () async {
    final a = await seed('A');
    final b = await seed('B');

    await repo.setColorTagBulk([a, b], 'lime');
    var rows = await db.select(db.savedDestinations).get();
    expect(rows.every((r) => r.colorTag == 'lime'), isTrue);

    await repo.setColorTagBulk([a], null);
    rows = await db.select(db.savedDestinations).get();
    expect(rows.firstWhere((r) => r.id == a).colorTag, isNull);
    expect(rows.firstWhere((r) => r.id == b).colorTag, 'lime');
  });

  test('deleteBulk supprime les fiches selectionnees', () async {
    final a = await seed('A');
    final b = await seed('B');
    final c = await seed('C');

    final n = await repo.deleteBulk([a, b]);
    expect(n, 2);

    final rows = await db.select(db.savedDestinations).get();
    expect(rows.map((r) => r.id), [c]);
  });

  test('listes vides -> 0 ligne affectee, pas d\'erreur', () async {
    expect(await repo.setFavoriBulk([], true), 0);
    expect(await repo.setColorTagBulk([], 'lime'), 0);
    expect(await repo.deleteBulk([]), 0);
  });
}
