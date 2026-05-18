import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/screens/tournee_du_jour/stop_row.dart';
import 'package:opti_route/screens/tournee_du_jour/stops_list.dart';
import 'package:opti_route/theme/app_theme.dart';

/// Widget tests cibles sur StopRow + StopsList : on couvre l'affichage
/// du statut (livre/echec barre, IndexChip rouge/vert), des tags
/// (priorite, GPS manquant, nb colis, fenetre horaire), du placeholder
/// vide et du mode reorderable on/off. Sert de filet anti-regression
/// sur le composant le plus utilise de l'app (chaque arret de chaque
/// tournee passe par la).
///
/// Pattern Drift Timer.zero : `runAsync` + pump + close dans le meme
/// bloc, assertions passees via callback `assertions:` pour qu'elles
/// s'executent pendant que la DB est encore vivante.

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Stop mkStop({
    int id = 1,
    int tourneeId = 1,
    String adresseBrute = '14 rue de la Paix, 28000 Chartres',
    String? adresseNormalisee,
    String? nomClient,
    String statutLivraison = 'a_livrer',
    String? raisonEchec,
    double? lat = 48.43,
    double? lng = 1.49,
    int nbColis = 1,
    String priorite = 'normale',
    String type = 'livraison',
    String? fenetreDebut,
    String? fenetreFin,
    int? coequipierId,
    String? notes,
  }) {
    return Stop(
      id: id,
      tourneeId: tourneeId,
      adresseBrute: adresseBrute,
      adresseNormalisee: adresseNormalisee,
      lat: lat,
      lng: lng,
      nbColis: nbColis,
      dureeArretMin: 3,
      priorite: priorite,
      type: type,
      statutLivraison: statutLivraison,
      raisonEchec: raisonEchec,
      fenetreDebut: fenetreDebut,
      fenetreFin: fenetreFin,
      nomClient: nomClient,
      coequipierId: coequipierId,
      notes: notes,
      creeLe: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );
  }

  Future<void> pumpInList(
    WidgetTester tester,
    List<Stop> stops, {
    bool reorderable = true,
    required void Function() assertions,
  }) async {
    await tester.runAsync(() async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              theme: buildAppTheme(),
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 800,
                  child: StopsList(stops: stops, reorderable: reorderable),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        assertions();
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
      }
    });
  }

  group('StopRow render', () {
    testWidgets('affiche le nom client en primaire si defini', (tester) async {
      await pumpInList(
        tester,
        [mkStop(nomClient: 'Mme Dupont', adresseBrute: '14 rue Foo, Bar')],
        assertions: () {
          expect(find.text('Mme Dupont'), findsOneWidget);
          expect(find.textContaining('14 rue Foo'), findsOneWidget);
        },
      );
    });

    testWidgets('sans nom client : 1ere partie d\'adresse en primaire',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(adresseBrute: '14 rue Verte, 28000 Chartres')],
        assertions: () {
          expect(find.text('14 rue Verte'), findsOneWidget);
          expect(find.text('Mme Dupont'), findsNothing);
        },
      );
    });

    testWidgets('statut livre : pas d\'echec affiche', (tester) async {
      await pumpInList(
        tester,
        [mkStop(nomClient: 'M. Martin', statutLivraison: 'livre')],
        assertions: () {
          expect(find.text('M. Martin'), findsOneWidget);
          expect(find.textContaining('Echec'), findsNothing);
        },
      );
    });

    testWidgets('statut echec : ligne "Echec : raison" visible',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(
          nomClient: 'M. Martin',
          statutLivraison: 'echec',
          raisonEchec: 'absent',
        )],
        assertions: () {
          expect(find.textContaining('Echec : absent'), findsOneWidget);
        },
      );
    });

    testWidgets('raison echec inconnue -> "sans raison"', (tester) async {
      await pumpInList(
        tester,
        [mkStop(statutLivraison: 'echec', raisonEchec: null)],
        assertions: () {
          expect(find.textContaining('sans raison'), findsOneWidget);
        },
      );
    });

    testWidgets('tag GPS manquant si lat ou lng null', (tester) async {
      await pumpInList(
        tester,
        [mkStop(lat: null, lng: null)],
        assertions: () {
          expect(find.text('GPS MANQUANT'), findsOneWidget);
        },
      );
    });

    testWidgets('pas de tag GPS manquant si coords presentes',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop()],
        assertions: () {
          expect(find.text('GPS MANQUANT'), findsNothing);
        },
      );
    });

    testWidgets('tag nb colis affiche uniquement si > 1', (tester) async {
      await pumpInList(
        tester,
        [
          mkStop(nbColis: 1, adresseBrute: 'A'),
          mkStop(id: 2, nbColis: 3, adresseBrute: 'B'),
        ],
        assertions: () {
          expect(find.text('1 COLIS'), findsNothing);
          expect(find.text('3 COLIS'), findsOneWidget);
        },
      );
    });

    testWidgets('tag fenetre horaire si debut ou fin defini',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(fenetreDebut: '09:00', fenetreFin: '12:00')],
        assertions: () {
          expect(find.textContaining('09:00'), findsOneWidget);
          expect(find.textContaining('12:00'), findsOneWidget);
        },
      );
    });

    testWidgets('priorite EN 1ER affiche tag "EN 1ER"', (tester) async {
      await pumpInList(
        tester,
        [mkStop(priorite: 'obligatoire_premier', nomClient: 'X')],
        assertions: () {
          expect(find.text('EN 1ER'), findsOneWidget);
        },
      );
    });

    testWidgets('priorite EN DERNIER affiche tag "EN DERNIER"',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(priorite: 'obligatoire_dernier', nomClient: 'Y')],
        assertions: () {
          expect(find.text('EN DERNIER'), findsOneWidget);
        },
      );
    });

    testWidgets('priorite eviter affiche tag "EVITER"', (tester) async {
      await pumpInList(
        tester,
        [mkStop(priorite: 'eviter_si_possible', nomClient: 'Z')],
        assertions: () {
          expect(find.text('EVITER'), findsOneWidget);
        },
      );
    });

    testWidgets('drag handle visible en mode reorderable=true',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(nomClient: 'A')],
        reorderable: true,
        assertions: () {
          expect(find.byIcon(Icons.drag_handle), findsOneWidget);
        },
      );
    });

    testWidgets('drag handle masque en mode reorderable=false',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(nomClient: 'A')],
        reorderable: false,
        assertions: () {
          expect(find.byIcon(Icons.drag_handle), findsNothing);
        },
      );
    });
  });

  group('StopsList render', () {
    testWidgets('liste vide : aucun StopRow', (tester) async {
      await pumpInList(
        tester,
        const [],
        assertions: () {
          expect(find.byType(StopRow), findsNothing);
        },
      );
    });

    testWidgets('3 stops : 3 StopRow', (tester) async {
      await pumpInList(
        tester,
        [
          mkStop(id: 1, nomClient: 'A'),
          mkStop(id: 2, nomClient: 'B'),
          mkStop(id: 3, nomClient: 'C'),
        ],
        assertions: () {
          expect(find.byType(StopRow), findsNWidgets(3));
          expect(find.text('A'), findsOneWidget);
          expect(find.text('B'), findsOneWidget);
          expect(find.text('C'), findsOneWidget);
        },
      );
    });

    testWidgets('mode reorderable=false utilise ListView simple',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(nomClient: 'X')],
        reorderable: false,
        assertions: () {
          expect(find.byType(ReorderableListView), findsNothing);
        },
      );
    });

    testWidgets('mode reorderable=true utilise ReorderableListView',
        (tester) async {
      await pumpInList(
        tester,
        [mkStop(nomClient: 'X')],
        reorderable: true,
        assertions: () {
          expect(find.byType(ReorderableListView), findsOneWidget);
        },
      );
    });
  });

  group('StopsPlaceholder', () {
    testWidgets('affiche message d\'invitation + icone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: StopsPlaceholder()),
        ),
      );
      expect(find.text('Pas encore d\'arrets'), findsOneWidget);
      expect(find.byIcon(Icons.add_road_outlined), findsOneWidget);
      expect(find.textContaining('Ajouter un arret'), findsOneWidget);
    });
  });

  group('IndexChip statut variants', () {
    Widget chip({
      required int index,
      required String statut,
      String priorite = 'normale',
    }) {
      return MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: IndexChip(
            index: index,
            priorite: priorite,
            statut: statut,
          ),
        ),
      );
    }

    testWidgets('statut livre : icone check', (tester) async {
      await tester.pumpWidget(chip(index: 1, statut: 'livre'));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('statut echec : icone close', (tester) async {
      await tester.pumpWidget(chip(index: 2, statut: 'echec'));
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('statut a_livrer : numero visible', (tester) async {
      await tester.pumpWidget(chip(index: 7, statut: 'a_livrer'));
      expect(find.text('7'), findsOneWidget);
    });
  });
}
