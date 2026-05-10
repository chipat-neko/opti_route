import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/navigation_service.dart';

void main() {
  group('NavigationService - construction des URIs', () {
    test('googleMapsUri : format dir API avec destination + travelmode', () {
      final uri = NavigationService.googleMapsUri(lat: 48.4307, lng: 1.4892);
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '48.4307,1.4892');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('wazeUri : format ul avec ll + navigate=yes', () {
      final uri = NavigationService.wazeUri(lat: 48.4307, lng: 1.4892);
      expect(uri.host, 'waze.com');
      expect(uri.path, '/ul');
      expect(uri.queryParameters['ll'], '48.4307,1.4892');
      expect(uri.queryParameters['navigate'], 'yes');
    });

    test('coordonnees negatives : signes preserves', () {
      final maps =
          NavigationService.googleMapsUri(lat: -33.8688, lng: -151.2093);
      expect(maps.queryParameters['destination'], '-33.8688,-151.2093');
      final waze = NavigationService.wazeUri(lat: -33.8688, lng: -151.2093);
      expect(waze.queryParameters['ll'], '-33.8688,-151.2093');
    });
  });
}
