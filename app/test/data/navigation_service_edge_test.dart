import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/navigation_service.dart';

// Complete navigation_service_test : tryLaunch via mock MethodChannel
// url_launcher, edge precision lat/lng, parametres URI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationService.googleMapsUri — edges', () {
    test('domaine + path + queryParameters propres', () {
      final uri = NavigationService.googleMapsUri(lat: 48.5, lng: 1.5);
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '48.5,1.5');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('lat/lng a precision elevee : preservee dans la string', () {
      final uri = NavigationService.googleMapsUri(
        lat: 48.4220456,
        lng: 1.4889012,
      );
      expect(uri.queryParameters['destination'],
          contains('48.4220456'));
      expect(uri.queryParameters['destination'],
          contains('1.4889012'));
    });

    test('lat negative (sud) : signe preserve', () {
      final uri = NavigationService.googleMapsUri(
        lat: -33.86,
        lng: 151.21,
      );
      expect(uri.queryParameters['destination'], '-33.86,151.21');
    });

    test('lng negative (ouest) : signe preserve', () {
      final uri = NavigationService.googleMapsUri(
        lat: 40.7128,
        lng: -74.006,
      );
      expect(uri.queryParameters['destination'], '40.7128,-74.006');
    });

    test('latitude 0 et longitude 0 (golfe Guinee) : "0.0,0.0"', () {
      final uri = NavigationService.googleMapsUri(lat: 0, lng: 0);
      expect(uri.queryParameters['destination'], '0.0,0.0');
    });
  });

  group('NavigationService.wazeUri — edges', () {
    test('hostpath + navigate=yes', () {
      final uri = NavigationService.wazeUri(lat: 48.5, lng: 1.5);
      expect(uri.host, 'waze.com');
      expect(uri.path, '/ul');
      expect(uri.queryParameters['ll'], '48.5,1.5');
      expect(uri.queryParameters['navigate'], 'yes');
    });

    test('lat/lng negatives Waze : preservees', () {
      final uri = NavigationService.wazeUri(lat: -1.5, lng: -2.5);
      expect(uri.queryParameters['ll'], '-1.5,-2.5');
    });
  });

  group('NavigationService.tryLaunch — mock url_launcher', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');

    setUp(() {
      // setup vide par defaut, chaque test installe son handler
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('handler renvoie true : tryLaunch -> true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'canLaunch') return true;
        if (call.method == 'launch') return true;
        return null;
      });
      final ok =
          await NavigationService.tryLaunch(Uri.parse('https://example.com'));
      expect(ok, isTrue);
    });

    test('handler throw : tryLaunch avale -> false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERR', message: 'no app');
      });
      final ok = await NavigationService.tryLaunch(Uri.parse('sms:+33600000000'));
      expect(ok, isFalse);
    });

    test('schema sms : tryLaunch transmet l\'URI', () async {
      String? capturedUrl;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'canLaunch' || call.method == 'launch') {
          final args = (call.arguments as Map?)?.cast<dynamic, dynamic>();
          capturedUrl = args?['url'] as String?;
          return true;
        }
        return null;
      });
      await NavigationService.tryLaunch(Uri.parse('sms:+33600000000'));
      expect(capturedUrl, 'sms:+33600000000');
    });
  });
}
