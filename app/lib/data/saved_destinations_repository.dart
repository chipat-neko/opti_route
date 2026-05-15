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
  ///
  /// Si plusieurs clients homonymes existent (cas reel : "MARTIN" dans
  /// deux villes differentes), on prefere celui dont les coords sont
  /// les plus proches du stop courant. Avant le fix 2026-05-14, on
  /// utilisait `getSingleOrNull` qui throw en cas d'homonymes.
  Future<SavedDestination?> _findExisting({
    String? nomClient,
    required double lat,
    required double lng,
  }) async {
    if (nomClient != null && nomClient.isNotEmpty) {
      final byName = await (_db.select(_db.savedDestinations)
            ..where((d) =>
                d.nomClient.lower().equals(nomClient.toLowerCase())))
          .get();
      if (byName.isNotEmpty) {
        if (byName.length == 1) return byName.first;
        // Homonymes : on prend celui dont les coords sont les plus proches.
        byName.sort((a, b) {
          final da = (a.lat - lat).abs() + (a.lng - lng).abs();
          final db = (b.lat - lat).abs() + (b.lng - lng).abs();
          return da.compareTo(db);
        });
        return byName.first;
      }
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

  /// Met a jour la couleur custom d'une entree (cf colorTag dans la
  /// table). [tag] peut etre null pour reset a la couleur par defaut.
  Future<int> setColorTag(int id, String? tag) {
    return (_db.update(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .write(SavedDestinationsCompanion(colorTag: Value(tag)));
  }

  /// Toggle l'etoile "favori" sur une entree du carnet.
  /// Atomique : un double-tap rapide ne pourra pas flipper la valeur
  /// deux fois (sinon le 2eme tap voit la valeur stale).
  Future<int> toggleFavori(int id) async {
    return _db.transaction(() async {
      final entry = await getById(id);
      if (entry == null) return 0;
      return (_db.update(_db.savedDestinations)
            ..where((d) => d.id.equals(id)))
          .write(
              SavedDestinationsCompanion(isFavori: Value(!entry.isFavori)));
    });
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
    String? notesCarnet,
    String? codeAcces,
    String? etageBatiment,
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
      notesCarnet: notesCarnet == null
          ? const Value.absent()
          : Value(notesCarnet.isEmpty ? null : notesCarnet),
      codeAcces: codeAcces == null
          ? const Value.absent()
          : Value(codeAcces.isEmpty ? null : codeAcces),
      etageBatiment: etageBatiment == null
          ? const Value.absent()
          : Value(etageBatiment.isEmpty ? null : etageBatiment),
    ));
  }

  /// Met a jour les tags (liste de strings encodee en JSON) d'une
  /// entree du carnet. [tags] vide ou null -> stocke null.
  Future<int> setTags(int id, List<String>? tags) {
    final v = (tags == null || tags.isEmpty)
        ? null
        : '[${tags.map((t) => '"${t.replaceAll('"', r'\"')}"').join(',')}]';
    return (_db.update(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .write(SavedDestinationsCompanion(tagsJson: Value(v)));
  }

  /// Decode les tags JSON d'une entree. Retourne liste vide si null
  /// ou si le JSON est malforme.
  static List<String> parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return const [];
    // Parser minimaliste : on attend ["a","b","c"], pas de support
    // des caracteres echappes complexes (suffit pour tags courts).
    final trimmed = tagsJson.trim();
    if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return const [];
    final inner = trimmed.substring(1, trimmed.length - 1).trim();
    if (inner.isEmpty) return const [];
    return inner
        .split(',')
        .map((s) {
          var t = s.trim();
          if (t.startsWith('"') && t.endsWith('"')) {
            t = t.substring(1, t.length - 1);
          }
          return t.replaceAll(r'\"', '"');
        })
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
  }

  /// Update le chemin photo (facade/interphone). Null pour retirer.
  Future<int> setPhotoPath(int id, String? path) {
    return (_db.update(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .write(SavedDestinationsCompanion(photoPath: Value(path)));
  }

  /// COUNT(*) cote SQLite (vs .length apres avoir chargé toutes les
  /// lignes). Sur un carnet de 1000+ entrées, la difference est nette.
  Future<int> count() async {
    final col = _db.savedDestinations.id.count();
    final row = await (_db.selectOnly(_db.savedDestinations)
          ..addColumns([col]))
        .getSingle();
    return row.read(col) ?? 0;
  }
}
