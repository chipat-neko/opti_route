import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_sync_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/supabase_service.dart';

/// Tests des guards de [CloudSyncService] : les conditions qui doivent
/// throw [CloudSyncException] avec un message explicite **avant** tout
/// appel reseau Supabase.
///
/// Le push reel (HTTP + insertion Postgres + write Drift local) est
/// teste manuellement en device dans le sous-jalon 2.B (cf
/// docs/supabase-setup.md), pas en unit test : mocker SupabaseClient
/// (Builder, From, Upsert) c'est lourd pour peu de valeur, et un test
/// end-to-end sur Supabase prod est plus parlant. On testera vraiment
/// la logique d'upsert dans le sous-jalon 2.D quand on aura l'auto-
/// sync background avec retry, ou on stub un mock light type-safe.
void main() {
  group('CloudSyncException', () {
    test('toString retourne le message', () {
      const e = CloudSyncException('Pas connecte');
      expect(e.toString(), 'Pas connecte');
      expect(e.message, 'Pas connecte');
    });
  });

  group('CloudSyncService.pushTournee guards', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('throw si cloud pas configure (build sans --dart-define)',
        () async {
      // En test sans --dart-define=SUPABASE_URL, SupabaseService.instance
      // a `isConfigured = false`. Le guard `_client()` doit throw
      // immediatement, avant meme de toucher la DB Drift.
      final service = CloudSyncService(db, SupabaseService.instance);

      await expectLater(
        () => service.pushTournee(1),
        throwsA(
          isA<CloudSyncException>().having(
            (e) => e.message,
            'message',
            contains('Cloud non disponible'),
          ),
        ),
      );
    });
  });
}
