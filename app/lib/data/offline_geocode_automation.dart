import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'stops_geocode_retry_service.dart';

/// Automate qui declenche le re-geocodage des arrets en attente
/// (`lat IS NULL`) automatiquement quand la connectivite revient.
///
/// Couvre le scenario typique : Noah ajoute un arret en zone sans 4G
/// (cave, parking sous-terrain, campagne reculee). L'adresse est
/// stockee en base sans coords. Des qu'il sort de la zone et que
/// l'OS notifie un retour wifi/mobile, l'automate appelle
/// [StopsGeocodeRetryService.retryAllPending] en arriere-plan -- pas
/// besoin que Noah ouvre une tournee ni clique un bouton.
///
/// **Cycle de vie** :
/// - Demarre via [start] depuis main.dart (apres le runApp).
/// - Ecoute `Connectivity().onConnectivityChanged` en stream.
/// - Throttle : pas plus d'1 retry par [_minIntervalBetweenRetries].
/// - Stop via [stop] (typiquement par Riverpod onDispose).
class OfflineGeocodeAutomation {
  OfflineGeocodeAutomation({
    required StopsGeocodeRetryService retryService,
    Connectivity? connectivity,
  })  : _retry = retryService,
        _connectivity = connectivity ?? Connectivity();

  final StopsGeocodeRetryService _retry;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Throttle : eviter de re-geocoder en boucle si l'OS spamme des
  /// changements de connectivite (wifi qui clignote dans un train).
  /// 30 s entre 2 tentatives auto, c'est largement suffisant pour
  /// couvrir le cas reel "je rentre chez moi avec 4G qui revient".
  static const _minIntervalBetweenRetries = Duration(seconds: 30);

  DateTime? _lastRetry;
  bool _running = false;

  /// Demarre l'observation. Idempotent : un 2eme appel a [start] ne
  /// duplique pas la souscription.
  void start() {
    if (_subscription != null) return;
    _subscription = _connectivity.onConnectivityChanged.listen(_onChange);
    // Au demarrage, on tente direct si on est deja connecte (cas
    // typique : Noah ouvre l'app le matin avec la wifi maison
    // disponible, sans avoir change de connectivite recemment).
    _maybeRetryNow();
  }

  /// Arrete l'observation. Le service de retry sous-jacent reste
  /// utilisable manuellement.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Appele par le stream `onConnectivityChanged`. Filtre les cas
  /// "still offline" (none/none) et declenche le retry sinon.
  void _onChange(List<ConnectivityResult> results) {
    // results peut contenir plusieurs types (ex: wifi + ethernet sur
    // un Chromebook). On considere "online" des qu'au moins un type
    // n'est pas `none`.
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) return;
    _maybeRetryNow();
  }

  /// Tentative de retry avec garde anti-spam.
  Future<void> _maybeRetryNow() async {
    if (_running) return;
    final now = DateTime.now();
    if (_lastRetry != null &&
        now.difference(_lastRetry!) < _minIntervalBetweenRetries) {
      return;
    }
    _running = true;
    _lastRetry = now;
    try {
      final pending = await _retry.countPending();
      if (pending == 0) return;
      debugPrint(
          '[OfflineGeocode] retry auto sur $pending arret(s) en attente');
      final result = await _retry.retryAllPending();
      debugPrint(
          '[OfflineGeocode] resolved ${result.resolved.length} / unresolved ${result.unresolved.length}');
    } catch (e) {
      debugPrint('[OfflineGeocode] erreur retry: $e');
    } finally {
      _running = false;
    }
  }

  /// Force un retry immediat sans tenir compte du throttle. Sert
  /// notamment a un bouton "Re-essayer maintenant" UI.
  Future<BatchGeocodeResult> forceRetry() async {
    _lastRetry = DateTime.now();
    return _retry.retryAllPending();
  }
}
