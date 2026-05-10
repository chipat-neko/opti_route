import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_service.dart';

/// Stream de la position GPS courante. Emet a chaque deplacement >= 25m.
/// L'UI utilise `.whenData` ou `.value` pour afficher la distance live
/// jusqu'au prochain arret.
///
/// `null` si la permission n'a pas encore ete accordee ou si on a
/// jamais demande de position. L'ecran appelle `ensurePermission` au
/// demarrage de la tournee pour declencher le stream.
final currentPositionProvider = StreamProvider<Position?>((ref) async* {
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
    yield* LocationService.positionStream();
  } on LocationPermissionDenied {
    yield null;
  }
});
