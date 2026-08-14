import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/screens/scan_colis/alerts.dart';

/// Alertes du scan colis (carte #315). Le point critique teste ici :
/// elles PREVIENNENT sans BLOQUER -- un dismiss doit toujours laisser
/// le livreur avancer.
void main() {
  setUpAll(() async {
    // Les libelles de date ("3 juin") passent par DateFormat(..., 'fr'),
    // initialise dans main() en prod.
    await initializeDateFormatting('fr');
  });

  /// Stop en memoire (pas de Drift ici : ces fonctions sont pures et
  /// les dialogs n'ont besoin d'aucune base).
  Stop makeStop({
    int id = 1,
    String adresseBrute = '14 Impasse Bois',
    String? adresseNormalisee,
    String? nomClient,
    DateTime? livreLe,
  }) {
    return Stop(
      id: id,
      tourneeId: 1,
      adresseBrute: adresseBrute,
      adresseNormalisee: adresseNormalisee,
      type: 'livraison',
      nbColis: 1,
      priorite: 'flexible',
      dureeArretMin: 3,
      nomClient: nomClient,
      statutLivraison: livreLe == null ? 'a_livrer' : 'livre',
      livreLe: livreLe,
      positionLocked: false,
      creeLe: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
      deposeSansContact: false,
      codPaye: false,
    );
  }

  /// Pompe un ecran minimal dont le bouton "go" ouvre [open] et stocke
  /// le resultat. Retourne un getter sur ce resultat.
  Future<T? Function()> pumpDialogLauncher<T>(
    WidgetTester tester,
    Future<T> Function(BuildContext ctx) open,
  ) async {
    T? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              result = await open(ctx);
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return () => result;
  }

  group('scanStopLabel', () {
    test('nom client quand il est renseigne', () {
      expect(scanStopLabel(makeStop(nomClient: 'Dupont')), 'Dupont');
    });

    test('fallback adresse normalisee si pas de nom', () {
      expect(
        scanStopLabel(makeStop(adresseNormalisee: '14 rue X, 28000 Chartres')),
        '14 rue X, 28000 Chartres',
      );
    });

    test('fallback adresse brute en dernier recours', () {
      expect(scanStopLabel(makeStop(nomClient: '   ')), '14 Impasse Bois');
    });
  });

  group('relivraisonSummary', () {
    // `now` est toujours passe explicitement : sans ca la phrase
    // dependrait de l'horloge du runner CI (le 3 juin, la meme donnee
    // dirait "aujourd'hui").
    final now = DateTime(2026, 6, 30, 10);

    test('dit QUOI et QUAND : jour, heure et chez qui', () {
      final s = makeStop(
        nomClient: 'Dupont',
        livreLe: DateTime(2026, 6, 3, 14, 5),
      );
      expect(
        relivraisonSummary(s, now: now),
        'Livre le 3 juin a 14:05 chez Dupont',
      );
    });

    test('livraison du jour : "aujourd\'hui", pas une date', () {
      // Cas le plus frequent sur le terrain : l'arret a ete valide plus
      // tot dans la tournee EN COURS. Annoncer une date seche (voire
      // "dans les 30 derniers jours") ferait passer une validation de
      // 09:12 pour une vieille livraison.
      final s = makeStop(
        nomClient: 'Dupont',
        livreLe: DateTime(2026, 6, 30, 9, 12),
      );
      expect(
        relivraisonSummary(s, now: now),
        'Livre aujourd\'hui a 09:12 chez Dupont',
      );
    });

    test('veille au soir : "hier" et pas "aujourd\'hui" (jours calendaires)',
        () {
      // 23:40 la veille = moins de 24 h avant `now`, mais c'est bien
      // hier : on compare des dates, pas des durees.
      final s = makeStop(
        nomClient: 'Dupont',
        livreLe: DateTime(2026, 6, 29, 23, 40),
      );
      expect(
        relivraisonSummary(s, now: now),
        'Livre hier a 23:40 chez Dupont',
      );
    });

    test('sans horodatage : phrase degradee mais lisible', () {
      expect(
        relivraisonSummary(makeStop(nomClient: 'Dupont'), now: now),
        'Deja livre chez Dupont',
      );
    });
  });

  group('askConfirmRelivraison', () {
    final now = DateTime(2026, 6, 30, 10);

    testWidgets('affiche ce qui a ete detecte et quand', (tester) async {
      final s = makeStop(
        nomClient: 'Dupont',
        livreLe: DateTime(2026, 6, 3, 14, 5),
      );
      await pumpDialogLauncher<bool>(
        tester,
        (ctx) => askConfirmRelivraison(ctx, dejaLivre: s, now: now),
      );
      expect(find.text('Colis deja livre ?'), findsOneWidget);
      expect(find.textContaining('3 juin'), findsOneWidget);
      expect(find.textContaining('Dupont'), findsOneWidget);
      // Le bandeau ne doit pas affirmer une anciennete qu'il ignore :
      // la fenetre de recherche est de 30 j, la livraison peut dater de
      // 10 minutes.
      expect(find.textContaining('30 derniers jours'), findsNothing);
    });

    testWidgets('dismiss = continuer (l\'alerte ne verrouille pas)',
        (tester) async {
      final s = makeStop(
        nomClient: 'Dupont',
        livreLe: DateTime(2026, 6, 3, 14, 5),
      );
      final choix = await pumpDialogLauncher<bool>(
        tester,
        (ctx) => askConfirmRelivraison(ctx, dejaLivre: s, now: now),
      );
      // Tap hors du dialog : on sort sans rien choisir.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(choix(), isTrue);
    });

    testWidgets('"Ne pas rattacher" renvoie false', (tester) async {
      final s = makeStop(
        nomClient: 'Dupont',
        livreLe: DateTime(2026, 6, 3, 14, 5),
      );
      final choix = await pumpDialogLauncher<bool>(
        tester,
        (ctx) => askConfirmRelivraison(ctx, dejaLivre: s, now: now),
      );
      await tester.tap(find.text('Ne pas rattacher'));
      await tester.pumpAndSettle();
      expect(choix(), isFalse);
    });
  });

  group('askWrongStopChoice', () {
    testWidgets('propose de basculer sur l\'arret suggere', (tester) async {
      final attendu = makeStop(nomClient: 'Dupont');
      final suggere =
          makeStop(id: 2, adresseBrute: '2 rue U', nomClient: 'Martin');
      final choix = await pumpDialogLauncher<WrongStopChoice>(
        tester,
        (ctx) => askWrongStopChoice(
          ctx,
          expected: attendu,
          suggested: suggere,
        ),
      );
      expect(find.text('Martin'), findsOneWidget);
      await tester.tap(find.text('Basculer'));
      await tester.pumpAndSettle();
      expect(choix(), WrongStopChoice.basculer);
    });

    testWidgets('dismiss = garder l\'arret attendu, jamais d\'annulation',
        (tester) async {
      final attendu = makeStop(nomClient: 'Dupont');
      final suggere =
          makeStop(id: 2, adresseBrute: '2 rue U', nomClient: 'Martin');
      final choix = await pumpDialogLauncher<WrongStopChoice>(
        tester,
        (ctx) => askWrongStopChoice(
          ctx,
          expected: attendu,
          suggested: suggere,
        ),
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(choix(), WrongStopChoice.continuer);
    });
  });
}
