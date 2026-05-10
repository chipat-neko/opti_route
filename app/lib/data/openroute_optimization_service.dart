import 'dart:convert';

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

    final payload = {
      'jobs': [
        for (final s in geocoded)
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
          'start': [tournee.pointDepartLng, tournee.pointDepartLat],
          'end': [tournee.pointDepartLng, tournee.pointDepartLat],
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
    final orderedIds = <int>[];
    for (final step in steps) {
      if (step is Map && step['type'] == 'job') {
        final jobId = step['job'];
        if (jobId is int) orderedIds.add(jobId);
      }
    }

    if (orderedIds.length != geocoded.length) {
      throw OptimizationException(
        'Solveur n\'a pu placer que ${orderedIds.length}/${geocoded.length} arrets. '
        'Verifie les fenetres horaires ou les priorites.',
      );
    }

    final summary = (raw['summary'] as Map?)?.cast<String, dynamic>();
    final duration = (route['duration'] as num?)?.toInt() ??
        (summary?['duration'] as num?)?.toInt() ??
        0;
    final distance = (route['distance'] as num?)?.toInt() ??
        (summary?['distance'] as num?)?.toInt() ??
        0;

    return OptimizationResult(
      orderedStopIds: orderedIds,
      totalDistanceMeters: distance,
      totalDurationSeconds: duration,
    );
  }

  int _mapPriority(String priorite) {
    return switch (priorite) {
      'obligatoire_premier' => 100,
      'obligatoire_dernier' => 0,
      'eviter_si_possible' => 10,
      _ => 50, // flexible
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
