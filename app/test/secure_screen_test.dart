import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';
import 'package:opti_route/data/secure_screen_service.dart';

/// Tests du toggle FLAG_SECURE (carte #111) : persistance dans
/// ParametresRepository + appel MethodChannel cote SecureScreenService.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParametresRepository.secureScreen', () {
    late AppDatabase db;
    late ParametresRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ParametresRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('default = false', () async {
      expect(await repo.getSecureScreen(), isFalse);
    });

    test('set true -> get true, set false -> get false', () async {
      await repo.setSecureScreen(true);
      expect(await repo.getSecureScreen(), isTrue);
      await repo.setSecureScreen(false);
      expect(await repo.getSecureScreen(), isFalse);
    });

    test('watch reflete l\'etat courant', () async {
      // 1er emit = etat initial. On l'attend avant de muter pour eviter
      // toute course entre l'ecriture et le 1er read du stream Drift.
      expect(await repo.watchSecureScreen().first, isFalse);
      await repo.setSecureScreen(true);
      expect(await repo.watchSecureScreen().first, isTrue);
    });
  });

  group('SecureScreenService', () {
    const svc = SecureScreenService();
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SecureScreenService.channel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SecureScreenService.channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test('sur Android : invoque setSecure avec enable=true', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await svc.setSecure(true);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'setSecure');
      expect(calls.single.arguments, {'enable': true});
    });

    test('sur Android : enable=false passe bien false', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await svc.setSecure(false);
      expect(calls.single.arguments, {'enable': false});
    });

    test('hors Android (iOS) : aucun appel natif', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await svc.setSecure(true);
      expect(calls, isEmpty);
    });
  });
}
