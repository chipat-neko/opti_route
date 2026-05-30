import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/update_checker_service.dart';

void main() {
  group('UpdateCheckerService.check', () {
    String pubspecWith(String version) => '''
name: opti_route
description: "test"
version: $version

environment:
  sdk: ^3.11.5
''';

    test('versions identiques -> upToDate', () async {
      final svc = UpdateCheckerService(
        client: MockClient((req) async => http.Response(
              pubspecWith('2.9.0+4050'),
              200,
            )),
      );
      final r = await svc.check(currentVersion: '2.9.0+4050');
      expect(r.isUpToDate, isTrue);
      expect(r.currentVersion, '2.9.0+4050');
    });

    test('versions differentes -> updateAvailable', () async {
      final svc = UpdateCheckerService(
        client: MockClient((req) async => http.Response(
              pubspecWith('2.10.0+4060'),
              200,
            )),
      );
      final r = await svc.check(currentVersion: '2.9.0+4050');
      expect(r.hasUpdate, isTrue);
      expect(r.currentVersion, '2.9.0+4050');
      expect(r.remoteVersion, '2.10.0+4060');
    });

    test('HTTP 404 -> error', () async {
      final svc = UpdateCheckerService(
        client: MockClient((req) async => http.Response('not found', 404)),
      );
      final r = await svc.check(currentVersion: '2.9.0+4050');
      expect(r.hasError, isTrue);
      expect(r.errorMessage, contains('404'));
    });

    test('pubspec sans version -> error', () async {
      final svc = UpdateCheckerService(
        client: MockClient((req) async => http.Response('foo: bar', 200)),
      );
      final r = await svc.check(currentVersion: '2.9.0+4050');
      expect(r.hasError, isTrue);
      expect(r.errorMessage, contains('introuvable'));
    });

    test('reseau down -> error', () async {
      final svc = UpdateCheckerService(
        client: MockClient((req) async => throw Exception('connection')),
      );
      final r = await svc.check(currentVersion: '2.9.0+4050');
      expect(r.hasError, isTrue);
      expect(r.errorMessage, contains('Réseau'));
    });
  });
}
