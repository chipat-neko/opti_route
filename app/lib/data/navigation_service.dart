import 'package:url_launcher/url_launcher.dart';

/// Service de lancement d'apps de navigation externes (Google Maps,
/// Waze) sur l'adresse d'un arret. Pour CarPlay/Android Auto, ces deux
/// apps prennent le relais automatiquement quand le telephone est
/// connecte au vehicule.
abstract class NavigationService {
  /// Construit l'URL de navigation Google Maps en mode "directions"
  /// (l'app calcule un itineraire depuis la position actuelle).
  static Uri googleMapsUri({required double lat, required double lng}) {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
      '&travelmode=driving',
    );
  }

  /// Construit l'URL de navigation Waze. `navigate=yes` lance la
  /// navigation immediatement, sans passer par l'ecran de preview.
  static Uri wazeUri({required double lat, required double lng}) {
    return Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
  }

  /// Lance Google Maps. Retourne false si aucune app n'a pu ouvrir
  /// l'URL (l'UI peut alors afficher un message).
  static Future<bool> launchGoogleMaps({
    required double lat,
    required double lng,
  }) {
    return launchUrl(
      googleMapsUri(lat: lat, lng: lng),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Lance Waze. Si Waze n'est pas installe, l'URL https://waze.com
  /// ouvre la version web par defaut, qui propose d'installer l'app.
  static Future<bool> launchWaze({
    required double lat,
    required double lng,
  }) {
    return launchUrl(
      wazeUri(lat: lat, lng: lng),
      mode: LaunchMode.externalApplication,
    );
  }
}
