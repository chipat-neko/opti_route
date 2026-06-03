import 'package:drift/drift.dart';

import 'database.dart';
import 'geo_utils.dart';
import 'stop_types.dart';
import 'stops_repository.dart';

/// Un bordereau scanne en mode batch (carte #119), pret a devenir un
/// arret. Les coords sont deja resolues (geocodage fait cote UI avant
/// le commit) ; null si le geocodage a echoue (l'arret est cree quand
/// meme, sans coords, comme un ajout manuel hors-ligne).
class BatchScanItem {
  const BatchScanItem({
    required this.adresse,
    this.nomClient,
    this.telephone,
    this.lat,
    this.lng,
    this.nbColis = 1,
    this.isEnlevement = false,
  });

  final String adresse;
  final String? nomClient;
  final String? telephone;
  final double? lat;
  final double? lng;
  final int nbColis;
  final bool isEnlevement;
}

/// Resultat d'un commit batch : combien d'arrets crees vs ignores
/// comme doublons.
class BatchCommitSummary {
  const BatchCommitSummary({required this.crees, required this.doublons});

  final int crees;
  final int doublons;

  int get total => crees + doublons;
}

/// Cree en masse les arrets d'un scan batch (carte #119), avec
/// deduplication. Sert au "Terminer" du mode rafale : on a N bordereaux
/// scannes, on les ajoute d'un coup a la tournee en sautant les
/// doublons (meme client deja present, ou meme point GPS).
class BatchScanCommitService {
  BatchScanCommitService(this._stops);

  final StopsRepository _stops;

  /// Distance en dessous de laquelle 2 arrets geocodes sont consideres
  /// au "meme endroit" (anti-doublon). 50 m : couvre les imprecisions
  /// de geocodage d'une meme adresse sans fusionner 2 maisons voisines.
  static const double kSeuilDoublonMetres = 50;

  /// Cree les arrets pour [items] dans [tourneeId], en sautant les
  /// doublons (vs les arrets deja presents ET vs les items deja acceptes
  /// plus tot dans le meme batch). Retourne le bilan.
  Future<BatchCommitSummary> commit({
    required int tourneeId,
    required List<BatchScanItem> items,
  }) async {
    final existing = await _stops.getByTournee(tourneeId);
    // Empreintes des arrets deja en base (pour le dedup).
    final refs = <({String? nom, double? lat, double? lng})>[
      for (final s in existing)
        (nom: s.nomClient, lat: s.lat, lng: s.lng),
    ];
    final accepted = <BatchScanItem>[];
    var doublons = 0;
    for (final item in items) {
      final dup = refs.any((r) => _isDuplicate(
            nomA: item.nomClient,
            latA: item.lat,
            lngA: item.lng,
            nomB: r.nom,
            latB: r.lat,
            lngB: r.lng,
          ));
      if (dup) {
        doublons++;
        continue;
      }
      accepted.add(item);
      refs.add((nom: item.nomClient, lat: item.lat, lng: item.lng));
    }

    for (final item in accepted) {
      await _stops.create(StopsCompanion.insert(
        tourneeId: tourneeId,
        adresseBrute: item.adresse,
        nomClient: Value(item.nomClient),
        telephone: Value(item.telephone),
        nbColis: Value(item.nbColis),
        type: Value(item.isEnlevement ? kStopTypeRamasse : kStopTypeLivraison),
        lat: Value(item.lat),
        lng: Value(item.lng),
      ));
    }
    return BatchCommitSummary(crees: accepted.length, doublons: doublons);
  }

  /// PURE : deux arrets sont doublons si meme nom client (normalise,
  /// non-vide) OU meme point GPS (< [kSeuilDoublonMetres]). Sans coords
  /// ni nom commun -> pas doublon (on prefere creer en double que de
  /// perdre un arret).
  static bool _isDuplicate({
    required String? nomA,
    required double? latA,
    required double? lngA,
    required String? nomB,
    required double? latB,
    required double? lngB,
  }) {
    final na = _normNom(nomA);
    final nb = _normNom(nomB);
    if (na != null && nb != null && na == nb) return true;
    if (latA != null && lngA != null && latB != null && lngB != null) {
      final d = GeoUtils.haversineMeters(
        lat1: latA,
        lon1: lngA,
        lat2: latB,
        lon2: lngB,
      );
      if (d < kSeuilDoublonMetres) return true;
    }
    return false;
  }

  /// Normalise un nom client pour la comparaison : trim + minuscules +
  /// espaces compresses. Null si vide.
  static String? _normNom(String? nom) {
    if (nom == null) return null;
    final n = nom.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return n.isEmpty ? null : n;
  }

  /// Expose le test de doublon pour les tests + l'UI (apercu recap).
  static bool isDuplicate(BatchScanItem a, BatchScanItem b) => _isDuplicate(
        nomA: a.nomClient,
        latA: a.lat,
        lngA: a.lng,
        nomB: b.nomClient,
        latB: b.lat,
        lngB: b.lng,
      );
}
