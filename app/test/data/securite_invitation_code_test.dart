import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud/cloud_sync_helpers.dart';

/// Tests sécurité poussés (nuit 2026-06-01) sur les codes d'invitation.
/// Mentalité « un attaquant cherche les faiblesses » : on vérifie que
/// les codes sont bien formés, non triviaux/prévisibles, et que la
/// traduction d'erreur ne fuite pas de détail technique inutile.
void main() {
  group('generateInvitationCode — format & robustesse', () {
    test('toujours exactement 6 chiffres', () {
      for (var i = 0; i < 2000; i++) {
        final c = generateInvitationCode();
        expect(c, matches(RegExp(r'^\d{6}$')),
            reason: 'code mal formé : "$c"');
      }
    });

    test('conserve les leading zeros (espace 000000-999999 complet)', () {
      // Sur 5000 tirages, on doit voir au moins un code commençant par 0
      // (sinon le padding serait cassé -> espace de clés réduit = + facile
      // à brute-forcer).
      var vusAvecZeroDevant = 0;
      for (var i = 0; i < 5000; i++) {
        if (generateInvitationCode().startsWith('0')) vusAvecZeroDevant++;
      }
      expect(vusAvecZeroDevant, greaterThan(0),
          reason: 'aucun code avec 0 en tête -> padding/espace de clés cassé');
    });

    test('pas de collision triviale : 2 appels successifs diffèrent (proba)',
        () {
      // L'ancien bug (DateTime XOR) renvoyait quasi toujours le même code.
      // Sur 1000 paires successives, on tolère très peu de collisions
      // (1/1e6 par paire). 0 attendu en pratique.
      var collisions = 0;
      for (var i = 0; i < 1000; i++) {
        if (generateInvitationCode() == generateInvitationCode()) {
          collisions++;
        }
      }
      expect(collisions, lessThan(3),
          reason: 'trop de collisions successives -> RNG dégénéré');
    });

    test('bonne dispersion : >900 valeurs distinctes sur 1000 tirages', () {
      final s = <String>{};
      for (var i = 0; i < 1000; i++) {
        s.add(generateInvitationCode());
      }
      // Avec 1e6 valeurs possibles, 1000 tirages -> ~quasi tous distincts.
      expect(s.length, greaterThan(900),
          reason: 'faible entropie : codes prévisibles');
    });
  });

  group('invitationErrorToFr — pas de fuite + couvre les sentinelles', () {
    test('AUTH_REQUIRED -> message connexion', () {
      expect(invitationErrorToFr('PostgrestException: AUTH_REQUIRED'),
          contains('Connecte-toi'));
    });
    test('CODE_INTROUVABLE -> message clair', () {
      expect(invitationErrorToFr('... CODE_INTROUVABLE ...'),
          contains('n\'existe pas'));
    });
    test('CODE_EXPIRE -> message clair', () {
      expect(invitationErrorToFr('CODE_EXPIRE'), contains('expire'));
    });
    test('CODE_DEJA_UTILISE -> message clair', () {
      expect(invitationErrorToFr('CODE_DEJA_UTILISE'),
          contains('deja ete utilise'));
    });
    test('message inconnu : reste générique (pas de crash)', () {
      final r = invitationErrorToFr('weird error 42');
      expect(r, isNotEmpty);
    });
  });
}
