import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud/cloud_admin_sync.dart';

/// Parsing des lignes renvoyées par la RPC admin_list_entreprises (#372).
/// La logique réseau (RPC) exige Supabase → non testable en unit ; on
/// couvre ici le mapping pur (robustesse aux champs null / timestamp).
void main() {
  group('AdminEntrepriseInfo.fromRow', () {
    test('mappe une ligne complète', () {
      final info = AdminEntrepriseInfo.fromRow({
        'cloud_id': 'ent-1',
        'nom': 'CALOTE',
        'siret': '12345678900011',
        'created_by': 'user-1',
        'cree_le': '2026-06-01T10:00:00.000Z',
      });
      expect(info.cloudId, 'ent-1');
      expect(info.nom, 'CALOTE');
      expect(info.siret, '12345678900011');
      expect(info.createdBy, 'user-1');
      expect(info.creeLe, isNotNull);
      expect(info.creeLe!.toUtc().year, 2026);
    });

    test('tolère siret null', () {
      final info = AdminEntrepriseInfo.fromRow({
        'cloud_id': 'ent-2',
        'nom': 'Sans SIRET',
        'siret': null,
        'created_by': 'user-2',
        'cree_le': '2026-06-01T10:00:00.000Z',
      });
      expect(info.siret, isNull);
    });

    test('tolère cree_le null sans crasher', () {
      final info = AdminEntrepriseInfo.fromRow({
        'cloud_id': 'ent-3',
        'nom': 'X',
        'siret': null,
        'created_by': 'user-3',
        'cree_le': null,
      });
      expect(info.creeLe, isNull);
    });
  });
}
