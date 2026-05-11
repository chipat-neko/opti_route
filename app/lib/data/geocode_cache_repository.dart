import 'dart:convert';

import 'package:drift/drift.dart';

import 'address_suggestion.dart';
import 'database.dart';

/// Cache persistant des reponses Nominatim.
/// Evite de re-taper Nominatim pour des adresses deja vues recemment
/// (TTL 30 jours par defaut). Permet aussi de tenir le rate limit
/// public a 1 req/s en n'envoyant que les vraies nouvelles requetes.
class GeocodeCacheRepository {
  GeocodeCacheRepository(this._db);

  final AppDatabase _db;

  static const Duration defaultTtl = Duration(days: 30);

  String _normalize(String query) =>
      query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Lit le cache si non expire, sinon `null`.
  Future<List<AddressSuggestion>?> read(String query) async {
    final key = _normalize(query);
    final row = await (_db.select(_db.geocodeCache)
          ..where((c) => c.query.equals(key)))
        .getSingleOrNull();

    if (row == null) return null;
    if (row.expireLe.isBefore(DateTime.now())) {
      // Hit expire -> on supprime au passage.
      await (_db.delete(_db.geocodeCache)..where((c) => c.query.equals(key)))
          .go();
      return null;
    }

    final list = jsonDecode(row.responseJson) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(AddressSuggestion.fromJson)
        .toList(growable: false);
  }

  /// V7.5 : lit le cache par **prefixe** plutot que par cle exacte.
  /// Permet de reutiliser les resultats d'une recherche plus large
  /// (ex: si "char" est cache, "chart" peut taper dedans en filtrant
  /// les resultats qui commencent par "chart").
  ///
  /// Garde-fous anti-faux-positifs :
  /// - `prefix` doit avoir au moins 4 caracteres (sinon trop large).
  /// - Apres lecture, on **filtre** les suggestions dont aucun champ
  ///   pertinent (displayName, road, city, poiName) ne contient le
  ///   prefixe en insensitive. Evite de proposer "Charles de Gaulle"
  ///   quand l'utilisateur tape "chartres".
  /// - Si moins de 2 resultats apres filtrage, on retourne null pour
  ///   que l'appelant fasse la vraie requete reseau (gain marginal
  ///   pas digne du risque).
  ///
  /// Cherche toutes les entrees `query LIKE prefix%` non expirees,
  /// concatene les resultats et dedupe par coords.
  Future<List<AddressSuggestion>?> readByPrefix(String prefix) async {
    final normalized = _normalize(prefix);
    if (normalized.length < 4) return null;

    final now = DateTime.now();
    final rows = await (_db.select(_db.geocodeCache)
          ..where((c) =>
              c.query.like('$normalized%') &
              c.expireLe.isBiggerThanValue(now)))
        .get();
    if (rows.isEmpty) return null;

    final all = <AddressSuggestion>[];
    for (final row in rows) {
      try {
        final list = jsonDecode(row.responseJson) as List;
        for (final m in list.whereType<Map<String, dynamic>>()) {
          all.add(AddressSuggestion.fromJson(m));
        }
      } catch (_) {
        // Entree corrompue : on saute.
      }
    }
    if (all.isEmpty) return null;

    // Filtre pertinence : au moins un champ textuel doit contenir le
    // prefixe. La cle de cache est typiquement `<provider>:<query>` ;
    // on ne filtre que sur la partie query, sinon "ban:chart" ne
    // matcherait jamais un displayName qui ne commence pas par "ban:".
    final colonIdx = normalized.indexOf(':');
    final lower = colonIdx >= 0
        ? normalized.substring(colonIdx + 1)
        : normalized;
    if (lower.length < 3) {
      // Apres avoir retire le provider, on a moins de 3 chars : trop
      // permissif, on refuse.
      return null;
    }
    final filtered = all.where((s) {
      bool contains(String? v) =>
          v != null && v.toLowerCase().contains(lower);
      return contains(s.displayName) ||
          contains(s.road) ||
          contains(s.city) ||
          contains(s.poiName);
    }).toList();
    if (filtered.length < 2) return null;

    // Dedup par coords arrondies (5 decimales = ~1m).
    final seen = <String>{};
    final dedup = <AddressSuggestion>[];
    for (final s in filtered) {
      final key = '${s.lat.toStringAsFixed(5)}_${s.lon.toStringAsFixed(5)}';
      if (seen.add(key)) dedup.add(s);
    }
    return dedup;
  }

  /// Ecrit (ou ecrase) une entree de cache. Si la liste est vide on
  /// stocke quand meme — c'est un signal "rien trouve" qui evite de
  /// retaper Nominatim immediatement.
  Future<void> write(
    String query,
    List<AddressSuggestion> results, {
    Duration ttl = defaultTtl,
  }) {
    final key = _normalize(query);
    final encoded = jsonEncode(results.map(_encode).toList());
    return _db.into(_db.geocodeCache).insertOnConflictUpdate(
          GeocodeCacheCompanion.insert(
            query: key,
            responseJson: encoded,
            expireLe: DateTime.now().add(ttl),
          ),
        );
  }

  Map<String, dynamic> _encode(AddressSuggestion s) => {
        'display_name': s.displayName,
        'lat': s.lat.toString(),
        'lon': s.lon.toString(),
        'address': {
          if (s.road != null) 'road': s.road,
          if (s.houseNumber != null) 'house_number': s.houseNumber,
          if (s.postcode != null) 'postcode': s.postcode,
          if (s.city != null) 'city': s.city,
          if (s.country != null) 'country': s.country,
        },
      };

  /// Purge toutes les entrees expirees (utile au demarrage).
  Future<int> purgeExpired() {
    return (_db.delete(_db.geocodeCache)
          ..where((c) => c.expireLe.isSmallerThanValue(DateTime.now())))
        .go();
  }

  /// Vide TOUT le cache, expirees ou non. Utile quand on change de
  /// fournisseur ou apres un fix de parser pour relancer toutes les
  /// recherches.
  Future<int> purgeAll() {
    return _db.delete(_db.geocodeCache).go();
  }
}
