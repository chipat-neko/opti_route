import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location_service.dart';
import '../data/location_tuning.dart';
import 'app_lifecycle_provider.dart';
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
    StreamProvider.autoDispose<Position?>((ref) {
  // Mode eco batterie (carte #258) : en consultation passive, GPS moins
  // precis/frequent. La navigation active (navigation_screen) garde son
  // propre stream 10 m haute precision. Le profil plafonne aussi la
  // cadence GPS Android (intervalDuration), meme hors mode eco.
  final eco = ref.watch(modeEcoProvider).value ?? false;
  final profile = resolveGpsProfile(usage: GpsUsage.passive, eco: eco);

  // Batterie (F20-gps-background) : le GPS est le plus gros consommateur
  // de batterie. On SUSPEND la souscription geolocator quand l'app passe
  // en arriere-plan (paused/hidden) et on la REPREND au premier plan,
  // sans reconstruire ce provider. Meme pattern que
  // `ambientLightThemeModeProvider` : un StreamController pilote via
  // `ref.listen(appForegroundProvider)` (et non `ref.watch`) reste vivant
  // et conserve sa DERNIERE Position -> en background on n'emet pas null,
  // donc aucun flash de distance au retour au premier plan.
  final controller = StreamController<Position?>();
  StreamSubscription<Position>? sub;
  var disposed = false;

  void subscribe() {
    if (disposed) return;
    sub ??= LocationService.positionStream(
      distanceFilterMeters: profile.distanceFilterMeters,
      accuracy: profile.accuracy,
      androidInterval: profile.androidInterval,
    ).listen(controller.add, onError: controller.addError);
  }

  void unsubscribe() {
    sub?.cancel();
    sub = null;
  }

  // Bootstrap async : permission + 1ere valeur immediate, puis
  // souscription au stream geolocator UNIQUEMENT si l'app est au premier
  // plan. `disposed` garde contre une resolution apres liberation du
  // provider (ex: dialog de permission qui traine puis plus aucun
  // observateur). C'est le seul ajout vs le pattern de reference, rendu
  // necessaire car ce bootstrap est asynchrone (permission + one-shot).
  Future<void> start() async {
    try {
      final ok = await LocationService.ensurePermission();
      if (disposed) return;
      if (!ok) {
        controller.add(null);
        return;
      }
      // 1ere valeur immediate (avant que le stream ne se cale).
      try {
        final pos = await LocationService.currentPosition();
        if (disposed) return;
        controller.add(pos);
      } catch (_) {/* on continue avec le stream */}
      if (disposed) return;
      if (ref.read(appForegroundProvider) == AppForeground.foreground) {
        subscribe();
      }
    } on LocationPermissionDenied {
      if (!disposed) controller.add(null);
    } catch (error, stack) {
      // Toute autre erreur (permission plateforme, service GPS) etait
      // surfacee comme erreur de stream par l'ancien generateur async*.
      // On preserve ce comportement au lieu de laisser filer une
      // exception async non geree (start() est fire-and-forget).
      if (!disposed) controller.addError(error, stack);
    }
  }

  start();

  // Transitions foreground/background SANS rebuild du provider : on
  // coupe/reprend juste la souscription GPS. En background on garde la
  // derniere Position (on n'emet pas null).
  ref.listen<AppForeground>(appForegroundProvider, (_, next) {
    if (next == AppForeground.foreground) {
      subscribe();
    } else {
      unsubscribe();
    }
  });

  ref.onDispose(() {
    disposed = true;
    unsubscribe();
    controller.close();
  });

  return controller.stream;
});
