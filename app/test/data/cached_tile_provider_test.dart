import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/cached_tile_provider.dart';

// Premier test pour CachedTileProvider : prefetchTile + cacheSizeBytes
// + clearCache. Mock path_provider via MethodChannel + MockClient pour
// l'HTTP. Pas de test du PNG transparent (Image rendering complexe).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('osm_tiles_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
      if (call.method == 'getApplicationCacheDirectory' ||
          call.method == 'getTemporaryDirectory' ||
          call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CachedTileProvider.prefetchTile', () {
    test('status 200 + body non vide : retourne true + cache disque',
        () async {
      final fakePng = List<int>.filled(100, 0x89);
      final mock = MockClient(
          (req) async => http.Response.bytes(fakePng, 200));
      final provider = CachedTileProvider(client: mock);
      final ok = await provider.prefetchTile(13, 4192, 2823);
      expect(ok, isTrue);
      // Verifie qu'un fichier a ete cree dans le cache
      expect(
        await Directory('${tempDir.path}/osm_tiles').exists(),
        isTrue,
      );
    });

    test('status 404 : retourne false (pas en cache, pas de poison)',
        () async {
      final mock = MockClient(
          (req) async => http.Response('not found', 404));
      final provider = CachedTileProvider(client: mock);
      final ok = await provider.prefetchTile(13, 9999, 9999);
      expect(ok, isFalse);
    });

    test('reseau down (throw) : retourne false silencieux', () async {
      final mock = MockClient((req) async {
        throw Exception('connection refused');
      });
      final provider = CachedTileProvider(client: mock);
      final ok = await provider.prefetchTile(13, 1, 1);
      expect(ok, isFalse);
    });

    test('body vide : retourne false (pas de cache vide)', () async {
      final mock =
          MockClient((req) async => http.Response.bytes([], 200));
      final provider = CachedTileProvider(client: mock);
      final ok = await provider.prefetchTile(13, 2, 2);
      expect(ok, isFalse);
    });

    test('tuile deja en cache : retourne true sans appel reseau', () async {
      var calls = 0;
      final fakePng = List<int>.filled(50, 0x42);
      final mock = MockClient((req) async {
        calls++;
        return http.Response.bytes(fakePng, 200);
      });
      final provider = CachedTileProvider(client: mock);
      // 1er appel : download
      await provider.prefetchTile(13, 5, 5);
      expect(calls, 1);
      // 2eme appel : cache hit
      final ok = await provider.prefetchTile(13, 5, 5);
      expect(ok, isTrue);
      expect(calls, 1, reason: 'pas de re-download');
    });
  });

  group('CachedTileProvider.cacheSizeBytes + clearCache', () {
    test('cache vide -> 0 bytes', () async {
      final mock = MockClient((req) async => http.Response('', 404));
      final provider = CachedTileProvider(client: mock);
      expect(await provider.cacheSizeBytes(), 0);
    });

    test('apres prefetch -> bytes > 0', () async {
      final fakePng = List<int>.filled(100, 0x89);
      final mock = MockClient(
          (req) async => http.Response.bytes(fakePng, 200));
      final provider = CachedTileProvider(client: mock);
      await provider.prefetchTile(13, 100, 100);
      expect(await provider.cacheSizeBytes(), greaterThan(0));
    });

    test('clearCache supprime tout', () async {
      final fakePng = List<int>.filled(100, 0x89);
      final mock = MockClient(
          (req) async => http.Response.bytes(fakePng, 200));
      final provider = CachedTileProvider(client: mock);
      await provider.prefetchTile(13, 200, 200);
      expect(await provider.cacheSizeBytes(), greaterThan(0));
      await provider.clearCache();
      expect(await provider.cacheSizeBytes(), 0);
    });

    test('clearCache idempotent : 2eme appel ne crash pas', () async {
      final mock = MockClient((req) async => http.Response('', 404));
      final provider = CachedTileProvider(client: mock);
      await provider.clearCache();
      await provider.clearCache();
      expect(await provider.cacheSizeBytes(), 0);
    });
  });
}
