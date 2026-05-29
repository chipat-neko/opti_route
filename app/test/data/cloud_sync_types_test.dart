import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_sync_types.dart';

CloudPullStats _stats({int ins = 0, int upd = 0, int skip = 0}) =>
    CloudPullStats(inserted: ins, updated: upd, skipped: skip);

CloudPullResult _empty() => CloudPullResult(
      coequipiers: _stats(),
      tournees: _stats(),
      stops: _stats(),
      savedDestinations: _stats(),
    );

void main() {
  group('CloudSyncException', () {
    test('toString = message', () {
      expect(const CloudSyncException('echec push').toString(), 'echec push');
    });
  });

  group('CloudPullStats', () {
    test('total = inserted + updated (ignore skipped)', () {
      expect(_stats(ins: 3, upd: 2).total, 5);
      expect(_stats(ins: 0, upd: 0, skip: 7).total, 0);
    });
  });

  group('CloudPullResult', () {
    test('totalChanged et totalSkipped a zero quand tout vide', () {
      final r = _empty();
      expect(r.totalChanged, 0);
      expect(r.totalSkipped, 0);
    });

    test('totalChanged additionne les 4 groupes', () {
      final r = CloudPullResult(
        coequipiers: _stats(ins: 1),
        tournees: _stats(upd: 2),
        stops: _stats(ins: 3, upd: 4),
        savedDestinations: _stats(ins: 5),
      );
      expect(r.totalChanged, 1 + 2 + 7 + 5);
    });

    test('totalSkipped additionne les 4 groupes', () {
      final r = CloudPullResult(
        coequipiers: _stats(skip: 1),
        tournees: _stats(skip: 2),
        stops: _stats(skip: 3),
        savedDestinations: _stats(skip: 4),
      );
      expect(r.totalSkipped, 10);
    });

    test('summary : tout vide -> "Tout etait deja a jour. Rien a synchroniser"',
        () {
      final s = _empty().summary;
      expect(s, contains('Tout etait deja a jour'));
      expect(s, contains('Rien a synchroniser'));
    });

    test('summary : tout vide + skipped > 0 -> mentionne cloud plus ancien', () {
      final r = CloudPullResult(
        coequipiers: _stats(),
        tournees: _stats(skip: 3),
        stops: _stats(),
        savedDestinations: _stats(),
      );
      expect(r.summary, contains('Tout etait deja a jour'));
      expect(r.summary, contains('3 element'));
      expect(r.summary, contains('cloud plus ancien'));
    });

    test('summary : changements multi-groupes formate la liste ordonnee', () {
      final r = CloudPullResult(
        coequipiers: _stats(ins: 1),
        tournees: _stats(ins: 2),
        stops: _stats(ins: 5),
        savedDestinations: _stats(),
      );
      final s = r.summary;
      expect(s, contains('8 element(s)'));
      expect(s, contains('2 tournee'));
      expect(s, contains('5 arret'));
      expect(s, contains('1 coequipier'));
    });

    test('summary : suffix "(N ignore(s))" quand skipped > 0', () {
      final r = CloudPullResult(
        coequipiers: _stats(),
        tournees: _stats(ins: 1),
        stops: _stats(),
        savedDestinations: _stats(skip: 2),
      );
      expect(r.summary, contains('2 ignore'));
    });
  });

  group('TourneeMembreInfo', () {
    test('isOwner = true si role "owner"', () {
      final m = TourneeMembreInfo(
        userCloudId: 'u1',
        email: 'a@x.fr',
        role: 'owner',
        joinedAt: DateTime(2026),
      );
      expect(m.isOwner, isTrue);
    });

    test('isOwner = false sinon', () {
      final m = TourneeMembreInfo(
        userCloudId: 'u2',
        email: 'b@x.fr',
        role: 'member',
        joinedAt: DateTime(2026),
      );
      expect(m.isOwner, isFalse);
    });
  });
}
