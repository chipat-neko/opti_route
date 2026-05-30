import 'dart:convert';

import 'database.dart';

/// Serialise une tournee en JSON minimal pour partage QR/lien
/// lecture seule a un remplacant. Carte #308 : permet de passer le
/// relais un jour de conge sans activer le mode equipe cloud.
///
/// Format compact pour rester sous la limite des QR (alphanumeric 4296
/// chars max niveau Low erreur correction, en pratique mieux 2000).
/// Pas de donnees sensibles : on omet notes carnet, photos preuves,
/// montants COD, telephones.
class TourneeSharePayload {
  TourneeSharePayload._();

  static String compose({
    required Tournee tournee,
    required List<Stop> orderedStops,
  }) {
    final stopsJson = [
      for (final s in orderedStops)
        {
          'a': s.adresseBrute,
          if ((s.nomClient ?? '').isNotEmpty) 'n': s.nomClient,
          if (s.lat != null && s.lng != null) ...{
            'la': s.lat,
            'lo': s.lng,
          },
          if (s.nbColis != 1) 'c': s.nbColis,
          if ((s.fenetreDebut ?? '').isNotEmpty) 'fd': s.fenetreDebut,
          if ((s.fenetreFin ?? '').isNotEmpty) 'ff': s.fenetreFin,
        },
    ];
    final payload = {
      'v': 1,
      'n': tournee.nom,
      'd': tournee.date.toIso8601String().substring(0, 10),
      'depot': [tournee.pointDepartLat, tournee.pointDepartLng],
      'stops': stopsJson,
    };
    return jsonEncode(payload);
  }

  /// Reverse : parse un payload compose. Retourne null si format
  /// invalide / version inconnue.
  static SharedTournee? parse(String raw) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      final v = j['v'];
      if (v != 1) return null;
      final stops = (j['stops'] as List?) ?? const [];
      return SharedTournee(
        nom: (j['n'] as String?) ?? 'Tournee partagee',
        date: DateTime.parse(j['d'] as String),
        depotLat: ((j['depot'] as List?)?[0] as num?)?.toDouble() ?? 0,
        depotLng: ((j['depot'] as List?)?[1] as num?)?.toDouble() ?? 0,
        stops: [
          for (final s in stops)
            if (s is Map)
              SharedStop(
                adresse: (s['a'] as String?) ?? '',
                nomClient: s['n'] as String?,
                lat: (s['la'] as num?)?.toDouble(),
                lng: (s['lo'] as num?)?.toDouble(),
                nbColis: (s['c'] as int?) ?? 1,
              ),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}

class SharedTournee {
  const SharedTournee({
    required this.nom,
    required this.date,
    required this.depotLat,
    required this.depotLng,
    required this.stops,
  });
  final String nom;
  final DateTime date;
  final double depotLat;
  final double depotLng;
  final List<SharedStop> stops;
}

class SharedStop {
  const SharedStop({
    required this.adresse,
    this.nomClient,
    this.lat,
    this.lng,
    this.nbColis = 1,
  });
  final String adresse;
  final String? nomClient;
  final double? lat;
  final double? lng;
  final int nbColis;
}
