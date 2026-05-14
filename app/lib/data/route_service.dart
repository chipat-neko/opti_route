import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// ════════════════════════════════════════════════════════════════
/// Service ORS Directions point-a-point.
/// ════════════════════════════════════════════════════════════════
///
/// Contrairement a [OpenRouteOptimizationService] qui optimise l'ORDRE
/// de plusieurs arrets via VROOM puis recupere la geometry de la
/// route complete via Directions, ce service-ci fait juste un appel
/// Directions entre 2 points (position courante -> destination).
///
/// Utilise par [NavigationScreen] (PoC Etape 2 du plan GPS, cf
/// `docs/plan-gps-integre.md`) pour afficher la vraie route routiere
/// au lieu d'une ligne droite. L'app retombe sur la ligne droite si
/// l'API echoue (timeout, quota depasse, pas de connexion, etc.).
///
/// **Cout en quota ORS** : 1 appel /v2/directions par push du
/// NavigationScreen. Pour une tournee de 20 stops, ca fait 20 calls /
/// jour si Noah utilise systematiquement le "Suivre dans l'app". Le
/// quota free = 500/jour, donc on a de la marge.
class RouteService {
  RouteService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  /// Recupere la geometry routiere entre [from] et [to] via l'API ORS
  /// Directions GeoJSON. Retourne une liste de [LatLng] qui forme une
  /// polyline routière (suit les rues), ou null si l'API ne repond
  /// pas ou retourne une erreur.
  ///
  /// [profil] : 'driving-car' (defaut) ou 'driving-hgv' selon le type
  /// de vehicule du livreur (camion lourd respecte les restrictions
  /// hauteur/poids/largeur OSM).
  ///
  /// Best-effort : timeout 15s, swallow toute erreur HTTP/JSON et
  /// retourne null. Le caller affichera la ligne droite en fallback.
  Future<List<LatLng>?> fetchRoute({
    required LatLng from,
    required LatLng to,
    String profil = 'driving-car',
    bool eviterPeages = false,
  }) async {
    final body = <String, dynamic>{
      'coordinates': [
        [from.longitude, from.latitude],
        [to.longitude, to.latitude],
      ],
    };
    if (eviterPeages) {
      body['options'] = {
        'avoid_features': ['tollways'],
      };
    }

    try {
      final response = await _client
          .post(
            Uri.parse(
                'https://api.openrouteservice.org/v2/directions/$profil/geojson'),
            headers: {
              'Authorization': apiKey,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) return null;
      final features = raw['features'];
      if (features is! List || features.isEmpty) return null;
      final feature = features.first as Map<String, dynamic>;
      final geom = (feature['geometry'] as Map?)?.cast<String, dynamic>();
      final coords = geom?['coordinates'];
      if (coords is! List) return null;
      return [
        for (final c in coords)
          if (c is List && c.length >= 2)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
    } catch (_) {
      return null;
    }
  }
}
