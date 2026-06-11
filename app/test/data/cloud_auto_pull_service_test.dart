import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_auto_pull_service.dart';
import 'package:opti_route/data/cloud_sync_service.dart';
import 'package:opti_route/data/cloud_sync_types.dart';

/// Tests de l'auto-pull au sign-in (audit 2026-06-11). Le service est
/// un wrapper fin de [CloudSyncService.pullAllForCurrentUser] : on
/// verifie la delegation et la propagation fidele du resultat et des
/// erreurs (l'UI s'appuie dessus pour la SnackBar resume / l'etat
/// d'erreur de cloudPullStateProvider).
void main() {
  test('delegue a pullAllForCurrentUser et propage le resultat', () async {
    const expected = CloudPullResult(
      coequipiers: CloudPullStats(inserted: 1, updated: 0),
      tournees: CloudPullStats(inserted: 2, updated: 1),
      stops: CloudPullStats(inserted: 5, updated: 0, skipped: 3),
      savedDestinations: CloudPullStats(inserted: 0, updated: 0),
    );
    final sync = _FakeCloudSync(result: expected);
    final service = CloudAutoPullService(sync);

    final r = await service.runAutoPullOnSignIn();

    expect(sync.pullCalls, 1);
    expect(identical(r, expected), isTrue);
    expect(r.totalChanged, 9);
    expect(r.totalSkipped, 3);
  });

  test('propage CloudSyncException sans la transformer', () async {
    final sync = _FakeCloudSync(error: const CloudSyncException('RLS bloque'));
    final service = CloudAutoPullService(sync);

    await expectLater(
      service.runAutoPullOnSignIn(),
      throwsA(
        isA<CloudSyncException>()
            .having((e) => e.message, 'message', 'RLS bloque'),
      ),
    );
  });

  test('chaque appel relance un pull (pas de cache/flag)', () async {
    // 2.D-1d : le flag "pull deja fait" a ete retire, on doit puller a
    // CHAQUE sign-in (multi-device). Ce test fige ce comportement.
    const empty = CloudPullResult(
      coequipiers: CloudPullStats(inserted: 0, updated: 0),
      tournees: CloudPullStats(inserted: 0, updated: 0),
      stops: CloudPullStats(inserted: 0, updated: 0),
      savedDestinations: CloudPullStats(inserted: 0, updated: 0),
    );
    final sync = _FakeCloudSync(result: empty);
    final service = CloudAutoPullService(sync);

    await service.runAutoPullOnSignIn();
    await service.runAutoPullOnSignIn();

    expect(sync.pullCalls, 2);
  });
}

/// Fake limite a la seule methode utilisee par le service. Tout autre
/// appel = bug de perimetre -> UnimplementedError explicite.
class _FakeCloudSync implements CloudSyncService {
  _FakeCloudSync({this.result, this.error});

  final CloudPullResult? result;
  final Object? error;
  int pullCalls = 0;

  @override
  Future<CloudPullResult> pullAllForCurrentUser() async {
    pullCalls++;
    if (error != null) throw error!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'CloudAutoPullService ne devrait appeler que pullAllForCurrentUser '
      '(appel inattendu : ${invocation.memberName})');
}
