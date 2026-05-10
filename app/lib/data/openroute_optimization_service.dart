import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'database.dart';
import 'optimization_service.dart';

/// Implementation [OptimizationService] basee sur OpenRouteService
/// (qui utilise VROOM en backend).
///
/// Plan free ORS : 500 optimisations/jour, sans carte de credit.
/// Inscription : https://openrouteservice.org/dev/#/signup
///
/// Endpoint : POST https://api.openrouteservice.org/optimization
/// Header `Authorization: <api_key>`.
class OpenRouteOptimizationService implements OptimizationService {
  OpenRouteOptimizationService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static final _endpoint =
      Uri.parse('https://api.openrouteservice.org/optimization');

  /// Endpoint Directions pour calculer la distance/duree exactes d'une
  /// sequence de waypoints. Utilise apres VROOM pour avoir le total
  /// reel sur toute la tournee (firsts + flexibles + lasts + retour).
  static final _directionsEndpoint =
      Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car');

  final String apiKey;
  final http.Client _client;

  @override
  Future<OptimizationResult> optimize({
    required Tournee tournee,
    required List<Stop> stops,
  }) async {
    final geocoded = stops
        .where((s) => s.lat != null && s.lng != null)
        .toList(growable: false);
    if (geocoded.isEmpty) {
      throw const OptimizationException(
        'Aucun arret avec coordonnees a optimiser',
      );
    }

    // 1. Separer en 3 groupes selon la priorite. Les firsts et lasts
    //    sont tries selon `ordrePriorite` (choisi par l'utilisateur via
    //    le dialog OrdrePrioriteDialog). VROOM ne sait pas faire ce
    //    tri lui-meme : son champ `priority` est un score de selection,
    //    pas un ordre absolu dans la route.
    final firsts = geocoded
        .where((s) => s.priorite == 'obligatoire_premier')
        .toList()
      ..sort(_byOrdrePriorite);
    final lasts = geocoded
        .where((s) => s.priorite == 'obligatoire_dernier')
        .toList()
      ..sort(_byOrdrePriorite);
    final flexibles = geocoded
        .where((s) =>
            s.priorite != 'obligatoire_premier' &&
            s.priorite != 'obligatoire_dernier')
        .toList(growable: false);

    // 2. Cas degeneres : tous les arrets sont en ordre fixe (firsts +
    //    lasts uniquement). On saute VROOM mais on appelle quand meme
    //    Directions pour avoir un total realiste.
    if (flexibles.isEmpty) {
      final orderedIds = <int>[
        for (final s in firsts) s.id,
        for (final s in lasts) s.id,
      ];
      final orderedStops = [...firsts, ...lasts];
      final totals = await _computeTotals(tournee, orderedStops);
      return OptimizationResult(
        orderedStopIds: orderedIds,
        totalDistanceMeters: totals.distance,
        totalDurationSeconds: totals.duration,
      );
    }

    // 3. Point de depart de la portion VROOM = position du dernier
    //    "first" si on en a, sinon depot. Idem pour le point de fin.
    final vroomStart = firsts.isNotEmpty
        ? [firsts.last.lng!, firsts.last.lat!]
        : [tournee.pointDepartLng, tournee.pointDepartLat];
    final vroomEnd = lasts.isNotEmpty
        ? [lasts.first.lng!, lasts.first.lat!]
        : [tournee.pointDepartLng, tournee.pointDepartLat];

    final payload = {
      'jobs': [
        for (final s in flexibles)
          {
            'id': s.id,
            'service': s.dureeArretMin * 60,
            'location': [s.lng, s.lat],
            'priority': _mapPriority(s.priorite),
            if (s.fenetreDebut != null || s.fenetreFin != null)
              'time_windows': [_toTimeWindow(s.fenetreDebut, s.fenetreFin)],
          }
      ],
      'vehicles': [
        {
          'id': 1,
          'profile': 'driving-car',
          'start': vroomStart,
          'end': vroomEnd,
        }
      ],
    };

    final response = await _client.post(
      _endpoint,
      headers: {
        'Authorization': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const OptimizationException(
        'Cle ORS invalide ou quota du jour atteint (500/jour). '
        'Verifie sur openrouteservice.org/dev/#/home.',
      );
    }
    if (response.statusCode != 200) {
      throw OptimizationException(
        'Reponse ORS ${response.statusCode} : '
        '${_truncate(response.body, 200)}',
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw const OptimizationException('Reponse JSON inattendue');
    }
    if (raw['code'] != 0) {
      throw OptimizationException(
        'ORS code=${raw['code']} : ${raw['error'] ?? 'erreur inconnue'}',
      );
    }

    final routes = raw['routes'];
    if (routes is! List || routes.isEmpty) {
      throw const OptimizationException('Aucune route renvoyee par ORS');
    }
    final route = routes.first as Map<String, dynamic>;

    final steps = (route['steps'] as List?) ?? const [];
    final flexiblesOrdered = <int>[];
    for (final step in steps) {
      if (step is Map && step['type'] == 'job') {
        final jobId = step['job'];
        if (jobId is int) flexiblesOrdered.add(jobId);
      }
    }

    if (flexiblesOrdered.length != flexibles.length) {
      throw OptimizationException(
        'Solveur n\'a pu placer que ${flexiblesOrdered.length}/'
        '${flexibles.length} arrets flexibles. '
        'Verifie les fenetres horaires ou les priorites.',
      );
    }

    // 4. Concatenation finale : firsts (ordre Noah) + flexibles (ordre
    //    VROOM) + lasts (ordre Noah).
    final orderedIds = <int>[
      for (final s in firsts) s.id,
      ...flexiblesOrdered,
      for (final s in lasts) s.id,
    ];

    // 5. Calcul du total exact sur l'ordre final complet (depot ->
    //    firsts -> flexibles -> lasts -> depot) via /directions. La
    //    reponse VROOM ne couvre que le segment vroomStart -> vroomEnd.
    final orderedStops = [
      ...firsts,
      for (final id in flexiblesOrdered)
        flexibles.firstWhere((s) => s.id == id),
      ...lasts,
    ];
    final totals = await _computeTotals(tournee, orderedStops);

    return OptimizationResult(
      orderedStopIds: orderedIds,
      totalDistanceMeters: totals.distance,
      totalDurationSeconds: totals.duration,
    );
  }

  /// Calcule la distance et la duree totales (en metres et secondes)
  /// pour la sequence depot -> stops[0] -> ... -> stops[N-1] -> depot.
  /// Utilise l'endpoint Directions d'OpenRouteService.
  ///
  /// En cas d'echec (reseau, quota, etc.), on tombe sur un fallback
  /// approximatif a vol d'oiseau pour ne pas casser l'optimisation
  /// (l'utilisateur verra un total approximatif plutot que rien).
  Future<({int distance, int duration})> _computeTotals(
    Tournee tournee,
    List<Stop> orderedStops,
  ) async {
    if (orderedStops.isEmpty) return (distance: 0, duration: 0);

    final coords = <List<double>>[
      [tournee.pointDepartLng, tournee.pointDepartLat],
      for (final s in orderedStops) [s.lng!, s.lat!],
      [tournee.pointDepartLng, tournee.pointDepartLat],
    ];

    try {
      final response = await _client.post(
        _directionsEndpoint,
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'coordinates': coords}),
      );
      if (response.statusCode != 200) {
        return _haversineFallback(coords);
      }
      final raw = jsonDecode(response.body);
      if (raw is! Map<String, dynamic>) return _haversineFallback(coords);
      final routes = raw['routes'];
      if (routes is! List || routes.isEmpty) {
        return _haversineFallback(coords);
      }
      final summary =
          ((routes.first as Map)['summary'] as Map?)?.cast<String, dynamic>();
      final distance = (summary?['distance'] as num?)?.toInt() ?? 0;
      final duration = (summary?['duration'] as num?)?.toInt() ?? 0;
      return (distance: distance, duration: duration);
    } catch (_) {
      return _haversineFallback(coords);
    }
  }

