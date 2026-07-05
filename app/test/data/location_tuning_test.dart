import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:opti_route/data/location_tuning.dart';

/// Tests des profils GPS et du builder de LocationSettings
/// (feat/opti-batterie, 2026-07-04).
void main() {
  group('resolveGpsProfile', () {
    test('navigation : haute precision, 10 m, intervalle 2 s '
        '(insensible au mode eco)', () {
      const expected = GpsProfile(
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 10,
        androidInterval: Duration(seconds: 2),
      );
      expect(resolveGpsProfile(usage: GpsUsage.navigation, eco: false),
          expected);
      expect(resolveGpsProfile(usage: GpsUsage.navigation, eco: true),
          expected);
    });

    test('presence : precision moyenne, 50 m, intervalle 10 s', () {
      final p = resolveGpsProfile(usage: GpsUsage.presence, eco: false);
      expect(p.accuracy, LocationAccuracy.medium);
      expect(p.distanceFilterMeters, 50);
      expect(p.androidInterval, const Duration(seconds: 10));
    });

    test('passive hors eco : haute precision preservee, mais cadence '
        'plafonnee a 4 s (25 m)', () {
      final p = resolveGpsProfile(usage: GpsUsage.passive, eco: false);
      expect(p.accuracy, LocationAccuracy.high);
      expect(p.distanceFilterMeters, 25);
      expect(p.androidInterval, const Duration(seconds: 4));
    });

    test('passive en mode eco : precision moyenne, 100 m, intervalle 20 s',
        () {
      final p = resolveGpsProfile(usage: GpsUsage.passive, eco: true);
      expect(p.accuracy, LocationAccuracy.medium);
      expect(p.distanceFilterMeters, 100);
      expect(p.androidInterval, const Duration(seconds: 20));
    });

    test('le mode eco n\'augmente jamais la cadence ni la precision '
        'du profil passif', () {
      final normal = resolveGpsProfile(usage: GpsUsage.passive, eco: false);
      final eco = resolveGpsProfile(usage: GpsUsage.passive, eco: true);
      // Intervalle eco >= normal (moins de fixes) et filtre eco >= normal
      // (bouge plus avant d'emettre) => eco consomme moins.
      expect(eco.androidInterval >= normal.androidInterval, isTrue);
      expect(eco.distanceFilterMeters >= normal.distanceFilterMeters, isTrue);
    });
  });

  group('GpsProfile ==/hashCode', () {
    test('egalite structurelle', () {
      const a = GpsProfile(
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 10,
        androidInterval: Duration(seconds: 2),
      );
      const b = GpsProfile(
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 10,
        androidInterval: Duration(seconds: 2),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('buildLocationSettings', () {
    test('Android : AndroidSettings avec intervalDuration + FUSED', () {
      final s = buildLocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 25,
        androidInterval: const Duration(seconds: 4),
        isAndroid: true,
      );
      expect(s, isA<AndroidSettings>());
      final android = s as AndroidSettings;
      expect(android.accuracy, LocationAccuracy.high);
      expect(android.distanceFilter, 25);
      expect(android.intervalDuration, const Duration(seconds: 4));
      // false = provider FUSED (Play Services), plus econome.
      expect(android.forceLocationManager, isFalse);
    });

    test('non-Android : LocationSettings generique (pas d\'AndroidSettings)',
        () {
      final s = buildLocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilterMeters: 100,
        androidInterval: const Duration(seconds: 20),
        isAndroid: false,
      );
      expect(s, isA<LocationSettings>());
      expect(s, isNot(isA<AndroidSettings>()));
      expect(s.accuracy, LocationAccuracy.medium);
      expect(s.distanceFilter, 100);
    });

    test('le distanceFilter et l\'accuracy sont bien propages (Android)',
        () {
      final s = buildLocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilterMeters: 50,
        androidInterval: const Duration(seconds: 10),
        isAndroid: true,
      ) as AndroidSettings;
      expect(s.accuracy, LocationAccuracy.medium);
      expect(s.distanceFilter, 50);
      expect(s.intervalDuration, const Duration(seconds: 10));
    });
  });
}
