import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_service.dart';
import '../data/location_tuning.dart';
import 'database_providers.dart';

/// Stream de la position GPS courante. Emet a chaque deplacement >= 25m
/// (ou >= 100m en mode eco batterie, cf carte #258).
/// L'UI utilise `.whenData` ou `.value` pour afficher la distance live
/// jusqu'au prochain arret.
///
/// `null` si la permission n'a pas encore ete accordee ou si on a
/// jamais demande de position. L'ecran appelle `ensurePermission` au
/// demarrage de la tournee pour declencher le stream.
///
/// **autoDispose** (feat/opti-batterie) : le GPS est le plus gros
/// consommateur de batterie. Sans autoDispose, ce stream restait
/// souscrit pour toute la vie du process des qu'une tournee etait
/// ouverte une fois -> GPS actif meme apres avoir quitte l'ecran
/// tournee. Avec autoDispose, le stream se ferme (et le GPS s'arrete)
/// des qu'aucun widget ne l'observe (ex: on passe dans Parametres ou
/// l'historique). Il se relance tout seul au retour sur la tournee.
final currentPositionProvider =
    StreamProvider.autoDispose<Position?>((ref) async* {
  // Mode eco batterie (carte #258) : en consultation passive, GPS moins
  // precis/frequent. La navigation active (navigation_screen) garde son
  // propre stream 10 m haute precision. Le profil plafonne aussi la
  // cadence GPS Android (intervalDuration), meme hors mode eco.
  final eco = ref.watch(modeEcoProvider).value ?? false;
  final profile = resolveGpsProfile(usage: GpsUsage.passive, eco: eco);
  try {
    final ok = await LocationService.ensurePermission();
    if (!ok) {
      yield null;
      return;
    }
    // 1ere valeur immediate (avant que le stream ne se cale).
    try {
      yield await LocationService.currentPosition();
    } catch (_) {/* on continue avec le stream */}
    yield* LocationService.positionStream(
      distanceFilterMeters: profile.distanceFilterMeters,
      accuracy: profile.accuracy,
      androidInterval: profile.androidInterval,
    );
  } on LocationPermissionDenied {
    yield null;
  }
});
