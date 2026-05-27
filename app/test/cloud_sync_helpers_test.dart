// Tests pour les helpers purs de sync cloud extraits du
// CloudSyncService (carte Trello #167 etape 1).

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud/cloud_sync_helpers.dart';

void main() {
  group('generateInvitationCode', () {
    test('6 chiffres avec leading zeros preserves', () {
      for (var i = 0; i < 200; i++) {
        final code = generateInvitationCode();
        expect(code.length, 6);
        expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue,
            reason: 'code "$code" doit etre 6 chiffres');
      }
    });

    test('genere des codes varies (pas un constant)', () {
      final codes = <String>{};
      for (var i = 0; i < 50; i++) {
        codes.add(generateInvitationCode());
      }
      // Avec 50 tirages sur 1M de combinaisons, on attend ~50 valeurs
      // distinctes. Tolerance large : au moins 40 pour eviter le flake.
      expect(codes.length, greaterThan(40));
    });
  });

  group('invitationErrorToFr', () {
    test('AUTH_REQUIRED -> message connexion', () {
      expect(invitationErrorToFr('AUTH_REQUIRED'),
          contains('Connecte-toi'));
    });

    test('CODE_INTROUVABLE -> verifier avec chef', () {
      expect(invitationErrorToFr('CODE_INTROUVABLE: 123456'),
          contains('n\'existe pas'));
    });

    test('CODE_EXPIRE -> demande nouveau code', () {
      expect(invitationErrorToFr('CODE_EXPIRE'), contains('expire'));
    });

    test('CODE_DEJA_UTILISE -> deja utilise', () {
      expect(invitationErrorToFr('CODE_DEJA_UTILISE'),
          contains('deja ete utilise'));
    });

    test('message inconnu -> fallback brut', () {
      final out = invitationErrorToFr('boom timeout 500');
      expect(out, contains('Echec acceptation'));
      expect(out, contains('boom timeout 500'));
    });
  });

  group('parseCloudUpdatedAt', () {
    test('ISO 8601 valide -> DateTime local', () {
      final d = parseCloudUpdatedAt('2026-05-16T14:23:45.000Z');
      expect(d.toUtc(), DateTime.utc(2026, 5, 16, 14, 23, 45));
    });

    test('null -> epoch 0 (infiniment ancien)', () {
      expect(parseCloudUpdatedAt(null),
          DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('type non-string -> epoch 0', () {
      expect(parseCloudUpdatedAt(12345),
          DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('cloudIsNewer', () {
    test('cloud > local + 1s -> true (ecraser local)', () {
      final local = DateTime(2026, 5, 16, 14, 0, 0);
      final cloud = DateTime(2026, 5, 16, 14, 0, 5);
      expect(cloudIsNewer(cloud, local), isTrue);
    });

    test('cloud == local -> false (tolerance 1s, skip)', () {
      final t = DateTime(2026, 5, 16, 14, 0, 0);
      expect(cloudIsNewer(t, t), isFalse);
    });

    test('cloud dans la tolerance 1s -> false', () {
      final local = DateTime(2026, 5, 16, 14, 0, 0);
      final cloud = DateTime(2026, 5, 16, 14, 0, 0, 800); // +0.8s
      expect(cloudIsNewer(cloud, local), isFalse);
    });

    test('cloud < local -> false (garder local)', () {
      final local = DateTime(2026, 5, 16, 14, 0, 10);
      final cloud = DateTime(2026, 5, 16, 14, 0, 0);
      expect(cloudIsNewer(cloud, local), isFalse);
    });
  });
}
