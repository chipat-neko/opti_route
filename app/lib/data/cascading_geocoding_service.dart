import 'address_suggestion.dart';
import 'geocoding_service.dart';

/// Compose plusieurs [GeocodingService] en cascade pour maximiser
/// le taux de reussite. Strategie :
///
/// 1. Tente le 1er fournisseur (le plus precis).
/// 2. Si erreur recuperable -> on passe au suivant en silencieux.
/// 3. Si le 1er retourne des resultats avec house_number -> on s'arrete
///    (precis = on n'a pas besoin de fallback).
/// 4. Si le 1er retourne des resultats sans house_number ou rien -> on
///    interroge le suivant et on **merge + dedupe**, puis on retourne.
///
/// Le but : Noah ne voit jamais "0 resultat" si une autre source connait
/// l'adresse, et si la 1ere a deja le numero precis, on ne paye pas une
/// 2eme requete inutile.
class CascadingGeocodingService implements GeocodingService {
  CascadingGeocodingService(this._providers)
      : assert(_providers.isNotEmpty, 'Au moins un fournisseur requis');

  final List<GeocodingService> _providers;

  @override
  String get providerKey => 'cascade';

  @override
  Future<List<AddressSuggestion>> search(
    String query,
    {int limit = 10, String acceptLanguage = 'fr-FR'}
  ) async {
    final accumulated = <AddressSuggestion>[];

    for (var i = 0; i < _providers.length; i++) {
      final provider = _providers[i];
      try {
        final results = await provider.search(
          query,
          limit: limit,
          acceptLanguage: acceptLanguage,
        );
        accumulated.addAll(results);

        // Le 1er fournisseur (le plus precis) a deja trouve du precis ?
        // On s'arrete pour eviter une requete inutile.
        if (i == 0 && _hasPreciseResult(results)) {
          return _dedupe(accumulated);
        }
      } catch (_) {
        // Erreur recuperable (timeout, 401, 403...) -> on tente le suivant
        // au lieu de planter le widget. La derniere exception est ignoree
        // si on a au moins un fournisseur qui a repondu.
        if (i == _providers.length - 1 && accumulated.isEmpty) rethrow;
      }
    }

    return _dedupe(accumulated);
  }

  bool _hasPreciseResult(List<AddressSuggestion> results) {
    return results.any((s) =>
        s.houseNumber != null && s.houseNumber!.isNotEmpty);
  }

  List<AddressSuggestion> _dedupe(List<AddressSuggestion> all) {
    final seen = <String>{};
    final out = <AddressSuggestion>[];
    for (final s in all) {
      final key = '${s.lat.toStringAsFixed(5)}_${s.lon.toStringAsFixed(5)}';
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  @override
  void close() {
    for (final p in _providers) {
      p.close();
    }
  }
}