  /// Fallback : somme des distances haversine (vol d'oiseau) entre
  /// waypoints, et duree estimee a 50 km/h moyenne (urbain + extra-urbain).
  ({int distance, int duration}) _haversineFallback(
    List<List<double>> coords,
  ) {
    var total = 0.0;
    for (var i = 1; i < coords.length; i++) {
      total += _haversineMeters(
        coords[i - 1][1], coords[i - 1][0],
        coords[i][1], coords[i][0],
      );
    }
    final dist = total.round();
    final dur = (total / (50000 / 3600)).round();
    return (distance: dist, duration: dur);
  }

  static double _haversineMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (math.sin(dLat / 2)) * (math.sin(dLat / 2)) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double d) => d * 3.141592653589793 / 180.0;

  /// Tri par `ordrePriorite` croissant. Null tombe a la fin (cas
  /// migration : un arret deja marque "EN 1ER" avant la v6 n'a pas
  /// d'ordrePriorite -> on le met en queue de groupe).
  static int _byOrdrePriorite(Stop a, Stop b) {
    final ao = a.ordrePriorite;
    final bo = b.ordrePriorite;
    if (ao == null && bo == null) return a.id.compareTo(b.id);
    if (ao == null) return 1;
    if (bo == null) return -1;
    return ao.compareTo(bo);
  }

  int _mapPriority(String priorite) {
    return switch (priorite) {
      // Note : ce score n'influence PLUS l'ordre dans la route (les
      // firsts/lasts sont gerees hors VROOM). Il sert uniquement a ce
      // que VROOM, en cas d'overflow horaire, abandonne en priorite
      // les `eviter_si_possible` plutot que les flexibles standards.
      'eviter_si_possible' => 10,
      _ => 50,
    };
  }

  List<int> _toTimeWindow(String? debut, String? fin) {
    return [
      _parseHHmmToSeconds(debut) ?? 0,
      _parseHHmmToSeconds(fin) ?? 86400 - 1,
    ];
  }

  int? _parseHHmmToSeconds(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 3600 + m * 60;
  }

  String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}...';

  @override
  void close() => _client.close();
}
