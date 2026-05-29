import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';

// Premier test pour l'historique des recherches recentes
// (UnifiedSearchScreen / Cmd+K). Verifie : ordre LRU, dedup
// case-insensitive, truncate a 5 max, trim, no-op sur vide, separateur
// "|" defensif, clear.
void main() {
  late AppDatabase db;
  late ParametresRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ParametresRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ParametresRepository — recentSearches', () {
    test('liste vide par defaut', () async {
      expect(await repo.getRecentSearches(), isEmpty);
    });

    test('ajout : en tete de la liste', () async {
      await repo.addRecentSearch('Garage X');
      expect(await repo.getRecentSearches(), ['Garage X']);
    });

    test('2 ajouts : le plus recent en premier', () async {
      await repo.addRecentSearch('A');
      await repo.addRecentSearch('B');
      expect(await repo.getRecentSearches(), ['B', 'A']);
    });

    test('dedup case-insensitive : "garage" puis "GARAGE" -> 1 seule entree '
        'avec la derniere casse', () async {
      await repo.addRecentSearch('garage');
      await repo.addRecentSearch('GARAGE');
      final r = await repo.getRecentSearches();
      expect(r.length, 1);
      expect(r.first, 'GARAGE', reason: 'la plus recente reste, en haut');
    });

    test('truncate a 5 elements max', () async {
      for (var i = 1; i <= 8; i++) {
        await repo.addRecentSearch('query $i');
      }
      final r = await repo.getRecentSearches();
      expect(r.length, 5);
      // Les 5 plus recentes : 8 (plus recent) -> 4
      expect(r, ['query 8', 'query 7', 'query 6', 'query 5', 'query 4']);
    });

    test('trim : "  abc  " -> "abc"', () async {
      await repo.addRecentSearch('  abc  ');
      expect(await repo.getRecentSearches(), ['abc']);
    });

    test('chaine vide : no-op', () async {
      await repo.addRecentSearch('');
      expect(await repo.getRecentSearches(), isEmpty);
    });

    test('whitespace seul : no-op (trim -> vide)', () async {
      await repo.addRecentSearch('   ');
      expect(await repo.getRecentSearches(), isEmpty);
    });

    test('query contenant le separateur "|" : no-op defensif', () async {
      await repo.addRecentSearch('a|b');
      expect(await repo.getRecentSearches(), isEmpty,
          reason: 'rejet defensif pour ne pas corrompre le storage');
    });

    test('re-ajout d\'une entree existante : la fait remonter en tete',
        () async {
      await repo.addRecentSearch('A');
      await repo.addRecentSearch('B');
      await repo.addRecentSearch('C');
      // A est en bas (3eme).
      expect((await repo.getRecentSearches()).last, 'A');
      // Re-ajout A -> remonte en haut.
      await repo.addRecentSearch('A');
      expect(await repo.getRecentSearches(), ['A', 'C', 'B']);
    });

    test('clearRecentSearches : remet la liste vide', () async {
      await repo.addRecentSearch('A');
      await repo.addRecentSearch('B');
      await repo.clearRecentSearches();
      expect(await repo.getRecentSearches(), isEmpty);
    });

    test('ordre stable apres dedup + truncate combine', () async {
      // 5 entrees, puis re-ajout du 3eme + 1 nouveau.
      for (var i = 1; i <= 5; i++) {
        await repo.addRecentSearch('q$i');
      }
      // Etat : q5 q4 q3 q2 q1
      await repo.addRecentSearch('q2'); // remonte q2
      // Etat : q2 q5 q4 q3 q1 (q1 toujours en queue, q2 dedup remonte)
      final r = await repo.getRecentSearches();
      expect(r, ['q2', 'q5', 'q4', 'q3', 'q1']);
    });
  });
}
