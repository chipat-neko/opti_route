import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

// Verrou de la version du schema Drift. Si quelqu'un bump la version
// sans mettre a jour ce test (et la migration onUpgrade), ca casse ici
// et force l'ajout d'une etape de migration dans la PR.
void main() {
  group('AppDatabase — schema', () {
    test('schemaVersion = 42 (verrou de version)', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 42,
          reason:
              'Si tu bump la version, ajoute la migration dans le '
              'onUpgrade(...) de database.dart ET mets a jour ce test.');
    });

    test('createAll sur DB memoire : pas de throw', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      // Si createAll crash, c'est qu'une table a un probleme syntaxique
      // ou conflit de schema. On force l'ouverture en lisant une table
      // (qui declenche le lazy open).
      await db.select(db.tournees).get();
      // Pas de throw -> schema OK.
    });

    test('toutes les 5 tables principales sont accessibles', () async {
      // Garde-fou : si une table principale est renommee/supprimee, ce
      // test catch l'oubli de migration cote consommer.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.select(db.tournees).get();
      await db.select(db.stops).get();
      await db.select(db.savedDestinations).get();
      await db.select(db.parametres).get();
      await db.select(db.coequipiers).get();
    });
  });
}
