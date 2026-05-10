import 'package:drift/drift.dart';

import 'database.dart';

class TourneesRepository {
  TourneesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Tournee>> watchAll() {
    final query = _db.select(_db.tournees)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Future<Tournee?> getById(int id) {
    return (_db.select(_db.tournees)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(TourneesCompanion entry) {
    return _db.into(_db.tournees).insert(entry);
  }

  Future<int> update(int id, TourneesCompanion entry) {
    return (_db.update(_db.tournees)..where((t) => t.id.equals(id)))
        .write(entry);
  }

  Future<int> delete(int id) {
    return (_db.delete(_db.tournees)..where((t) => t.id.equals(id))).go();
  }

  /// Duplique une tournee comme template : nouvelle ligne avec le meme
  /// nom (+ suffixe "(copie)"), la meme capacite et le meme point de
  /// depart. Tous les arrets sont copies aussi mais on **reset** les
  /// donnees specifiques a une execution :
  /// - `statutLivraison` -> 'a_livrer'
  /// - `raisonEchec` -> null
  /// - `ordreOptimise` -> null (l'optim devra etre relancee)
  /// - `ordrePriorite` -> conserve (l'ordre EN 1ER / EN DERNIER reflete
  ///   la realite terrain et reste pertinent)
  ///
  /// La date du clone est `nouvelle DateTime.now()` (date du jour),
  /// pour qu'il apparaisse en haut de l'historique. Retourne l'id du
  /// nouveau clone.
  Future<int> duplicate(int sourceId) async {
    return _db.transaction(() async {
      final source = await getById(sourceId);
      if (source == null) {
        throw StateError('Tournee $sourceId introuvable');
      }
      final newId = await _db.into(_db.tournees).insert(
            TourneesCompanion.insert(
              nom: _suffixCopie(source.nom),
              date: DateTime.now(),
              pointDepartLat: source.pointDepartLat,
              pointDepartLng: source.pointDepartLng,
              pointDepartLabel: source.pointDepartLabel,
              vehiculeCapaciteColis: Value(source.vehiculeCapaciteColis),
              // Pas de statut / metriques / trace : nouvelle tournee
              // -> brouillon, pas encore optimisee.
            ),
          );

      final stops = await (_db.select(_db.stops)
            ..where((s) => s.tourneeId.equals(sourceId)))
          .get();
      for (final s in stops) {
        await _db.into(_db.stops).insert(
              StopsCompanion.insert(
                tourneeId: newId,
                adresseBrute: s.adresseBrute,
                adresseNormalisee: Value(s.adresseNormalisee),
                lat: Value(s.lat),
                lng: Value(s.lng),
                nbColis: Value(s.nbColis),
                priorite: Value(s.priorite),
                fenetreDebut: Value(s.fenetreDebut),
                fenetreFin: Value(s.fenetreFin),
                dureeArretMin: Value(s.dureeArretMin),
                notes: Value(s.notes),
                nomClient: Value(s.nomClient),
                ordrePriorite: Value(s.ordrePriorite),
                // Reset des donnees d'execution :
                // - statutLivraison default = 'a_livrer'
                // - raisonEchec default = null
                // - ordreOptimise default = null
              ),
            );
      }
      return newId;
    });
  }

  static String _suffixCopie(String nom) {
    // Si le nom finit deja par "(copie)" ou "(copie N)", on incremente.
    final reg = RegExp(r'^(.*?)\s*\(copie(?:\s+(\d+))?\)\s*$');
    final m = reg.firstMatch(nom);
    if (m == null) return '$nom (copie)';
    final base = m.group(1)!.trim();
    final n = int.tryParse(m.group(2) ?? '') ?? 1;
    return '$base (copie ${n + 1})';
  }

  /// Efface les metadonnees d'optimisation d'une tournee : `optimiseeLe`,
  /// `distanceTotaleM`, `dureeTotaleS`, `traceGeojson`. A appeler des
  /// qu'une modification structurelle (ajout/suppr/edit d'arret, point
  /// de depart change) rend l'optim periment.
  ///
  /// Le `statut` n'est volontairement pas touche : si la tournee est
  /// `en_cours` ou `terminee`, on ne veut pas la faire repasser en
  /// `brouillon` -- on signale juste que l'itineraire calcule n'est
  /// plus a jour, et que le bouton "Optimiser" redevient cliquable.
  Future<int> invalidateOptimization(int id) {
    return (_db.update(_db.tournees)..where((t) => t.id.equals(id))).write(
      const TourneesCompanion(
        optimiseeLe: Value(null),
        distanceTotaleM: Value(null),
        dureeTotaleS: Value(null),
        traceGeojson: Value(null),
      ),
    );
  }
}
