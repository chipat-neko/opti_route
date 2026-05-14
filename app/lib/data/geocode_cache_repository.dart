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

    // Decode tolerant : si le JSON ou une entree individuelle est
    // corrompu (downgrade format, ecriture interrompue...), on traite
    // comme cache miss plutot que de crasher. Le caller refetchera.
    List<dynamic> list;
    try {
      final decoded = jsonDecode(row.responseJson);
      if (decoded is! List) throw const FormatException('cache not a list');
      list = decoded;
    } catch (_) {
      await (_db.delete(_db.geocodeCache)
            ..where((c) => c.query.equals(key)))
          .go();
      return null;
    }
    final out = <AddressSuggestion>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        out.add(AddressSuggestion.fromJson(entry));
      } catch (_) {/* skip entree corrompue, on garde les autres */}
    }
    return out;
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

  /// Compte le nombre d'entrees actuellement en cache (toutes, expirees
  /// ou non). Affiche dans Parametres pour donner une idee de l'usage.
  Future<int> count() async {
    final rows = await _db.select(_db.geocodeCache).get();
    return rows.length;
  }
}
