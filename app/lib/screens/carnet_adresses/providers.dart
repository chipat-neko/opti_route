import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/doublon_detection_service.dart';
import '../../providers/database_providers.dart';

/// Stream du contenu complet du carnet d'adresses. Watch directement la
/// table `saved_destinations` via le repository pour recevoir tous les
/// changements (ajout / suppression / favori toggle) en temps reel.
///
/// `autoDispose` car ce provider est lourd (peut contenir des centaines
/// d'entrees) -- on le decompose des qu'on quitte l'ecran qui le watch
/// pour ne pas garder le stream Drift ouvert inutilement.
///
/// Extrait du fichier `carnet_adresses_screen.dart` lors du refactor
/// 2026-05-14 (ecran 704 lignes -> 385). Aussi consomme par
/// `screens/stats/top_clients_card.dart` qui calcule un Top N
/// clients livres par effectif.
final carnetStreamProvider =
    StreamProvider.autoDispose<List<SavedDestination>>((ref) {
  return ref.watch(savedDestinationsRepositoryProvider).watchAll();
});

/// Paires de fiches suspectees d'etre des doublons dans le carnet
/// (carte #103). Derive de [carnetStreamProvider] -> recalcul auto a
/// chaque modif du carnet (ajout / fusion / suppression).
///
/// La detection est en O(n²) (Levenshtein + haversine par paire). Sur un
/// gros carnet, la lancer sur l'isolate UI fige l'ecran (#215) -> on la
/// deporte dans un isolate via compute() au-dela d'un petit seuil. En
/// dessous, le cout de spawn de l'isolate dominerait, donc calcul inline.
const int _kDoublonIsolateThreshold = 150;

final carnetDoublonsProvider =
    FutureProvider.autoDispose<List<DoublonPaire>>((ref) async {
  final entries =
      ref.watch(carnetStreamProvider).asData?.value ?? const <SavedDestination>[];
  if (entries.length < 2) return const [];
  if (entries.length < _kDoublonIsolateThreshold) {
    return DoublonDetectionService.detect(entries);
  }
  return compute(DoublonDetectionService.detect, entries);
});
