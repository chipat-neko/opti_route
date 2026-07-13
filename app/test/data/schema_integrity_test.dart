// Test d'intégrité du schéma Drift (F18). Un test de migration versionnée
// v1→courante exige l'outillage drift_dev (schémas générés) indisponible
// sur cette machine ; on fait donc un test d'INTÉGRITÉ robuste et
// auto-adaptatif : à l'ouverture d'une base neuve, Drift crée tout le
// schéma courant. On vérifie que chaque table déclarée dans
// `@DriftDatabase` est bien matérialisée, qu'un round-trip basique marche,
// et que la version de schéma est cohérente. Se met à jour tout seul quand
// on ajoute/retire une table (pas de liste codée en dur).
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

void main() {
  group('Intégrité du schéma Drift', () {
    test('toutes les tables déclarées sont créées à l\'ouverture', () async {
      final db = makeTestDb();
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final existing = rows.map((r) => r.read<String>('name')).toSet();
      // db.allTables = toutes les tables du @DriftDatabase ; on les compare
      // à ce que sqlite a réellement créé.
      for (final table in db.allTables) {
        expect(
          existing,
          contains(table.actualTableName),
          reason: 'table "${table.actualTableName}" absente du schéma créé',
        );
      }
      await db.close();
    });

    test('round-trip minimal : insert + relecture d\'une tournée', () async {
      final db = makeTestDb();
      final id = await seedTournee(db, nom: 'Tournée test');
      final t = await (db.select(db.tournees)..where((x) => x.id.equals(id)))
          .getSingle();
      expect(t.nom, 'Tournée test');
      expect(t.pointDepartLabel, isNotEmpty);
      await db.close();
    });

    test('schemaVersion est cohérent (> 0)', () async {
      final db = makeTestDb();
      expect(db.schemaVersion, greaterThan(0));
      await db.close();
    });
  });
}
