import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_service.dart';
import 'database_providers.dart';

/// Stream de la position GPS courante. Emet a chaque deplacement >= 25m
/// (ou >= 100m en mode eco batterie, cf carte #258).
/// L'UI utilise `.whenData` ou `.value` pour afficher la distance live
/// jusqu'au prochain arret.
///
/// `null` si la permission n'a pas encore ete accordee ou si on a
/// jamais demande de position. L'ecran appelle `ensurePermission` au
/// demarrage de la tournee pour declencher le stream.
final currentPositionProvider = StreamProvider<Position?>((ref) async* {
  // Mode eco batterie (carte #258) : en consultation passive, GPS moins
  // precis/frequent (medium / 100 m vs high / 25 m). La navigation active
  // (navigation_screen) garde son propre stream 10 m haute precision.
  final eco = ref.watch(modeEcoProvider).value ?? false;
  final filter = eco ? 100 : 25;
  final accuracy = eco ? LocationAccuracy.medium : LocationAccuracy.high;
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
      distanceFilterMeters: filter,
      accuracy: accuracy,
    );
  } on LocationPermissionDenied {
    yield null;
  }
});
