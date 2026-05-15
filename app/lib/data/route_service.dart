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
/// Utilise par [NavigationScreen] (PoC Etape 2 + 3 du plan GPS, cf
/// `docs/plan-gps-integre.md`) pour afficher la vraie route routière
/// + lire des instructions vocales ("Tournez a droite dans 200m").
/// L'app retombe sur la ligne droite si l'API echoue.
class RouteService {
  RouteService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  /// Recupere la route routière + les instructions textuelles entre
  /// [from] et [to] via l'API ORS Directions GeoJSON. Retourne null
  /// si l'API ne repond pas ou retourne une erreur (timeout, quota,
  /// pas d'internet, mauvaise cle).
  ///
  /// [profil] : 'driving-car' (defaut) ou 'driving-hgv' selon le type
  /// de vehicule. [eviterPeages] : avoid_features tollways.
  ///
  /// Les instructions sont demandees en francais (`language: fr`).
  /// Best-effort : timeout 15s, swallow toute erreur HTTP/JSON.
  Future<RouteData?> fetchRoute({
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
      // Demande la langue francaise pour les instructions textuelles
      // ("Tournez a droite sur Avenue Foch" au lieu de l'anglais).
      'language': 'fr',
      // Demande aussi les instructions par etape (active par defaut
      // mais on le force pour clarte).
      'instructions': true,
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
      final feature = features.first;
      if (feature is! Map<String, dynamic>) return null;

      // Geometry : liste de coords [lng, lat] -> liste de LatLng.
      // On skip defensivement les coords mal formees (null, string,
      // tuple < 2) plutot que crasher.
      final geom = (feature['geometry'] as Map?)?.cast<String, dynamic>();
      final coords = geom?['coordinates'];
      if (coords is! List) return null;
      final polyline = <LatLng>[];
      for (final c in coords) {
        if (c is! List || c.length < 2) continue;
        final lng = (c[0] as num?)?.toDouble();
        final lat = (c[1] as num?)?.toDouble();
        if (lng == null || lat == null) continue;
        polyline.add(LatLng(lat, lng));
      }
      if (polyline.length < 2) return null;

      // Steps : structure ORS = properties.segments[0].steps[]
      // Chaque step a : distance, duration, instruction, name, type,
      // way_points (indices dans geometry.coordinates).
      final props = (feature['properties'] as Map?)?.cast<String, dynamic>();
      final segments = props?['segments'];
      final steps = <RouteStep>[];
      if (segments is List && segments.isNotEmpty) {
        final segment = segments.first;
        if (segment is! Map<String, dynamic>) {
          return RouteData(polyline: polyline, steps: steps);
        }
        final rawSteps = segment['steps'];
        if (rawSteps is List) {
          for (final s in rawSteps) {
            if (s is! Map) continue;
            final wp = s['way_points'];
            if (wp is! List || wp.length < 2) continue;
            final endIdxRaw = (wp[1] as num?)?.toInt();
            if (endIdxRaw == null) continue;
            final endIdx = endIdxRaw;
            // Coord du POINT DE FIN du step = c'est la le pivot ou
            // l'utilisateur doit manoeuvrer. ORS exprime un step comme
            // "de point A a point B", l'instruction concerne ce qui
            // se passe a la fin (le tournant).
            if (endIdx < 0 || endIdx >= polyline.length) continue;
            steps.add(RouteStep(
              instruction: (s['instruction'] as String?) ?? '',
              distance: (s['distance'] as num?)?.toDouble() ?? 0,
              duration: (s['duration'] as num?)?.toDouble() ?? 0,
              type: (s['type'] as num?)?.toInt() ?? 0,
              pivot: polyline[endIdx],
            ));
          }
        }
      }

      return RouteData(polyline: polyline, steps: steps);
    } catch (_) {
      return null;
    }
  }
}

/// Resultat de [RouteService.fetchRoute] : polyline routière (qui
/// suit les rues) + liste d'instructions textuelles.
class RouteData {
  const RouteData({required this.polyline, required this.steps});

  /// La polyline GeoJSON convertie en LatLng. Affichee directement
  /// dans le `PolylineLayer` du `FlutterMap`.
  final List<LatLng> polyline;

  /// Liste ordonnee des instructions de navigation, avec leur point
  /// pivot (lieu de la manoeuvre). Peut etre vide si l'API n'a pas
  /// renvoye de steps (cas rare, generalement quand from == to).
  final List<RouteStep> steps;
}

/// Une instruction de navigation : "Tournez a droite sur Avenue Foch"
/// avec le point GPS ou la manoeuvre a lieu. Sert au TTS qui annonce
/// l'instruction quand l'utilisateur arrive a [pivot] (seuil 100m).
class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.type,
    required this.pivot,
  });

  /// Phrase d'instruction prete a TTS, en francais. Ex: "Tournez a
  /// droite sur Avenue de la Republique". Vide si ORS n'a pas pu
  /// generer un texte.
  final String instruction;

  /// Distance du segment en metres.
  final double distance;

  /// Duree du segment en secondes.
  final double duration;

  /// Type de manoeuvre ORS :
  /// - 0 : tournez a gauche
  /// - 1 : tournez a droite
  /// - 2 : demi-tour
  /// - 3 : legere droite
  /// - 4 : legere gauche
  /// - 5 : forte droite
  /// - 6 : continuer tout droit
  /// - 7 : rond-point
  /// - 8 : sortie de rond-point
  /// - 10 : arrivee
  /// - 11 : depart
  /// - 12 : keep left
  /// - 13 : keep right
  final int type;

  /// Coordonnees GPS du point de la manoeuvre. Le TTS declenche quand
  /// la position courante est a moins de 100m de ce point (et pas
  /// encore annonce).
  final LatLng pivot;
}
