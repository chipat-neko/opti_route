// Test unitaire du CarnetAutoPushService : verifie que le watch Drift
// + debounce 5s detecte uniquement les rows dont updatedAt a avance
// (1er emit = baseline, pas de push) et appelle pushSavedDestination
// pour chaque row identifiee.
//
// Ne touche pas a Supabase : on injecte un FakeCloudSyncService qui
// compte les appels. Lightweight, pas de reseau.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/carnet_auto_push_service.dart';
import 'package:opti_route/data/cloud_sync_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('CarnetAutoPushService', () {
    late AppDatabase db;
    late _FakeCloudSync sync;
    late _FakeSupabaseService supabase;
    late CarnetAutoPushService service;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sync = _FakeCloudSync();
      supabase = _FakeSupabaseService(userPresent: true);
      service = CarnetAutoPushService(sync, db, supabase);
    });

    tearDown(() async {
      service.stop();
      await db.close();
    });

    test('1er emit = baseline, aucun push declenche', () async {
      // Pre-load la table : ces rows seront le snapshot initial.
      await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'baseline',
              lat: 48.0,
              lng: 1.0,
            ),
          );

      service.start();
      // Laisse le watch emettre une fois.
      await _waitMs(50);
      // Force le flush qui pousserait s'il y avait des ids en attente.
      await service.flush();

      expect(sync.pushedIds, isEmpty,
          reason: 'le 1er emit ne doit pas push (baseline)');
    });

    test('insert apres baseline -> push apres flush', () async {
      // Baseline avec 1 entree.
      await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'baseline',
              lat: 48.0,
              lng: 1.0,
            ),
          );
      service.start();
      await _waitMs(50);

      // Insert apres baseline.
      final newId = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'nouveau client',
              lat: 48.5,
              lng: 1.5,
            ),
          );
      await _waitMs(50);
      await service.flush();

      expect(sync.pushedIds, contains(newId));
    });

    test('update apres baseline -> push de la row modifiee', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'init',
              lat: 48.0,
              lng: 1.0,
            ),
          );
      service.start();
      await _waitMs(50);

      // Update : touche updatedAt explicitement (le trigger AFTER UPDATE
      // s'en charge en prod mais on a un noop trigger dans memory).
      await (db.update(db.savedDestinations)..where((d) => d.id.equals(id)))
          .write(SavedDestinationsCompanion(
        nomClient: const Value('Acme Corp'),
        updatedAt: Value(DateTime.now().add(const Duration(seconds: 1))),
      ));
      await _waitMs(50);
      await service.flush();

      expect(sync.pushedIds, [id]);
    });

    test('user pas connecte -> pending conserve, pas de push', () async {
      supabase.userPresent = false;
      await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'baseline',
              lat: 48.0,
              lng: 1.0,
            ),
          );
      service.start();
      await _waitMs(50);

      await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'nouveau',
              lat: 48.5,
              lng: 1.5,
            ),
          );
      await _waitMs(50);
      await service.flush();

      expect(sync.pushedIds, isEmpty,
          reason: 'pas connecte -> pas de push effectif');
    });

    test('stop() puis start() re-utilise le snapshot connu', () async {
      final id = await db.into(db.savedDestinations).insert(
            SavedDestinationsCompanion.insert(
              adresseDisplay: 'init',
              lat: 48.0,
              lng: 1.0,
            ),
          );
      service.start();
      await _waitMs(50);

      service.stop();
      // Re-start : pas de nouvelle baseline car _initialized=true persiste.
      service.start();
      await _waitMs(50);
      await service.flush();

      expect(sync.pushedIds, isEmpty,
          reason: 'aucune modif entre stop/start -> aucun push attendu');

      // Modif post-restart -> doit etre detectee.
      await (db.update(db.savedDestinations)..where((d) => d.id.equals(id)))
          .write(SavedDestinationsCompanion(
        isFavori: const Value(true),
        updatedAt: Value(DateTime.now().add(const Duration(seconds: 1))),
      ));
      await _waitMs(50);
      await service.flush();

      expect(sync.pushedIds, [id]);
    });
  });
}

/// Attend [ms] millisecondes. Drift watch + Timer ont besoin d'un peu
/// de breathing room pour delivrer leurs events (microtask + delay).
Future<void> _waitMs(int ms) => Future.delayed(Duration(milliseconds: ms));

/// Fake CloudSyncService qui ne contacte pas Supabase. Compte les
/// pushSavedDestination dans une liste pour assertions.
class _FakeCloudSync implements CloudSyncService {
  final List<int> pushedIds = [];

  @override
  Future<void> pushSavedDestination(int localId) async {
    pushedIds.add(localId);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake SupabaseService qui peut faire varier l'etat "connecte" via
/// [userPresent]. Le service teste ne touche qu'a `currentUser`.
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
