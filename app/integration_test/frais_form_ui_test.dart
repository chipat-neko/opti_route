// Test integration UI E2E pour FraisFormScreen (carte Trello refactor
// frais_form + complement aux tests unit).
//
// **Pourquoi integration_test plutot que flutter_test ?**
// flutter_test execute dans un isolate Dart sans Flutter engine ->
// Drift watch + Riverpod StreamProvider ne tirent pas leurs emissions
// asynchronously, on tombe en timeout. integration_test tourne sur un
// vrai device (ou emulateur) avec un vrai event loop -> les streams
// fonctionnent normalement et `pumpAndSettle` est fiable.
//
// **Lancement** :
//   flutter test integration_test/frais_form_ui_test.dart -d <device-id>
//
// Ou avec un emulateur Android demarré :
//   flutter test integration_test/frais_form_ui_test.dart -d emulator-5554
//
// Sur Windows desktop : `-d windows` (rapide, idem behavior business).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/screens/frais_form_screen.dart';
import 'package:opti_route/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Pour DateFormat('EEEE d MMMM y', 'fr') du screen.
    await initializeDateFormatting('fr');
  });

  Widget appWrap({required Widget home, required AppDatabase db}) {
    // home wrappe dans un Scaffold + Builder qui push le FraisFormScreen
    // via un Navigator parent : indispensable pour que Navigator.pop()
    // apres save ne plante pas (sinon le screen est home: direct = pas
    // de route parent dans la pile).
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR')],
        locale: const Locale('fr', 'FR'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Push asap le vrai screen, comme s'il etait pousse depuis
              // un menu de l'app. Le Scaffold home: reste invisible.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => home),
                );
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  group('FraisFormScreen E2E', () {
    testWidgets('mode create : titre + bouton "Ajouter" + chips type',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          appWrap(db: db, home: const FraisFormScreen()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Nouveau frais'), findsOneWidget);
        expect(find.text('Ajouter le frais'), findsOneWidget);
        expect(find.text('Carburant'), findsOneWidget);
        // Bouton stations Diesel visible pour type carburant.
        expect(find.text('Stations Diesel proches'), findsOneWidget);
      } finally {
        await db.close();
      }
    });

    testWidgets('toggle chip Peage : cache le bouton stations',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          appWrap(db: db, home: const FraisFormScreen()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Stations Diesel proches'), findsOneWidget);

        // Tap sur Peage.
        await tester.tap(find.text('Peage'));
        await tester.pumpAndSettle();
        expect(find.text('Stations Diesel proches'), findsNothing);

        // Tap retour Carburant.
        await tester.tap(find.text('Carburant'));
        await tester.pumpAndSettle();
        expect(find.text('Stations Diesel proches'), findsOneWidget);
      } finally {
        await db.close();
      }
    });

    // Note : le test "save complet + pop Navigator" est volontairement
    // omis ici -- pumpAndSettle apres tap "Ajouter" boucle a l'infini
    // car le Drift watch `tourneesStreamProvider` re-emit en continu et
    // ne se "settled" jamais. Le flow save lui-meme est deja couvert
    // par les tests unit du repo (frais_flow_test.dart) qui valident
    // create + update + watchByMonth. Ce qu'on couvre ICI est l'UI :
    // rendu, validators bloquants, mode edit pre-rempli.

    testWidgets('validator : libelle vide bloque le save', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          appWrap(db: db, home: const FraisFormScreen()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Montant'),
          '12',
        );
        await tester.pump();
        await tester.tap(find.text('Ajouter le frais'));
        await tester.pumpAndSettle();

        expect(find.text('Donne un libelle'), findsOneWidget);
        final rows = await db.select(db.frais).get();
        expect(rows, isEmpty);
      } finally {
        await db.close();
      }
    });

    testWidgets('validator : montant 0 bloque le save', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          appWrap(db: db, home: const FraisFormScreen()),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Montant'),
          '0',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Libelle'),
          'X',
        );
        await tester.pump();
        await tester.tap(find.text('Ajouter le frais'));
        await tester.pumpAndSettle();

        expect(find.text('Doit etre superieur a 0'), findsOneWidget);
        final rows = await db.select(db.frais).get();
        expect(rows, isEmpty);
      } finally {
        await db.close();
      }
    });

    testWidgets('mode edit : pre-rempli + bouton "Enregistrer"',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final id = await db.into(db.frais).insert(
              FraisCompanion.insert(
                date: DateTime(2026, 5, 13),
                type: 'peage',
                montantCentimes: 950,
                libelle: 'Peage A11',
              ),
            );
        final frais = await (db.select(db.frais)
              ..where((f) => f.id.equals(id)))
            .getSingle();

        await tester.pumpWidget(
          appWrap(db: db, home: FraisFormScreen(initial: frais)),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.text('Modifier le frais'), findsOneWidget);
        expect(find.text('Enregistrer'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Peage A11'),
            findsOneWidget);
        expect(find.widgetWithText(TextFormField, '9.50'), findsOneWidget);
        // Pas de bouton stations Diesel pour type = peage.
        expect(find.text('Stations Diesel proches'), findsNothing);
      } finally {
        await db.close();
      }
    });
  });
}
