import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/widgets/snack.dart';

// Regression carte #260 : dans la version Flutter du projet, un SnackBar avec
// une `action` a `persist=true` par defaut et ne s'auto-ferme jamais. Le helper
// snack.dart force `persist:false` -> ces tests verrouillent ce comportement.
void main() {
  testWidgets('un SnackBar avec action garde persist=false', (tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    messengerKey.currentState!.showSuccess(
      'arret livre',
      action: SnackBarAction(label: 'Photo preuve', onPressed: () {}),
    );
    await tester.pump();

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.action, isNotNull);
    expect(snack.persist, isFalse);
  });

  testWidgets('un SnackBar avec action s\'auto-ferme apres sa duree',
      (tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    messengerKey.currentState!.showError(
      'echec livraison',
      duration: const Duration(seconds: 2),
      action: SnackBarAction(label: 'Photo preuve', onPressed: () {}),
    );
    await tester.pump(); // insertion + debut animation d'entree
    await tester.pump(const Duration(milliseconds: 300)); // entree terminee
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(seconds: 2)); // declenche l'auto-dismiss
    await tester.pumpAndSettle(); // animation de sortie
    expect(find.byType(SnackBar), findsNothing);
  });
}
