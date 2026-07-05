import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/providers/app_lifecycle_provider.dart';

/// Tests de la logique de detection arriere-plan (feat/opti-batterie).
/// La fonction est pure : pas besoin de binding Flutter.
void main() {
  group('isAppBackground', () {
    test('paused = arriere-plan', () {
      expect(isAppBackground(AppLifecycleState.paused), isTrue);
    });

    test('hidden = arriere-plan', () {
      expect(isAppBackground(AppLifecycleState.hidden), isTrue);
    });

    test('resumed = premier plan', () {
      expect(isAppBackground(AppLifecycleState.resumed), isFalse);
    });

    test('inactive = premier plan (transitoire, evite le flapping)', () {
      // Un volet de notifs a demi tire / l'app switcher qui s'ouvre
      // emettent `inactive` : on ne doit PAS couper les streams pour ca,
      // sinon on les relance a chaque micro-transition.
      expect(isAppBackground(AppLifecycleState.inactive), isFalse);
    });

    test('tous les etats sont couverts (pas de defaut implicite oublie)',
        () {
      // Si Flutter ajoute un etat, ce test force a reconsiderer la regle.
      for (final s in AppLifecycleState.values) {
        final bg = isAppBackground(s);
        final expectedBg =
            s == AppLifecycleState.paused || s == AppLifecycleState.hidden;
        expect(bg, expectedBg, reason: 'etat $s mal classe');
      }
    });
  });
}
