import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/screens/parametres_screen.dart';
import 'package:opti_route/theme/app_theme.dart';

/// Vérifie la refonte #401 : l'écran Paramètres est un HUB qui présente
/// la carte « Temps de travail » + les 6 catégories de réglages (au lieu
/// d'un long défilement). On rend le hub avec une DB en mémoire et on
/// vérifie la présence de chaque catégorie.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpHub(WidgetTester tester) async {
    await tester.runAsync(() async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: buildAppTheme(),
              home: const ParametresScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      }
    });
  }

  testWidgets('le hub affiche les 6 catégories + le bloc Temps de travail',
      (tester) async {
    // Surface haute : sinon le ListView (lazy) ne construit pas les tuiles
    // hors écran (Sécurité / Application) et les finds échouent.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: buildAppTheme(),
              home: const ParametresScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Sections de tête (ParametresSectionTitle met en MAJUSCULES).
        expect(find.text('TEMPS DE TRAVAIL'), findsOneWidget);
        expect(find.text('RÉGLAGES'), findsOneWidget);

        // Les 6 catégories de la refonte.
        for (final titre in const [
          'Tournée & carburant',
          'Apparence & notifications',
          'Compte & équipe',
          'Données & stockage',
          'Sécurité',
          'Application & aide',
        ]) {
          expect(find.text(titre), findsOneWidget, reason: 'manque "$titre"');
        }

        // Les catégories sont cliquables (InkWell par tuile).
        expect(find.byType(InkWell), findsWidgets);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      }
    });
  });

  testWidgets('rend sans crash (filet de sécurité)', (tester) async {
    await pumpHub(tester);
    expect(tester.takeException(), isNull);
  });
}
