import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/database.dart';
import '../data/location_service.dart';
import '../data/location_tuning.dart';
import '../data/proximity_checker.dart';
// `firstAlivrerWithCoords` designe le prochain arret planifie. La regle
// est partagee avec ProchainArretCard : la recopier ici ferait diverger
// les deux affichages des la premiere retouche, ce que le bandeau de
// proximite doit precisement eviter.
import '../data/stop_selection.dart';
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

/// Position courante reduite au couple (lat, lng) : ce dont ont besoin
/// les providers derives, et rien de plus.
///
/// Deux raisons d'exister plutot que de watcher [currentPositionProvider]
/// directement :
/// - une `Position` porte aussi l'horodatage, la precision, la vitesse et
///   le cap, qui bougent a CHAQUE fix meme quand on ne se deplace pas.
///   Ce record a une egalite structurelle : tant que lat/lng ne changent
///   pas, les providers qui en derivent ne sont pas re-executes.
/// - il isole ces providers (et leurs tests) du plugin geolocator.
///
/// null tant qu'aucun fix n'est arrive, si la permission est refusee ou
/// si le stream GPS est en erreur (`.asData` rend null dans ces cas) :
/// on ne calcule alors rien plutot que d'afficher une valeur douteuse.
final currentLatLngProvider =
    Provider.autoDispose<({double lat, double lng})?>((ref) {
  final pos = ref.watch(currentPositionProvider).asData?.value;
  if (pos == null) return null;
  return (lat: pos.latitude, lng: pos.longitude);
});

/// Ce que l'ecran affiche quand un ou plusieurs arrets a livrer sont a
/// portee immediate (carte #285). Snapshot immuable : pas de Stop brut
/// recalcule cote widget.
class ArretsProches {
  const ArretsProches({
    required this.plusProche,
    required this.distanceMeters,
    required this.autresCount,
  });

  /// Arret `a_livrer` le plus proche de la position courante.
  final Stop plusProche;

  /// Distance a vol d'oiseau jusqu'a [plusProche], arrondie au metre.
  /// Arrondie des ici pour que deux fixes GPS qui donnent le meme
  /// affichage produisent deux [ArretsProches] egaux (cf `operator ==`).
  final int distanceMeters;

  /// Nombre d'AUTRES arrets a livrer dans le meme rayon (0 = il est seul).
  final int autresCount;

  /// Egalite structurelle : c'est elle qui evite de repropager un rebuild
  /// a chaque emission GPS quand le bandeau afficherait exactement la
  /// meme chose. `Stop` est une data class Drift, son `==` compare toutes
  /// les colonnes (donc un renommage du client rafraichit bien le texte).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArretsProches &&
          other.plusProche == plusProche &&
          other.distanceMeters == distanceMeters &&
          other.autresCount == autresCount);

  @override
  int get hashCode => Object.hash(plusProche, distanceMeters, autresCount);

  @override
  String toString() => 'ArretsProches(${plusProche.id}, ${distanceMeters}m, '
      '+$autresCount)';
}

