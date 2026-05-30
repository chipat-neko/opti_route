import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// ════════════════════════════════════════════════════════════════
/// Client OSRM (Open Source Routing Machine) pour distance + duree
/// routieres exactes, SANS toucher au quota ORS (VROOM).
/// ════════════════════════════════════════════════════════════════
///
/// Endpoint : https://router.project-osrm.org/route/v1/driving/...
/// - Demo publique maintenue par le projet OSRM
/// - GRATUIT, sans cle API, sans inscription
/// - Usage modere demande (debounce 500ms cote app)
/// - Routes sur reseau OSM monde entier
///
/// On demande `overview=false` car on ne veut que les totaux distance
/// + duree, pas la geometry decodee.
class OsrmRouteService {
  OsrmRouteService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Recupere distance (metres) + duree (secondes) routieres pour un
  /// parcours dans l'ordre donne [waypoints]. Retourne `null` si
  /// l'API ne repond pas, < 2 points, ou erreur reseau.
  ///
  /// Best-effort : timeout 8s, swallow exceptions, le caller doit
  /// gerer un null (fallback haversine ou affichage " - ").
  Future<OsrmRouteResult?> fetchRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    try {
      // Format OSRM : lng,lat;lng,lat;... (ATTENTION lng avant lat)
      final coords = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final uri = Uri.parse('$_baseUrl/$coords').replace(
        queryParameters: {
          'overview': 'false',
          'alternatives': 'false',
          'steps': 'false',
        },
      );
      final resp = await _client
          .get(uri, headers: {'User-Agent': 'opti_route/0.1'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final raw = jsonDecode(resp.body);
      if (raw is! Map<String, dynamic>) return null;
      final routes = raw['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route = routes.first;
      if (route is! Map<String, dynamic>) return null;
      final distance = (route['distance'] as num?)?.toDouble();
      final duration = (route['duration'] as num?)?.toDouble();
      if (distance == null || duration == null) return null;
      return OsrmRouteResult(
        meters: distance.round(),
        seconds: duration.round(),
      );
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}

/// Resultat de [OsrmRouteService.fetchRoute] : distance routiere
/// exacte (m) et duree (s) basees sur reseau OSM.
class OsrmRouteResult {
  const OsrmRouteResult({required this.meters, required this.seconds});
  final int meters;
  final int seconds;
}
