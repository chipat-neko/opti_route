import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud/cloud_membres_entreprise_sync.dart';

/// Tests du modèle EntrepriseMembreInfo (carte #366), surtout le getter
/// pur `joursAvantExpiration` (logique du lockout J+30, cron #363).
void main() {
  EntrepriseMembreInfo membre({
    required String statut,
    DateTime? revokedAt,
  }) {
    return EntrepriseMembreInfo(
      userId: 'u1',
      email: 'marc@exemple.com',
      role: 'employe',
      statut: statut,
      revokedAt: revokedAt,
    );
  }

  group('joursAvantExpiration (#366)', () {
    test('membre actif -> null (pas de countdown)', () {
      expect(membre(statut: 'actif').joursAvantExpiration, isNull);
    });

    test('révoqué sans revokedAt -> null (défensif)', () {
      expect(membre(statut: 'revoque').joursAvantExpiration, isNull);
    });

    test('révoqué il y a 0 jour -> ~30 jours restants', () {
      final m = membre(
        statut: 'revoque',
        revokedAt: DateTime.now(),
      );
      // 29 ou 30 selon l'heure (inDays tronque) : on borne.
      expect(m.joursAvantExpiration, inInclusiveRange(29, 30));
    });

    test('révoqué il y a 10 jours -> ~20 jours restants', () {
      final m = membre(
        statut: 'revoque',
        revokedAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(m.joursAvantExpiration, inInclusiveRange(19, 20));
    });

    test('révoqué il y a 40 jours -> 0 (jamais négatif)', () {
      final m = membre(
        statut: 'revoque',
        revokedAt: DateTime.now().subtract(const Duration(days: 40)),
      );
      expect(m.joursAvantExpiration, 0);
    });

    test('statut expiré -> null', () {
      expect(
        membre(statut: 'expire', revokedAt: DateTime.now()).joursAvantExpiration,
        isNull,
      );
    });
  });
}