/// Traduit le resultat brut de [ProximityChecker.findNearby] en ce que le
/// bandeau montre. Fonction PURE : testable sans Riverpod ni geolocator.
///
/// [exclureStopId] retire completement un arret du calcul : le bandeau
/// ne doit rien dire du PROCHAIN arret planifie, dont `ProchainArretCard`
/// affiche deja la distance juste en dessous (sinon le bandeau ne fait
/// que repeter). L'exclusion porte aussi sur le compteur "+N autres",
/// pour qu'il reste coherent avec ce qui est affiche : le bandeau ne
/// parle QUE des arrets proches hors sequence.
///
/// Retourne null quand il n'y a rien a annoncer (aucun arret `a_livrer`
/// geocode dans le rayon, ou seulement l'arret exclu) -> le bandeau ne
/// s'affiche pas du tout.
ArretsProches? selectArretsProches({
  required double lat,
  required double lng,
  required List<Stop> stops,
  double radiusMeters = ProximityChecker.defaultRadiusMeters,
  int? exclureStopId,
}) {
  final hits = ProximityChecker.findNearby(
    currentLat: lat,
    currentLng: lng,
    stops: stops,
    radiusMeters: radiusMeters,
  );
  // findNearby trie deja du plus proche au plus loin : on garde cet
  // ordre et on se contente de retirer l'arret exclu. Si c'etait le plus
  // proche, on passe donc au suivant de la liste des proches plutot que
  // de tout masquer -- c'est encore une info que l'ecran ne donne nulle
  // part ailleurs.
  final retenus = exclureStopId == null
      ? hits
      : hits.where((h) => h.stop.id != exclureStopId).toList(growable: false);
  if (retenus.isEmpty) return null;
  final premier = retenus.first;
  return ArretsProches(
    plusProche: premier.stop,
    distanceMeters: premier.distanceMeters.round(),
    autresCount: retenus.length - 1,
  );
}

/// Arrets de [tourneeId] a portee immediate de la position courante
/// (carte #285). null = rien a annoncer, le bandeau reste masque.
///
/// Ne calcule RIEN tant que :
/// - la tournee n'est pas `en_cours` : un "tu es a 20 m de X" n'a aucun
///   sens avant le depart ou apres la cloture. Ce garde-fou est teste en
///   premier, donc dans ces cas on ne souscrit meme pas au GPS. La PAUSE,
///   elle, ne masque plus rien (arbitrage du proprietaire) : Noah coupe
///   souvent son dej juste devant un client, et l'info reste vraie -- il
///   decide seul s'il y va tout de suite ;
/// - la position est absente, pas encore recue ou en erreur ;
/// - les arrets de la tournee ne sont pas encore charges.
///
/// Le PROCHAIN arret planifie (`firstAlivrerWithCoords`, la source de
/// verite de `ProchainArretCard`) est exclu du calcul : sa distance est
/// deja affichee dans l'encart juste en dessous. Le bandeau ne parle donc
/// que d'un arret proche HORS SEQUENCE -- le seul cas ou il apprend
/// quelque chose.
///
/// **autoDispose** : l'ecran tournee du jour n'est pas toujours monte, et
/// ce provider ne doit pas maintenir vivant a lui seul le stream GPS (lui
/// aussi autoDispose, cf [currentPositionProvider]).
///
/// Cout : [ProximityChecker.findNearby] est en O(n) sur les arrets, mais
/// `currentPositionProvider` n'emet qu'au-dela de 25 m parcourus (100 m en
/// mode eco, cf `resolveGpsProfile`), pas a chaque metre. Le scan est donc
/// rejoue au pire toutes les quelques secondes sur quelques dizaines
/// d'arrets. Et comme [ArretsProches] a une egalite structurelle avec une
/// distance arrondie au metre, deux fixes qui donneraient le meme bandeau
/// ne declenchent aucun rebuild de l'UI.
final arretsProchesProvider =
    Provider.autoDispose.family<ArretsProches?, int>((ref, tourneeId) {
  final tournee = ref.watch(tourneeByIdProvider(tourneeId)).asData?.value;
  if (tournee == null || tournee.statut != 'en_cours') return null;
  final pos = ref.watch(currentLatLngProvider);
  if (pos == null) return null;
  final stops = ref.watch(stopsByTourneeProvider(tourneeId)).asData?.value;
  if (stops == null || stops.isEmpty) return null;
  return selectArretsProches(
    lat: pos.lat,
    lng: pos.lng,
    stops: stops,
    // Meme selection que `ProchainArretCard` (meme liste, meme ordre :
    // `stopsByTourneeProvider` trie par ordre optimise puis id).
    exclureStopId: firstAlivrerWithCoords(stops)?.id,
  );
});
