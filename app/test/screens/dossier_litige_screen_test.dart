import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/screens/dossier_litige_screen.dart';
import 'package:opti_route/theme/app_theme.dart';

/// Le dossier litige contient des donnees personnelles (nom, adresse,
/// position GPS, reference photo) et le depot est public. Regle
/// tranchee par le proprietaire : il se genere et s'affiche librement,
/// mais RIEN ne sort de l'app sans une confirmation explicite qui
/// enonce ce que le document contient.
///
/// Ces tests verrouillent cette regle : ils echouent si un jour le
/// bouton partage appelle directement le share natif, ou si quelqu'un
/// remet une copie presse-papiers "au cas ou".
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Arret livre SANS photo preuve : aucune lecture disque, l'ecran se
  /// compose donc entierement dans le zone de test (pas de runAsync).
  Stop mkStop() => Stop(
        id: 7,
        tourneeId: 1,
        adresseBrute: '14 rue de la Paix, 28000 Chartres',
        type: 'livraison',
        lat: 48.43,
        lng: 1.49,
        nbColis: 2,
        priorite: 'normale',
        dureeArretMin: 3,
        nomClient: 'Mme Dupont',
        statutLivraison: 'livre',
        livreLat: 48.4301,
        livreLng: 1.4902,
        livreLe: DateTime(2026, 5, 30, 14, 7),
        positionLocked: false,
        creeLe: DateTime(2026, 5, 30),
        updatedAt: DateTime(2026, 5, 30),
        deposeSansContact: false,
        codPaye: false,
      );

  /// Pompe l'ecran avec un partage espionne + un espion sur le channel
  /// natif (c'est par la que passe `Clipboard.setData`).
  Future<(List<String>, List<MethodCall>)> pumpEcran(
      WidgetTester tester) async {
    final partages = <String>[];
    final appelsNatifs = <MethodCall>[];
    // Ecran haut : le dossier est long, on veut le bouton de partage
    // reellement pose dans la viewport (pas de tap sur du hors-champ).
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      appelsNatifs.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DossierLitigeScreen(
          stop: mkStop(),
          shareFn: ({required String text, required String subject}) async {
            partages.add(text);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (partages, appelsNatifs);
  }

  Future<void> tapPartager(WidgetTester tester) async {
    final bouton = find.text('Partager le dossier');
    await tester.ensureVisible(bouton);
    await tester.pumpAndSettle();
    await tester.tap(bouton);
    await tester.pumpAndSettle();
  }

  testWidgets('affiche le dossier et son empreinte sans rien partager',
      (tester) async {
    final (partages, appelsNatifs) = await pumpEcran(tester);

    expect(find.textContaining('DOSSIER LITIGE OPPOSABLE'), findsWidgets);
    expect(find.textContaining('Mme Dupont'), findsWidgets);
    expect(find.text('EMPREINTE SHA-256'), findsOneWidget);
    expect(find.textContaining('SHA-256:'), findsWidgets);

    // Generation et affichage sont libres : rien n'est sorti de l'app.
    expect(partages, isEmpty);
    expect(
      appelsNatifs.where((c) => c.method == 'Clipboard.setData'),
      isEmpty,
      reason: 'aucune copie presse-papiers par defaut',
    );
  });

  testWidgets('tap sur Partager : dialog de confirmation, rien ne part',
      (tester) async {
    final (partages, appelsNatifs) = await pumpEcran(tester);
    await tapPartager(tester);

    expect(find.text('Partager ce dossier ?'), findsOneWidget);
    // Le dialog ENONCE le contenu personnel du document.
    expect(find.textContaining('Nom du client'), findsOneWidget);
    expect(find.textContaining('Adresse de livraison'), findsOneWidget);
    expect(find.textContaining('Position GPS de passage'), findsOneWidget);
    expect(find.textContaining('Photo preuve'), findsOneWidget);

    expect(partages, isEmpty, reason: 'rien avant la confirmation');
    expect(
      appelsNatifs.where((c) => c.method == 'Clipboard.setData'),
      isEmpty,
    );
  });

  testWidgets('Annuler la confirmation : toujours aucun partage',
      (tester) async {
    final (partages, appelsNatifs) = await pumpEcran(tester);
    await tapPartager(tester);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Partager ce dossier ?'), findsNothing);
    expect(partages, isEmpty);
    expect(
      appelsNatifs.where((c) => c.method == 'Clipboard.setData'),
      isEmpty,
    );
  });

  testWidgets('confirmation explicite : le dossier part une seule fois',
      (tester) async {
    final (partages, _) = await pumpEcran(tester);
    await tapPartager(tester);

    await tester.tap(find.text('Oui, partager'));
    await tester.pumpAndSettle();

    expect(partages, hasLength(1));
    expect(partages.single, contains('DOSSIER LITIGE OPPOSABLE'));
    expect(partages.single, contains('SHA-256:'));
  });
}
