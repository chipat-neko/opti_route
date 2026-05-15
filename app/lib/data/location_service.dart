import 'package:geolocator/geolocator.dart';

/// Encapsule la gestion des permissions et le stream de position GPS.
/// Sert au mode 'tournee en cours' pour afficher la distance temps
/// reel jusqu'au prochain arret.
abstract class LocationService {
  /// Demande la permission de localisation a l'utilisateur si elle n'a
  /// pas encore ete accordee. Retourne `true` si on a au moins une
  /// permission utilisable (whileInUse ou always).
  ///
  /// Lance [LocationPermissionDenied] si l'utilisateur a refuse
  /// definitivement (`deniedForever`) ou si la localisation systeme
  /// est desactivee (mode avion / GPS off).
  static Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationPermissionDenied(
        'Localisation desactivee. Active le GPS dans les reglages '
        'Android pour utiliser le mode tournee en cours.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDenied(
        'Permission de localisation refusee. Ouvre les reglages Android '
        '> Apps > opti_route > Permissions pour l\'activer.',
      );
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Stream de positions, mis a jour des que le telephone se deplace
  /// d'au moins [distanceFilterMeters] metres. 25m est un compromis
  /// raisonnable pour un livreur en voiture (precis sans bouffer la
  /// batterie).
  static Stream<Position> positionStream({
    int distanceFilterMeters = 25,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// Position courante one-shot (utile a l'ouverture de l'ecran avant
  /// que le stream n'ait emis sa 1ere valeur).
  ///
  /// Geolocator.getCurrentPosition n'a PAS de timeout par defaut --
  /// si le GPS hardware ne repond pas (zone intérieure, mode avion
  /// silencieux), l'appel peut bloquer indefiniment. On force donc un
  /// timeout cote Dart : meilleur d'echouer apres [timeout] que de
  /// laisser l'UI sur un loader infini.
  static Future<Position> currentPosition({
    Duration timeout = const Duration(seconds: 10),
  }) {
    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: timeout,
      ),
    ).timeout(timeout);
  }

  /// Distance vol d'oiseau (en metres) entre deux points lat/lng.
  /// Ce n'est pas la distance routiere mais c'est suffisant pour un
  /// affichage 'restant' approximatif sans appel API.
  static double distanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }
}

class LocationPermissionDenied implements Exception {
  const LocationPermissionDenied(this.message);
  final String message;

  @override
  String toString() => 'LocationPermissionDenied: $message';
}
