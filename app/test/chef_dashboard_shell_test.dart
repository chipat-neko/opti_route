import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:opti_route/data/chef_stats_service.dart';
import 'package:opti_route/data/chef_tournees_service.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/screens/chef/chef_dashboard_shell.dart';
import 'package:opti_route/theme/app_theme.dart';
import 'package:opti_route/theme/app_tokens.dart';

/// Widget tests du shell "vue d'ensemble chef" (epopee #88, [#88·1]).
/// Verifie la bascule responsive : grand ecran -> 3 panneaux en
/// colonnes (pas de hint), ecran etroit -> panneaux empiles + message
/// "optimise pour grand ecran". Le panneau stats ([#88·4]) lit
/// `equipeStatsJourProvider` : on l'override pour ne pas toucher Drift.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget harness() => ProviderScope(
        overrides: [
          equipeStatsJourProvider
              .overrideWith((ref) async => ChefStatsJour.empty),
          equipeTourneesEnCoursProvider
              .overrideWith((ref) async => const <ChefTourneeProgress>[]),
        ],
        child: MaterialApp(
          theme: buildAppTheme(preset: AppThemePreset.lime),
          home: const ChefDashboardShell(),
        ),
      );

  testWidgets('affiche les 3 panneaux avec leur tag sous-carte',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Tournees en cours'), findsOneWidget);
    expect(find.text('Carte live'), findsOneWidget);
    expect(find.text('Stats du jour'), findsOneWidget);

    expect(find.text('[#88·2]'), findsOneWidget);
    expect(find.text('[#88·3]'), findsOneWidget);
    expect(find.text('[#88·4]'), findsOneWidget);
  });

  testWidgets('grand ecran : pas de hint "grand ecran"', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Optimise pour grand ecran'),
      findsNothing,
    );
  });

  testWidgets('ecran etroit : affiche le hint + empile les panneaux',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Optimise pour grand ecran'),
      findsOneWidget,
    );
    // Les 3 panneaux restent presents, juste empiles.
    expect(find.text('Tournees en cours'), findsOneWidget);
    expect(find.text('Carte live'), findsOneWidget);
    expect(find.text('Stats du jour'), findsOneWidget);
  });
}
