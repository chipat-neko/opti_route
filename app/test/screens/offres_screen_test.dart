import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_route/screens/offres_screen.dart';
import 'package:opti_route/theme/app_theme.dart';

/// Smoke + contenu de l'écran « Nos offres » (#381-D). Écran statique
/// (aucun provider/DB), donc test simple sans override.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(WidgetTester tester, Brightness b) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        darkTheme: buildAppThemeDark(),
        themeMode: b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: const OffresScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('rend sans crash (clair)', (tester) async {
    await pump(tester, Brightness.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rend sans crash (sombre)', (tester) async {
    await pump(tester, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche les premiers paliers (en haut de liste)',
      (tester) async {
    await pump(tester, Brightness.light);
    // Visibles sans scroll : Solo + Petite équipe + leurs badges.
    expect(find.text('Solo'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    expect(find.text('Gratuit'), findsOneWidget);
  });

  testWidgets('tous les paliers existent (scroll pour les derniers)',
      (tester) async {
    await pump(tester, Brightness.light);
    // Grande entreprise est en bas -> on scrolle jusqu'à lui.
    await tester.scrollUntilVisible(
      find.text('Grande entreprise'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Grande entreprise'), findsOneWidget);
  });
}
