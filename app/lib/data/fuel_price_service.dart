import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Service de recuperation du prix moyen du carburant en temps reel
/// depuis l'API publique data.gouv.fr (sans cle, sans inscription).
///
/// Source : `prix-des-carburants-en-france-flux-instantane-v2`. Donnees
/// mises a jour toutes les 10 minutes par le ministere. Couverture
/// nationale sauf zones tres isolees.
///
/// Carte Trello #39. Sert a pre-remplir le champ "Prix carburant L"
/// dans Parametres > Carburant (au lieu de demander a Noah de saisir
/// manuellement et de mettre a jour chaque mois).
class FuelPriceService {
  FuelPriceService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  /// Endpoint API publique. Cle obligatoire : `code_departement` (string
  /// 2 ou 3 chiffres, ex "28" pour Eure-et-Loir, "974" Reunion). Limit
  /// 100 stations par appel (le departement le plus dense en France a
  /// environ 200 stations actives, mais 100 suffit pour une moyenne
  /// representative).
  static const String _baseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets'
      '/prix-des-carburants-en-france-flux-instantane-v2/records';

  /// Recupere le prix moyen du Diesel (Gazole) dans un departement
  /// francais donne. Retourne null si reseau down, API en erreur, ou
  /// aucune station avec prix renseigne.
  ///
  /// Le calcul est une **moyenne arithmetique** des prix gazole non-null
  /// des stations actives du departement. Pas pondere par volume car
  /// donnee non dispo cote API.
  ///
  /// [departement] : code INSEE du departement (ex "28" pour
  /// Eure-et-Loir). Default "28" car c'est la zone principale de
  /// l'utilisateur.
  ///
  /// [timeout] : abandon apres 8 secondes (l'API gouv.fr est en
  /// general < 1s, mais bridee parfois aux heures de pointe).
  Future<FuelPriceResult?> getAverageDieselPrice({
    String departement = '28',
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      // `where=code_departement="28"` : filtre cote serveur, on rapatrie
      // pas les 11 000 stations de France.
      // `select=gazole_prix,gazole_maj,cp,ville` : on ne demande que les
      // champs dont on a besoin (reduit la bande passante x10).
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'where': 'code_departement="$departement"',
        'select': 'gazole_prix,gazole_maj,cp,ville',
        'limit': '100',
      });
      final resp = await _http.get(uri).timeout(timeout);
      if (resp.statusCode != 200) return null;
      final body = json.decode(resp.body) as Map<String, dynamic>;
      final results = (body['results'] as List?) ?? const [];
      if (results.isEmpty) return null;

