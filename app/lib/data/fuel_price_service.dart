import 'dart:convert';

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

  void dispose() => _http.close();
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
