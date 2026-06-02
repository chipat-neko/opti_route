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
      // UTF-8 explicite (cf geocodeurs) : evite le mojibake des noms de
      // villes accentuees si le header charset manque.
      final decoded =
          json.decode(utf8.decode(resp.bodyBytes, allowMalformed: true));
      if (decoded is! Map) return null;
      final rawResults = decoded['results'];
      final results = rawResults is List ? rawResults : const [];
      if (results.isEmpty) return null;

      // Moyenne des prix gazole non null. On ignore les stations qui
      // n'ont pas de gazole (electriques pures, GPL only, etc.).
      final prices = <double>[];
      DateTime? lastUpdate;
      for (final r in results) {
        if (r is! Map) continue;
        // Conversion tolerante : une station au prix malforme (String,
        // null) est SKIP, elle ne fait plus planter toute la boucle (le
        // catch externe annulait sinon TOUT le departement). Audit nuit.
        final price = _numToDouble(r['gazole_prix']);
        if (price == null) continue;
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
  /// Utilise le filtre `within_distance(geom, geom'POINT(lng lat)', Xkm)`
  /// natif de l'API ODSql v2.1 -- l'API fait le filtre cote serveur,
  /// on rapatrie uniquement les stations dans le rayon. La distance
  /// exacte est recalculee en RAM via haversine pour le tri + l'UI.
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
      // L'API ODSql v2.1 : within_distance(geom, geom'POINT(lng lat)', Xkm).
      // ATTENTION ordre lng/lat dans POINT (WKT standard) et NON lat/lng.
      // Le 3e argument accepte les suffixes 'km', 'm', etc.
      // On filtre aussi sur gazole_prix non null (sinon ca renvoie des
      // stations sans Diesel = donnees inutiles pour Noah).
      final where = "within_distance(geom, geom'POINT($lng $lat)', "
          "${maxKm.toInt()}km) and gazole_prix is not null";
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'where': where,
        // 'nom' n'existe pas dans le dataset, on prend juste id +
        // adresse + cp + ville. La "marque" n'est pas exposee par
        // data.gouv.fr -- on affichera l'adresse comme label principal.
        'select': 'id,gazole_prix,gazole_maj,cp,ville,adresse,geom',
        'limit': '100',
      });
      final resp = await _http.get(uri).timeout(timeout);
      if (resp.statusCode != 200) return const [];
      // UTF-8 explicite (cf geocodeurs) : evite le mojibake des adresses
      // / villes accentuees si le header charset manque.
      final decoded =
          json.decode(utf8.decode(resp.bodyBytes, allowMalformed: true));
      if (decoded is! Map) return const [];
      final rawResults = decoded['results'];
      final results = rawResults is List ? rawResults : const [];

      final stations = <FuelStation>[];
      for (final r in results) {
        if (r is! Map) continue;
        // `geom` est un objet `{lon: ..., lat: ...}` (geo_point_2d).
        final g = r['geom'];
        if (g is! Map) continue;
        // Conversions tolerantes : une station au prix/coord malforme est
        // SKIP, elle ne fait plus planter toute la liste. Audit nuit.
        final stLat = _numToDouble(g['lat']);
        final stLng = _numToDouble(g['lon']);
        if (stLat == null || stLng == null) continue;
        final price = _numToDouble(r['gazole_prix']);
        if (price == null) continue;
        if (price < 0.5 || price > 5.0) continue;
        final dKm = _haversineKm(lat, lng, stLat, stLng);
        // Filtre defensif : l'API a deja filtre mais on re-coupe au cas
        // ou (precision within_distance vs haversine).
        if (dKm > maxKm) continue;
        stations.add(FuelStation(
          id: r['id']?.toString() ?? '',
          // Pas de nom : data.gouv.fr ne le fournit pas. On laisse vide,
          // l'UI affichera l'adresse comme label principal.
          name: '',
          address: _str(r['adresse'])?.trim() ?? '',
          codePostal: _str(r['cp'])?.trim() ?? '',
          ville: _str(r['ville'])?.trim() ?? '',
          lat: stLat,
          lng: stLng,
          dieselPriceEur: price,
          distanceKm: dKm,
          lastUpdate: _parseDate(r['gazole_maj']),
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

  /// Conversion tolerante num/String -> double (sinon null). Evite qu'une
  /// seule station au champ malforme (String, null, type inattendu) fasse
  /// planter toute la boucle via un cast `as num` -- le catch externe
  /// annulait alors TOUT le resultat. Cf audit robustesse nuit 2026-06-01.
  static double? _numToDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Lecture tolerante d'un champ texte : la String telle quelle, sinon
  /// null (au lieu de `as String?` qui crashe sur un nombre).
  static String? _str(Object? v) => v is String ? v : null;
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