      // Moyenne des prix gazole non null. On ignore les stations qui
      // n'ont pas de gazole (electriques pures, GPL only, etc.).
      final prices = <double>[];
      DateTime? lastUpdate;
      for (final r in results) {
        final p = (r as Map<String, dynamic>)['gazole_prix'];
        if (p == null) continue;
        final price = (p as num).toDouble();
        // Filtre defensif : un prix < 0.5 ou > 5 EUR est probablement
        // une erreur de saisie, on l'exclut.
        if (price < 0.5 || price > 5.0) continue;
        prices.add(price);
        // Garde la date de maj la plus recente parmi les stations.
        final maj = r['gazole_maj'];
        if (maj is String) {
          final d = DateTime.tryParse(maj);
          if (d != null && (lastUpdate == null || d.isAfter(lastUpdate))) {
            lastUpdate = d;
          }
        }
      }
      if (prices.isEmpty) return null;
      final avg = prices.reduce((a, b) => a + b) / prices.length;
      return FuelPriceResult(
        averageEurPerLiter: avg,
        sampleSize: prices.length,
        departement: departement,
        lastUpdate: lastUpdate ?? DateTime.now(),
      );
    } catch (_) {
      // Tout echec (timeout, JSON malforme, etc.) => null. L'UI doit
      // gerer ce cas en gardant la valeur saisie manuellement.
      return null;
    }
  }

  /// Recupere les N stations Diesel les plus proches de [lat]/[lng]
  /// dans un rayon de [maxKm] km. Tri par distance haversine croissante.
  /// Carte Trello #39 V4 : permet de localiser les stations pas cheres
  /// pendant les tournees.
  ///
  /// L'API data.gouv.fr ne supporte pas le filtre geo natif sans un
  /// where SQL personnalise. On rapatrie un batch (limit 500) au-dessus
  /// d'un radius approximatif (~0.1 deg = ~11 km), puis on filtre + trie
  /// cote app pour avoir une distance precise.
  ///
  /// Retourne une liste vide si reseau down, API erreur, ou aucune
  /// station dans le rayon. **Pas de levee d'exception** : best-effort.
  Future<List<FuelStation>> findNearbyDieselStations({
    required double lat,
    required double lng,
    int limit = 5,
    double maxKm = 10,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      // Approx 1 deg de latitude = ~111 km. On prend une marge x1.5 pour
      // ne pas manquer les stations en bordure.
      final degRadius = (maxKm / 111) * 1.5;
      final latMin = lat - degRadius;
      final latMax = lat + degRadius;
      // La longitude varie avec la latitude. On compense par cos(lat).
      final lngRadius = degRadius / math.cos(lat * math.pi / 180);
      final lngMin = lng - lngRadius;
      final lngMax = lng + lngRadius;

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'where':
            'geom is not null and gazole_prix is not null '
            'and latitude > $latMin and latitude < $latMax '
            'and longitude > $lngMin and longitude < $lngMax',
        'select':
            'id,gazole_prix,gazole_maj,latitude,longitude,'
            'cp,ville,adresse,nom',
        'limit': '500',
      });
      final resp = await _http.get(uri).timeout(timeout);
      if (resp.statusCode != 200) return const [];
      final body = json.decode(resp.body) as Map<String, dynamic>;
      final results = (body['results'] as List?) ?? const [];

      final stations = <FuelStation>[];
      for (final r in results) {
        final m = r as Map<String, dynamic>;
        final p = m['gazole_prix'];
        final lt = m['latitude'];
        final lg = m['longitude'];
        if (p == null || lt == null || lg == null) continue;
        final price = (p as num).toDouble();
        if (price < 0.5 || price > 5.0) continue;
        final stLat = (lt as num).toDouble();
        final stLng = (lg as num).toDouble();
        final dKm = _haversineKm(lat, lng, stLat, stLng);
        if (dKm > maxKm) continue;
        stations.add(FuelStation(
          id: (m['id'] as Object?)?.toString() ?? '',
          name: (m['nom'] as String?)?.trim() ?? '',
          address: (m['adresse'] as String?)?.trim() ?? '',
          codePostal: (m['cp'] as String?)?.trim() ?? '',
          ville: (m['ville'] as String?)?.trim() ?? '',
          lat: stLat,
          lng: stLng,
          dieselPriceEur: price,
          distanceKm: dKm,
          lastUpdate: _parseDate(m['gazole_maj']),
        ));
      }
      stations.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return stations.take(limit).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  void dispose() => _http.close();

  /// Distance haversine en km entre 2 points GPS.
  static double _haversineKm(
    double lat1, double lng1, double lat2, double lng2,
  ) {
    const r = 6371.0; // rayon terre en km
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final lat1r = lat1 * math.pi / 180;
    final lat2r = lat2 * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1r) * math.cos(lat2r) *
            math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String) {
      final d = DateTime.tryParse(raw);
      if (d != null) return d;
    }
    return DateTime.now();
  }
}

/// Une station Diesel localisee, retournee par
/// [FuelPriceService.findNearbyDieselStations].
class FuelStation {
  const FuelStation({
    required this.id,
    required this.name,
    required this.address,
    required this.codePostal,
    required this.ville,
    required this.lat,
    required this.lng,
    required this.dieselPriceEur,
    required this.distanceKm,
    required this.lastUpdate,
  });

  final String id;
  /// Nom commercial (TOTAL, CARREFOUR...). Souvent vide dans l'API.
  final String name;
  final String address;
  final String codePostal;
  final String ville;
  final double lat;
  final double lng;
  final double dieselPriceEur;
  /// Distance haversine en km depuis la position user.
  final double distanceKm;
  final DateTime lastUpdate;

  /// Label compose : "TOTAL · 12 rue X" ou juste l'adresse si pas de nom.
  String get displayLabel {
    if (name.isEmpty) return address.isEmpty ? ville : address;
    return address.isEmpty ? name : '$name · $address';
  }
}

/// Resultat d'un appel reussi a l'API prix carburants.
class FuelPriceResult {
  const FuelPriceResult({
    required this.averageEurPerLiter,
    required this.sampleSize,
    required this.departement,
    required this.lastUpdate,
  });

  /// Prix moyen en EUR par litre. Ex : 1.752.
  final double averageEurPerLiter;

  /// Nombre de stations utilisees pour calculer la moyenne. Utile
  /// pour l'UI : si < 5, on affiche un disclaimer "echantillon faible".
  final int sampleSize;

  /// Code INSEE du departement requis (ex "28").
  final String departement;

  /// Timestamp de la station la plus recemment mise a jour. Permet
  /// d'afficher "actualise il y a X minutes / heures".
  final DateTime lastUpdate;
}
