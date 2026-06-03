import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/screens/tournee_du_jour/optim_actions.dart';
import 'package:opti_route/theme/app_theme.dart';

/// Vérifie le point demandé par Noah : au DÉMARRAGE d'une tournée, si elle
/// a ≥2 arrêts « EN 1ER » (ou « EN DERNIER »), un dialog drag & drop
/// permet d'en choisir l'ordre (ce que faisait VROOM avant). On teste le
/// helper [OptimTourneeActions.ensureOrdrePrioriteChoisi] branché sur le
/// flux « Démarrer ».
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<(AppDatabase, Tournee)> seed({
    required String prioriteCommune,
    required int nb,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final tourneeId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 6, 3),
            pointDepartLat: 48.0,
            pointDepartLng: 2.0,
            pointDepartLabel: 'Depot',
          ),
        );
    for (var i = 0; i < nb; i++) {
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'A$i',
              lat: Value(48.01 + i * 0.01),
              lng: const Value(2.0),
              priorite: Value(prioriteCommune),
            ),
          );
    }
    final tournee = await (db.select(db.tournees)
          ..where((t) => t.id.equals(tourneeId)))
        .getSingle();
    return (db, tournee);
  }

  // Pompe un widget avec un bouton « go » qui appelle le helper et stocke
  // le résultat dans [holder] (liste 1-élément, lue après les taps).
  Future<void> pump(WidgetTester tester, AppDatabase db, Tournee tournee,
      List<bool?> holder) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    holder[0] =
                        await OptimTourneeActions.ensureOrdrePrioriteChoisi(
                      context: context,
                      ref: ref,
                      tournee: tournee,
                    );
                  },
                  child: const Text('go'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('≥2 arrêts EN 1ER : le dialog apparaît au démarrage',
      (tester) async {
    final (db, tournee) =
        await seed(prioriteCommune: 'obligatoire_premier', nb: 2);
    addTearDown(db.close);
    await pump(tester, db, tournee, [null]);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Ordre des arrets EN 1ER'), findsOneWidget);
    expect(find.text('Valider l\'ordre'), findsOneWidget);
  });

  testWidgets('valider persiste ordrePriorite 1,2 + helper renvoie true',
      (tester) async {
    final (db, tournee) =
        await seed(prioriteCommune: 'obligatoire_premier', nb: 2);
    addTearDown(db.close);
    final holder = <bool?>[null];
    await pump(tester, db, tournee, holder);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle(); // dialog ouvert
    await tester.tap(find.text('Valider l\'ordre'));
    await tester.pumpAndSettle(); // helper terminé
    expect(holder[0], isTrue);

    final stops = await db.select(db.stops).get()
      ..sort((a, b) => a.id.compareTo(b.id));
    expect(stops.map((s) => s.ordrePriorite).toList(), [1, 2]);
  });

  testWidgets('moins de 2 par groupe : aucun dialog, renvoie true direct',
      (tester) async {
    final (db, tournee) =
        await seed(prioriteCommune: 'obligatoire_premier', nb: 1);
    addTearDown(db.close);
    final holder = <bool?>[null];
    await pump(tester, db, tournee, holder);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Ordre des arrets EN 1ER'), findsNothing);
    expect(holder[0], isTrue);
  });
}
