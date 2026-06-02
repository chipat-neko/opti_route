import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud/cloud_entreprise_sync.dart' show MonRole;
import 'package:opti_route/data/cloud/cloud_membres_entreprise_sync.dart'
    show EntrepriseMembreInfo;

/// Tests de la feature « nom d'affichage » + rôle menu (nuit 2026-06-01).
/// Logique pure (pas de réseau) : verrouille le fallback email et les
/// titres de menu selon le rôle.
void main() {
  group('EntrepriseMembreInfo.nomAffiche', () {
    EntrepriseMembreInfo make({String? displayName}) => EntrepriseMembreInfo(
          userId: 'u1',
          email: 'lucas@exemple.com',
          role: 'employe',
          statut: 'actif',
          displayName: displayName,
        );

    test('affiche le nom si défini', () {
      expect(make(displayName: 'Lucas M.').nomAffiche, 'Lucas M.');
    });

    test('retombe sur l\'email si nom null', () {
      expect(make(displayName: null).nomAffiche, 'lucas@exemple.com');
    });

    test('retombe sur l\'email si nom vide ou espaces', () {
      expect(make(displayName: '   ').nomAffiche, 'lucas@exemple.com');
      expect(make(displayName: '').nomAffiche, 'lucas@exemple.com');
    });

    test('trim le nom affiché', () {
      expect(make(displayName: '  Lucas  ').nomAffiche, 'Lucas');
    });
  });

  group('MonRole.titreMenu', () {
    test('chef d\'entreprise -> « Mon entreprise »', () {
      const r = MonRole(
        entrepriseId: 'e1',
        entrepriseNom: 'CALOTE',
        roleGlobal: 'admin_entreprise',
      );
      expect(r.isAdminEntreprise, isTrue);
      expect(r.titreMenu, 'Mon entreprise');
    });

    test('chef d\'entrepôt -> « Mon entrepôt X »', () {
      const r = MonRole(
        entrepriseId: 'e1',
        entrepriseNom: 'CALOTE',
        roleGlobal: 'membre',
        entrepotId: 'ep1',
        entrepotNom: 'Chartres',
        roleEntrepot: 'chef_entrepot',
      );
      expect(r.isAdminEntreprise, isFalse);
      expect(r.isChefEntrepot, isTrue);
      expect(r.titreMenu, 'Mon entrepôt Chartres');
    });

    test('chauffeur -> « Mon entrepôt X » (pas chef)', () {
      const r = MonRole(
        entrepriseId: 'e1',
        entrepriseNom: 'CALOTE',
        roleGlobal: 'membre',
        entrepotId: 'ep1',
        entrepotNom: 'Le Mans',
        roleEntrepot: 'employe',
      );
      expect(r.isChefEntrepot, isFalse);
      expect(r.titreMenu, 'Mon entrepôt Le Mans');
    });

    test('entrepôt sans nom -> « Mon entrepôt » sans espace en trop', () {
      const r = MonRole(
        entrepriseId: 'e1',
        entrepriseNom: 'CALOTE',
        roleGlobal: 'membre',
        roleEntrepot: 'employe',
      );
      expect(r.titreMenu, 'Mon entrepôt');
    });
  });
}
