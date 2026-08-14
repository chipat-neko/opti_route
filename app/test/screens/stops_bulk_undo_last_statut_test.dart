import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/screens/tournee_du_jour/stops_bulk_actions.dart';

import '../helpers/test_db.dart';

/// `StopsBulkActions.undoLastStatus` (bouton "Annuler le dernier
/// statut") est le chemin qui FABRIQUAIT l'etat degenere "tournee
/// terminee alors qu'il reste un arret a livrer" : il repassait l'arret
/// en 'a_livrer' sans jamais re-synchroniser le statut de la tournee.
///
/// Test widget et pas data-layer : le defaut vit dans une methode
/// statique qui exige un BuildContext et un WidgetRef, donc rejouer la
/// sequence a la main depuis un test de service ne peut pas le prendre
/// en defaut -- il faut appeler la vraie methode.
///
/// L'arbre monte est volontairement reduit a un bouton : pas d'ecran
/// reel, pas de police a charger, pas de stream Drift a drainer. On
/// passe par un vrai tap plutot que par un BuildContext capture, sinon
/// `use_build_context_synchronously` se declenche a l'analyse.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    // undoLastStatus declenche un HapticFeedback en fire-and-forget.
    // Sans handler, le MethodChannel leve MissingPluginException dans un
    // future non attendu -- que flutter_test remonte en echec de test.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Monte l'arbre minimal, tape le bouton et attend la fin de l'action.
  Future<void> annulerDernierStatut(
    WidgetTester tester,
    AppDatabase db,
    Tournee tournee,
  ) async {
    Future<void>? action;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () {
                  action = StopsBulkActions.undoLastStatus(
                    context: context,
                    ref: ref,
                    tournee: tournee,
                  );
                },
                child: const Text('Annuler'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Annuler'));
    // Le tap est synchrone : `action` est pose avant qu'on revienne ici.
    expect(action, isNotNull, reason: 'le bouton n\'a pas ete declenche');
    await action;
  }

  Future<int> seedStop(AppDatabase db, int tourneeId, String adresse) {
    return db.into(db.stops).insert(
          StopsCompanion.insert(tourneeId: tourneeId, adresseBrute: adresse),
        );
  }

  testWidgets('tournee cloturee : annuler le dernier statut la rouvre',
      (tester) async {
    await tester.runAsync(() async {
      final db = makeTestDb();
      try {
        final stops = StopsRepository(db);
        final tournees = TourneesRepository(db);
        final tId = await seedTournee(db);
        final a = await seedStop(db, tId, 'A');
        final b = await seedStop(db, tId, 'B');
        await stops.markLivre(a);
        await stops.markLivre(b);
        // Etat de depart : tous les arrets valides, tournee cloturee --
        // exactement ce que produit la bascule automatique du service.
        await tournees.update(
          tId,
          const TourneesCompanion(statut: Value('terminee')),
        );

        await annulerDernierStatut(tester, db, (await tournees.getById(tId))!);

        // Le coeur du correctif : sans la re-synchronisation, la tournee
        // restait 'terminee' avec un arret repasse en 'a_livrer'.
        expect((await tournees.getById(tId))!.statut, 'optimisee');
        // Quel arret exactement a ete reverte n'est pas verifie a
        // dessein : `getLastTransitionedStop` trie sur un timestamp a la
        // seconde, donc deux transitions posees dans le meme test sont a
        // egalite et l'ordre de depart est indefini. Les deux etant
        // 'livre', il en reste dans tous les cas exactement un a livrer
        // -- c'est ca qui doit rouvrir la tournee.
        final relus = await stops.getByTournee(tId);
        expect(
          relus.where((s) => s.statutLivraison == 'a_livrer'),
          hasLength(1),
        );
      } finally {
        // Demonte avant de fermer la DB : ca dispose le
        // ScaffoldMessenger, donc annule le timer du SnackBar affiche
        // par l'undo.
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      }
    });
  });

  testWidgets('tournee encore ouverte : le statut ne bouge pas',
      (tester) async {
    await tester.runAsync(() async {
      final db = makeTestDb();
      try {
        final stops = StopsRepository(db);
        final tournees = TourneesRepository(db);
        final tId = await seedTournee(db);
        final a = await seedStop(db, tId, 'A');
        await seedStop(db, tId, 'B'); // celui-la reste a livrer
        await stops.markLivre(a);
        await tournees.update(
          tId,
          const TourneesCompanion(statut: Value('en_cours')),
        );

        await annulerDernierStatut(tester, db, (await tournees.getById(tId))!);

        // L'autre sens : la re-synchronisation ne doit rien normaliser au
        // passage. Une tournee jamais cloturee reste 'en_cours', elle ne
        // repart pas en 'optimisee'.
        expect((await tournees.getById(tId))!.statut, 'en_cours');
        final relus = await stops.getByTournee(tId);
        expect(relus.every((s) => s.statutLivraison == 'a_livrer'), isTrue);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      }
    });
  });
}
