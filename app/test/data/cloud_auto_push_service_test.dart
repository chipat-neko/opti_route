// Test unitaire du CloudAutoPushService (audit 2026-06-11 : service
// critique du flux "tournee en cours", aucun filet avant).
//
// Verifie le cycle watch Drift -> debounce -> push silencieux, ainsi
// que les garde-fous : user deconnecte, fenetre de suppression
// Realtime, stop(), et erreurs de push avalees sans crash.
//
// Ne touche pas a Supabase : FakeCloudSyncService qui compte les
// appels, meme pattern que carnet_auto_push_test.dart.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud_auto_push_service.dart';
import 'package:opti_route/data/cloud_sync_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('CloudAutoPushService', () {
    late AppDatabase db;
    late _FakeCloudSync sync;
    late _FakeSupabaseService supabase;
    late CloudAutoPushService service;
    late int tourneeId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      sync = _FakeCloudSync();
      supabase = _FakeSupabaseService(userPresent: true);
      service = CloudAutoPushService(sync, db, supabase);
      tourneeId = await db.into(db.tournees).insert(
            TourneesCompanion(
              nom: const Value('Tournee test'),
              date: Value(DateTime(2026, 6, 1)),
              pointDepartLat: const Value(48.0),
              pointDepartLng: const Value(1.0),
              pointDepartLabel: const Value('Depot'),
            ),
          );
    });

    tearDown(() async {
      service.stop();
      await db.close();
    });

    test('etat initial : idle, aucun push', () {
      expect(service.currentState, AutoPushState.idle);
      expect(sync.pushedIds, isEmpty);
    });

    test('watchTournee : le 1er emit arme le debounce (etat pending)',
        () async {
      service.watchTournee(tourneeId);
      await _waitMs(50);
      expect(service.currentState, AutoPushState.pending);
      // Mais pas de push tant que le debounce 5s n'a pas expire.
      expect(sync.pushedIds, isEmpty);
    });

    test('flush() pendant un debounce : push immediat puis idle', () async {
      service.watchTournee(tourneeId);
      await _waitMs(50); // laisse le watch emettre -> debounce arme
      await service.flush();

      expect(sync.pushedIds, [tourneeId]);
      expect(service.currentState, AutoPushState.idle);
    });

    test('flush() sans watch actif : no-op', () async {
      await service.flush();
      expect(sync.pushedIds, isEmpty);
    });

    test('flush() user deconnecte : no-op silencieux', () async {
      supabase.userPresent = false;
      service.watchTournee(tourneeId);
      await _waitMs(50);
      await service.flush();

      expect(sync.pushedIds, isEmpty);
    });

    test('suppress() bloque le flush pendant la fenetre Realtime',
        () async {
      // Cas anti-boucle : le Realtime vient d'appliquer un event local,
      // le watch Drift le voit comme une modif -> sans suppress, on
      // re-pousserait ce qu'on vient de recevoir.
      service.watchTournee(tourneeId);
      await _waitMs(50);
      service.suppress(const Duration(seconds: 10));
      await service.flush();

      expect(sync.pushedIds, isEmpty);
    });

    test('stop() : retour a idle et flush suivant no-op', () async {
      service.watchTournee(tourneeId);
      await _waitMs(50);
      expect(service.currentState, AutoPushState.pending);

      service.stop();
      expect(service.currentState, AutoPushState.idle);

      await service.flush();
      expect(sync.pushedIds, isEmpty);
    });

    test('stop() est idempotent', () {
      service.stop();
      expect(() => service.stop(), returnsNormally);
    });

    test('erreur de push : avalee (silencieux), etat revient a idle',
        () async {
      sync.throwOnPush = true;
      service.watchTournee(tourneeId);
      await _waitMs(50);

      // Ne doit pas propager : un push rate se re-tentera au prochain
      // changement, l'UI ne doit pas crasher.
      await expectLater(service.flush(), completes);
      expect(service.currentState, AutoPushState.idle);
    });

    test('modification de stop -> debounce re-arme', () async {
      service.watchTournee(tourneeId);
      await _waitMs(50);
      await service.flush(); // vide le debounce initial
      sync.pushedIds.clear();
      expect(service.currentState, AutoPushState.idle);

      // Un ajout de stop doit re-armer le debounce.
      await db.into(db.stops).insert(
            StopsCompanion(
              tourneeId: Value(tourneeId),
              adresseBrute: const Value('12 rue X'),
            ),
          );
      await _waitMs(50);
      expect(service.currentState, AutoPushState.pending);

      await service.flush();
      expect(sync.pushedIds, [tourneeId]);
    });

    test('watchTournee deux fois sur la meme tournee : no-op (pas de '
        'double souscription)', () async {
      service.watchTournee(tourneeId);
      await _waitMs(50);
      await service.flush();
      sync.pushedIds.clear();

      // 2e watch sur la meme tournee : ne doit pas re-armer un debounce
      // via une nouvelle souscription (1er emit).
      service.watchTournee(tourneeId);
      await _waitMs(50);
      expect(service.currentState, AutoPushState.idle);
    });
  });
}

/// Attend [ms] millisecondes. Drift watch + Timer ont besoin d'un peu
/// de breathing room pour delivrer leurs events (microtask + delay).
Future<void> _waitMs(int ms) => Future.delayed(Duration(milliseconds: ms));

/// Fake CloudSyncService qui ne contacte pas Supabase. Compte les
/// pushTournee dans une liste pour assertions.
class _FakeCloudSync implements CloudSyncService {
  final List<int> pushedIds = [];
  bool throwOnPush = false;

  @override
  Future<void> pushTournee(int localTourneeId) async {
    if (throwOnPush) {
      throw const CloudSyncException('reseau indisponible (test)');
    }
    pushedIds.add(localTourneeId);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake SupabaseService : seul `currentUser` est consulte par le
/// service teste.
class _FakeSupabaseService implements SupabaseService {
  _FakeSupabaseService({required this.userPresent});

  bool userPresent;

  @override
  User? get currentUser => userPresent ? _StubUser() : null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubUser implements User {
  @override
  String get id => 'stub-user-id';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
