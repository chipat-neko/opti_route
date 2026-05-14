import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/screens/carnet_adresses_screen.dart';
import 'package:opti_route/screens/home_screen.dart';
import 'package:opti_route/screens/parametres_screen.dart';
import 'package:opti_route/screens/stats_screen.dart';
import 'package:opti_route/theme/app_theme.dart';

/// Smoke tests : verifier que chaque ecran principal **rend sans
/// crash** en mode clair ET en mode sombre. Pas d'assertion fine sur
/// le contenu, juste un filet "tu ne casses pas l'app".
///
/// Pour les pieces qui dependent d'un stream Drift, on injecte une
/// DB en memoire via `parametresRepositoryProvider.overrideWith` etc.
///
/// **Solution Drift Timer.zero** : `tester.runAsync(...)` autour de
/// pumpWidget donne du vrai temps a Drift pour drainer ses streams,
/// ce qui resout l'exception "Timer is still pending" historique.
/// Cf [_pumpScreen] qui implementee ce pattern.
///
/// **Solution google_fonts** : depuis 2026-05-14, les .ttf Manrope +
/// JetBrainsMono sont bundle dans `assets/fonts/` (cf pubspec.yaml).
/// On set `GoogleFonts.config.allowRuntimeFetching = false` au
/// `setUpAll`, ce qui force google_fonts a utiliser les assets
/// locaux au lieu de fetcher via HTTP (qui est mock par
/// TestWidgetsFlutterBinding).

void main() {
  setUpAll(() {
    // Empeche google_fonts de fetcher en HTTP (le main.dart le fait
    // deja, mais les tests court-circuitent main() donc on le refait
    // ici par defense). Les .ttf sont bundle en `assets/fonts/`.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Chaque test cree sa propre AppDatabase(NativeDatabase.memory()).
    // Drift loggue un WARNING pour chaque instance >1 (race conditions
    // possibles). Ici les DBs sont isolees en memoire, on coupe le
    // warning pour ne pas polluer le log de test.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Smoke render — mode clair', () {
    testWidgets('HomeScreen rend sans crash', (tester) async {
      await _pumpScreen(tester, const HomeScreen(), brightness: Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CarnetAdressesScreen rend sans crash', (tester) async {
      await _pumpScreen(tester, const CarnetAdressesScreen(),
          brightness: Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StatsScreen rend sans crash', (tester) async {
      await _pumpScreen(tester, const StatsScreen(),
          brightness: Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ParametresScreen rend sans crash', (tester) async {
      await _pumpScreen(tester, const ParametresScreen(),
          brightness: Brightness.light);
      expect(tester.takeException(), isNull);
    });
  });

  group('Smoke render — mode sombre', () {
    testWidgets('HomeScreen rend sans crash en sombre', (tester) async {
      await _pumpScreen(tester, const HomeScreen(), brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CarnetAdressesScreen rend sans crash en sombre',
        (tester) async {
      await _pumpScreen(tester, const CarnetAdressesScreen(),
          brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StatsScreen rend sans crash en sombre', (tester) async {
      await _pumpScreen(tester, const StatsScreen(),
          brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ParametresScreen rend sans crash en sombre',
        (tester) async {
      await _pumpScreen(tester, const ParametresScreen(),
          brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Helper qui pompe un screen dans un MaterialApp avec un theme et
/// une DB Drift en memoire. Necessaire pour que les providers
/// Riverpod qui touchent la base aient une vraie source.
///
/// Encapsule **tout** dans **un seul** `runAsync` : pump + close.
/// La separation pump-en-runAsync / close-en-tearDown-runAsync a cause
/// des "Reentrant call to runAsync() denied" en CI : si close()
/// hangeait (Drift streams non draines), la runAsync de tearDown
/// restait active et bloquait le test suivant qui appelait runAsync.
/// En fermant la DB dans le meme runAsync que le pump, on garantit
/// l'isolation par test : 1 runAsync entre, 1 sort.
///
/// Le wrap reste necessaire pour donner du vrai temps a Drift de
/// drainer ses Timer.zero internes au close (sans ca : exception
/// "Timer is still pending" historique).
Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required Brightness brightness,
}) async {
  await tester.runAsync(() async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            darkTheme: buildAppThemeDark(),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: screen,
          ),
        ),
      );
      // Laisser un frame pour les streams initiaux.
      await tester.pump(const Duration(milliseconds: 100));
    } finally {
      // Vide l'arbre AVANT de fermer la DB : dispose les Riverpod
      // StreamProviders qui pourraient encore ecouter les tables Drift,
      // sinon db.close() attend ces subscribers indefiniment.
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    }
  });
}
