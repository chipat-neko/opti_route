import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
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
