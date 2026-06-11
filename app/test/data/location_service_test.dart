import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:opti_route/data/location_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Tests du wrapper GPS (audit 2026-06-11 : service critique du mode
/// "tournee en cours", aucun filet avant).
///
/// On injecte un [GeolocatorPlatform] mocke : les statics de la facade
/// `Geolocator` deleguent a `GeolocatorPlatform.instance`, donc tout
/// le flux permissions est testable sans device.
void main() {
  late _MockGeolocatorPlatform mock;

  setUp(() {
    mock = _MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mock;
  });

  group('LocationService.ensurePermission', () {
    test('GPS systeme desactive -> LocationPermissionDenied', () async {
      mock.serviceEnabled = false;
      await expectLater(
        LocationService.ensurePermission(),
        throwsA(isA<LocationPermissionDenied>()),
      );
      // On ne doit meme pas atteindre le check de permission.
      expect(mock.checkPermissionCalls, 0);
    });

    test('permission deja accordee (whileInUse) -> true sans prompt',
        () async {
      mock.permission = LocationPermission.whileInUse;
      expect(await LocationService.ensurePermission(), isTrue);
      expect(mock.requestPermissionCalls, 0);
    });

    test('permission always -> true sans prompt', () async {
      mock.permission = LocationPermission.always;
      expect(await LocationService.ensurePermission(), isTrue);
      expect(mock.requestPermissionCalls, 0);
    });

    test('denied -> prompt -> accorde whileInUse -> true', () async {
      mock.permission = LocationPermission.denied;
      mock.permissionAfterRequest = LocationPermission.whileInUse;
      expect(await LocationService.ensurePermission(), isTrue);
      expect(mock.requestPermissionCalls, 1);
    });

    test('denied -> prompt -> refuse encore -> false (pas un throw)',
        () async {
      // Refus simple (pas deniedForever) : l'UI peut re-demander plus
      // tard, on retourne false sans exception.
      mock.permission = LocationPermission.denied;
      mock.permissionAfterRequest = LocationPermission.denied;
      expect(await LocationService.ensurePermission(), isFalse);
      expect(mock.requestPermissionCalls, 1);
    });

    test('deniedForever -> LocationPermissionDenied avec message reglages',
        () async {
      mock.permission = LocationPermission.deniedForever;
      await expectLater(
        LocationService.ensurePermission(),
        throwsA(
          isA<LocationPermissionDenied>().having(
            (e) => e.message,
            'message',
            contains('reglages Android'),
          ),
        ),
      );
    });

    test('denied -> prompt -> deniedForever -> LocationPermissionDenied',
        () async {
      mock.permission = LocationPermission.denied;
      mock.permissionAfterRequest = LocationPermission.deniedForever;
      await expectLater(
        LocationService.ensurePermission(),
        throwsA(isA<LocationPermissionDenied>()),
      );
    });
  });

  group('LocationService.distanceMeters', () {
    test('Paris -> Lyon : ~392 km vol d\'oiseau', () {
      final d = LocationService.distanceMeters(
        fromLat: 48.8566,
        fromLng: 2.3522,
        toLat: 45.7640,
        toLng: 4.8357,
      );
      expect(d, greaterThan(380000));
      expect(d, lessThan(405000));
    });

    test('meme point -> 0', () {
      final d = LocationService.distanceMeters(
        fromLat: 48.0,
        fromLng: 1.0,
        toLat: 48.0,
        toLng: 1.0,
      );
      expect(d, 0);
    });
  });

  group('LocationService.positionStream', () {
    test('transmet le distanceFilter demande a la plateforme', () {
      LocationService.positionStream(distanceFilterMeters: 10);
      expect(mock.lastLocationSettings?.distanceFilter, 10);
    });

    test('25 m par defaut (compromis batterie livreur)', () {
      LocationService.positionStream();
      expect(mock.lastLocationSettings?.distanceFilter, 25);
    });
  });
}

/// Mock minimal : `extends` (et non implements) pour heriter de
/// l'implementation Dart pure de `distanceBetween` (haversine).
class _MockGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission permissionAfterRequest = LocationPermission.denied;
  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  LocationSettings? lastLocationSettings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCalls++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls++;
    return permissionAfterRequest;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    lastLocationSettings = locationSettings;
    return const Stream<Position>.empty();
  }
}
