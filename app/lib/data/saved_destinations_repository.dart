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
    String? telephone,
  }) async {
    final now = DateTime.now();
    final normalizedNom = nomClient?.trim();
    final tel = (telephone ?? '').trim();
    final telValue = tel.isEmpty ? null : tel;

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
        // N'ecrase pas un telephone existant par null (import vCard #102).
        telephone:
            telValue == null ? const Value.absent() : Value(telValue),
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
            telephone: Value(telValue),
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
  /// Lookup public d'un destinataire par nom client (case-insensitive,
  /// trim). Retourne le 1er match exact ou null. Sert au bouton
  /// "Appeler client" dans StopActionSheet (QW4 - PR sprint immediat
  /// 2026-05-31) : le `Stops.nomClient` n'a pas de champ `telephone`
  /// mais le carnet `saved_destinations.telephone` peut etre branche
  /// par lookup.
  Future<SavedDestination?> findByNomClient(String nomClient) async {
    final trimmed = nomClient.trim();
    if (trimmed.isEmpty) return null;
    final rows = await (_db.select(_db.savedDestinations)
          ..where((d) => d.nomClient.lower().equals(trimmed.toLowerCase()))
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

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

  /// Renvoie tout le carnet en une fois (pour les services qui font
  /// du fuzzy matching en memoire comme [ClientMemoryService]). Trie
  /// favoris > useCount > lastUsedAt comme [watchAll].
  Future<List<SavedDestination>> getAll() {
    final select = _db.select(_db.savedDestinations)
      ..orderBy([
        (d) => OrderingTerm.desc(d.isFavori),
        (d) => OrderingTerm.desc(d.useCount),
        (d) => OrderingTerm.desc(d.lastUsedAt),
      ]);
    return select.get();
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

  // ─── Operations en masse (carte #104) ───────────────────────────────
  // Une seule requete SQL par operation (WHERE id IN (...)), pas N
  // requetes. Retournent le nombre de lignes affectees.

  /// Applique (ou retire si [tag] == null) une etiquette couleur a
  /// plusieurs fiches d'un coup.
  Future<int> setColorTagBulk(List<int> ids, String? tag) {
    if (ids.isEmpty) return Future.value(0);
    return (_db.update(_db.savedDestinations)..where((d) => d.id.isIn(ids)))
        .write(SavedDestinationsCompanion(colorTag: Value(tag)));
  }

  /// Met le flag favori a [favori] sur plusieurs fiches d'un coup.
  Future<int> setFavoriBulk(List<int> ids, bool favori) {
    if (ids.isEmpty) return Future.value(0);
    return (_db.update(_db.savedDestinations)..where((d) => d.id.isIn(ids)))
        .write(SavedDestinationsCompanion(isFavori: Value(favori)));
  }

  /// Supprime plusieurs fiches du carnet d'un coup.
  Future<int> deleteBulk(List<int> ids) {
    if (ids.isEmpty) return Future.value(0);
    return (_db.delete(_db.savedDestinations)..where((d) => d.id.isIn(ids)))
        .go();
  }

  Future<SavedDestination?> getById(int id) {
    return (_db.select(_db.savedDestinations)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }

  /// Fusionne 2 fiches doublons (carte #103) : conserve [keepId], y
  /// recopie les champs que [dropId] renseigne mais que [keepId] laisse
  /// vide, cumule `useCount`, OR sur `isFavori`, garde le `lastUsedAt`
  /// le plus recent, puis supprime [dropId]. No-op si l'une des 2 fiches
  /// est introuvable. Transaction atomique.
  Future<void> mergeInto(int keepId, int dropId) async {
    if (keepId == dropId) return;
    await _db.transaction(() async {
      final keep = await getById(keepId);
      final drop = await getById(dropId);
      if (keep == null || drop == null) return;

      // Garde la valeur de keep si non-vide, sinon prend celle de drop.
      String? pick(String? k, String? d) {
        final kv = (k ?? '').trim();
        if (kv.isNotEmpty) return k;
        final dv = (d ?? '').trim();
        return dv.isEmpty ? null : d;
      }

      final lastUsed = keep.lastUsedAt.isAfter(drop.lastUsedAt)
          ? keep.lastUsedAt
          : drop.lastUsedAt;

      await (_db.update(_db.savedDestinations)
            ..where((t) => t.id.equals(keepId)))
          .write(SavedDestinationsCompanion(
        nomClient: Value(pick(keep.nomClient, drop.nomClient)),
        rue: Value(pick(keep.rue, drop.rue)),
        codePostal: Value(pick(keep.codePostal, drop.codePostal)),
        ville: Value(pick(keep.ville, drop.ville)),
        notesCarnet: Value(pick(keep.notesCarnet, drop.notesCarnet)),
        codeAcces: Value(pick(keep.codeAcces, drop.codeAcces)),
        etageBatiment: Value(pick(keep.etageBatiment, drop.etageBatiment)),
        telephone: Value(pick(keep.telephone, drop.telephone)),
        colorTag: Value(pick(keep.colorTag, drop.colorTag)),
        photoPath: Value(pick(keep.photoPath, drop.photoPath)),
        tagsJson: Value(pick(keep.tagsJson, drop.tagsJson)),
        useCount: Value(keep.useCount + drop.useCount),
        isFavori: Value(keep.isFavori || drop.isFavori),
        lastUsedAt: Value(lastUsed),
      ));

      await (_db.delete(_db.savedDestinations)
            ..where((t) => t.id.equals(dropId)))
          .go();
    });
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
    String? telephone,
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
      telephone: telephone == null
          ? const Value.absent()
          : Value(telephone.isEmpty ? null : telephone),
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
