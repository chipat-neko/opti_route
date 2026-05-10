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

    // 2. Cas degeneres : pas besoin d'appeler VROOM si tous les arrets
    //    sont en ordre fixe (firsts + lasts uniquement).
    if (flexibles.isEmpty) {
      return OptimizationResult(
        orderedStopIds: [
          for (final s in firsts) s.id,
          for (final s in lasts) s.id,
        ],
        // Pas d'API call -> pas de distance/duree calculees ici. Le
        // caller verra 0 et affichera "—" comme avant.
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
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

    final summary = (raw['summary'] as Map?)?.cast<String, dynamic>();
    final duration = (route['duration'] as num?)?.toInt() ??
        (summary?['duration'] as num?)?.toInt() ??
        0;
    final distance = (route['distance'] as num?)?.toInt() ??
        (summary?['distance'] as num?)?.toInt() ??
        0;

    // Note : la distance/duree retournees ici concernent uniquement le
    // segment VROOM (entre vroomStart et vroomEnd). Les segments
    // firsts/lasts ne sont pas factures dans le total. C'est une
    // approximation volontaire pour eviter un 2e appel ORS.
    return OptimizationResult(
      orderedStopIds: orderedIds,
      totalDistanceMeters: distance,
      totalDurationSeconds: duration,
    );
  }

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
