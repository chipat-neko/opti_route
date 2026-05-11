import 'package:drift/drift.dart';

import 'database.dart';

/// Carnet d'adresses local : chaque arret valide ajoute (ou rafraichit)
/// une entree. Tout reste sur le telephone (meme base SQLite que le
/// reste de l'app).
class SavedDestinationsRepository {
  SavedDestinationsRepository(this._db);

  final AppDatabase _db;

  /// Insert ou refresh : si une entree avec le meme nomClient (insensible
  /// a la casse) existe deja, on incremente useCount et on met a jour
  /// lastUsedAt + adresse (au cas ou le client a demenage). Sinon, on
  /// distingue aussi par lat/lng arrondis (4 decimales ~= 11m) pour
  /// gerer les saisies sans nom client.
  Future<void> upsertFromValidatedStop({
    String? nomClient,
    required String adresseDisplay,
    required double lat,
    required double lng,
    String? rue,
    String? codePostal,
    String? ville,
  }) async {
    final now = DateTime.now();
    final normalizedNom = nomClient?.trim();

    final existing = await _findExisting(
      nomClient: normalizedNom,
      lat: lat,
      lng: lng,
    );

    if (existing != null) {
      await (_db.update(_db.savedDestinations)
            ..where((d) => d.id.equals(existing.id)))
          .write(SavedDestinationsCompanion(
        adresseDisplay: Value(adresseDisplay),
        lat: Value(lat),
        lng: Value(lng),
        rue: Value(rue),
        codePostal: Value(codePostal),
        ville: Value(ville),
        useCount: Value(existing.useCount + 1),
        lastUsedAt: Value(now),
      ));
      return;
    }

    await _db.into(_db.savedDestinations).insert(
          SavedDestinationsCompanion.insert(
            nomClient: Value(normalizedNom == null || normalizedNom.isEmpty
                ? null
                : normalizedNom),
            adresseDisplay: adresseDisplay,
            lat: lat,
            lng: lng,
            rue: Value(rue),
            codePostal: Value(codePostal),
            ville: Value(ville),
          ),
        );
  }

  /// Cherche une entree existante par nomClient (case-insensitive) ou,
  /// a defaut, par proximite GPS (~11 metres a 4 decimales).
  Future<SavedDestination?> _findExisting({
    String? nomClient,
    required double lat,
    required double lng,
  }) async {
    if (nomClient != null && nomClient.isNotEmpty) {
      final byName = await (_db.select(_db.savedDestinations)
            ..where((d) =>
                d.nomClient.lower().equals(nomClient.toLowerCase())))
          .getSingleOrNull();
      if (byName != null) return byName;
    }
    // Fallback : meme coords arrondies a 4 decimales.
    final all = await _db.select(_db.savedDestinations).get();
    for (final d in all) {
      if ((d.lat - lat).abs() < 0.0001 && (d.lng - lng).abs() < 0.0001) {
        return d;
      }
    }
    return null;
  }

  /// Recherche dans le carnet local : matche nomClient OU adresseDisplay
  /// OU ville. Filtrage fait en memoire pour gerer correctement les
  /// accents (Lucé == luce), ce que SQLite ne fait pas nativement.
  /// Acceptable car le carnet reste petit (< 1000 entrees typiquement).
  /// Retourne les plus utilisees d'abord, puis les plus recentes.
  Future<List<SavedDestination>> search(String query, {int limit = 5}) async {
    final q = _normalize(query);
    if (q.length < 2) return const [];

    final all = await (_db.select(_db.savedDestinations)
          ..orderBy([
            (d) => OrderingTerm.desc(d.useCount),
            (d) => OrderingTerm.desc(d.lastUsedAt),
          ]))
        .get();

    final matched = all.where((d) {
      final hay = [
        _normalize(d.nomClient ?? ''),
        _normalize(d.adresseDisplay),
        _normalize(d.ville ?? ''),
      ].join(' ');
      return hay.contains(q);
    }).toList();

    return matched.take(limit).toList();
  }

  /// Lowercase + retire les diacritiques (NFD-style minimal).
  static String _normalize(String s) {
    final lower = s.toLowerCase().trim();
    const map = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ÿ': 'y', 'ý': 'y',
      'ñ': 'n',
      'œ': 'oe', 'æ': 'ae',
    };
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  Stream<List<SavedDestination>> watchAll() {
    final select = _db.select(_db.savedDestinations)
      ..orderBy([
        // Favoris en haut, peu importe useCount/lastUsedAt.
        (d) => OrderingTerm.desc(d.isFavori),
        (d) => OrderingTerm.desc(d.useCount),
        (d) => OrderingTerm.desc(d.lastUsedAt),
      ]);
    return select.watch();
  }

  /// Toggle l'etoile "favori" sur une entree du carnet.
  Future<int> toggleFavori(int id) async {
    final entry = await getById(id);
    if (entry == null) return 0;
    return (_db.update(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .write(SavedDestinationsCompanion(isFavori: Value(!entry.isFavori)));
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .go();
  }

  Future<SavedDestination?> getById(int id) {
    return (_db.select(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }

  /// Edition manuelle d'une entree du carnet. On ne met a jour que les
  /// champs fournis, sans toucher a `useCount` ni `creeLe`.
  Future<int> update(
    int id, {
    String? nomClient,
    String? adresseDisplay,
    double? lat,
    double? lng,
    String? rue,
    String? codePostal,
    String? ville,
  }) {
    return (_db.update(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .write(SavedDestinationsCompanion(
      nomClient: nomClient == null
          ? const Value.absent()
          : Value(nomClient.isEmpty ? null : nomClient),
      adresseDisplay: adresseDisplay == null
          ? const Value.absent()
          : Value(adresseDisplay),
      lat: lat == null ? const Value.absent() : Value(lat),
      lng: lng == null ? const Value.absent() : Value(lng),
      rue: rue == null ? const Value.absent() : Value(rue.isEmpty ? null : rue),
      codePostal: codePostal == null
          ? const Value.absent()
          : Value(codePostal.isEmpty ? null : codePostal),
      ville: ville == null
          ? const Value.absent()
          : Value(ville.isEmpty ? null : ville),
    ));
  }

  Future<int> count() async {
    final rows = await _db.select(_db.savedDestinations).get();
    return rows.length;
  }
}
