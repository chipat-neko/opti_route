import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/plan.dart';

/// #381-A : colonne `entreprises.plan` (défaut 'illimite' = grandfathering)
/// + catalogue [Plan]. Fondation neutre : aucune limite appliquée ici, on
/// vérifie juste le stockage + le mapping de badge.
void main() {
  group('colonne entreprises.plan', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<Entreprise> read(String id) => (db.select(db.entreprises)
          ..where((e) => e.cloudId.equals(id)))
        .getSingle();

    test('défaut illimite à l\'insert (grandfathering)', () async {
      await db.into(db.entreprises).insert(EntreprisesCompanion.insert(
            cloudId: 'e1',
            nom: 'CALOTE Noah',
            createdBy: 'u1',
          ));
      expect((await read('e1')).plan, 'illimite');
    });

    test('plan persiste si fourni', () async {
      await db.into(db.entreprises).insert(EntreprisesCompanion.insert(
            cloudId: 'e2',
            nom: 'X',
            createdBy: 'u1',
            plan: const Value('tier2'),
          ));
      expect((await read('e2')).plan, 'tier2');
    });
  });

  group('Plan.fromCode', () {
    test('codes connus', () {
      expect(Plan.fromCode('free').badge, 'Free');
      expect(Plan.fromCode('free').maxEntrepots, 0);
      expect(Plan.fromCode('tier1').maxMembres, 5);
      expect(Plan.fromCode('tier2').peutCreerEntreprise, isTrue);
      expect(Plan.fromCode('tier3').entrepotsIllimites, isTrue);
    });

    test('code null ou inconnu retombe sur illimite (jamais de bridage)', () {
      expect(Plan.fromCode(null).code, 'illimite');
      expect(Plan.fromCode('bidon').code, 'illimite');
      expect(Plan.fromCode('illimite').entrepotsIllimites, isTrue);
      expect(Plan.fromCode('illimite').membresIllimites, isTrue);
    });
  });
}
