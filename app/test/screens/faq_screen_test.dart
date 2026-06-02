import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_route/screens/faq_screen.dart';
import 'package:opti_route/theme/app_theme.dart';

/// Smoke + interaction de l'écran « Questions fréquentes ». Écran statique
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
        home: const FaqScreen(),
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

  testWidgets('affiche des questions (ExpansionTile)', (tester) async {
    await pump(tester, Brightness.light);
    expect(find.byType(ExpansionTile), findsWidgets);
    expect(
      find.text('Comment ajouter un arrêt à ma tournée ?'),
      findsOneWidget,
    );
  });

  testWidgets('déplier une question révèle sa réponse', (tester) async {
    await pump(tester, Brightness.light);
    // Réponse repliée par défaut : le texte de réponse n'est pas monté.
    final reponse = find.textContaining('géocodée automatiquement');
    expect(reponse, findsNothing);
    // On déplie la première question.
    await tester.tap(find.text('Comment ajouter un arrêt à ma tournée ?'));
    await tester.pumpAndSettle();
    expect(reponse, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
