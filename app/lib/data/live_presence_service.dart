import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';
import 'tournee_realtime_service.dart';

/// ════════════════════════════════════════════════════════════════
/// Push periodique de la position GPS du device courant sur le channel
/// Realtime de la tournee active (jalon 3.C).
/// ════════════════════════════════════════════════════════════════
///
/// Demarre quand l'ecran TourneeDuJourScreen ouvre une tournee partagee
/// (cloudId != null) qui est `en_cours`. Le timer push la position tous
/// les 30s via TourneeRealtimeService.broadcastMyPosition. Le chef voit
/// le marker live se deplacer sur la carte.
///
/// **Tradeoff fréquence** :
/// - 30s = bon compromis batterie / fraicheur (vs Waze qui push toutes
///   les ~5s mais a un autre cas d'usage avec son propre GPS dedie)
/// - Chaque push = ~200 bytes via WebSocket Supabase = negligeable
///
/// **Permission GPS** : demande au demarrage via [LocationService.
/// ensurePermission]. Si refuse, log + no-op.
///
/// **Lifecycle** : stop() doit etre appele quand l'ecran ferme OU
/// quand la tournee n'est plus active (statut != en_cours).
class LivePresenceService {
  LivePresenceService(this._realtime);

  final TourneeRealtimeService _realtime;
  Timer? _ticker;
  StreamSubscription<Position>? _positionSub;
  Position? _lastKnownPosition;

  /// Demarre le push de position. Idempotent : si deja actif sur la
  /// meme tournee on garde, sinon on stop + restart.
  Future<void> start() async {
    if (_ticker != null) return;
    try {
      final hasPerm = await LocationService.ensurePermission();
      if (!hasPerm) {
        debugPrint('[LivePresenceService] permission GPS refusee, skip');
        return;
      }
    } on Object catch (e) {
      debugPrint('[LivePresenceService] permission check fail : $e');
      return;
    }
    // Stream de positions a forte distance filter (50m) : on push
    // seulement quand le livreur s'est vraiment deplace. Sinon le
    // ticker 30s relance le dernier push (utile si stationnaire pour
    // confirmer que le livreur est toujours la / sa derniere position
    // connue).
    _positionSub = LocationService.positionStream(distanceFilterMeters: 50)
        .listen((pos) {
      _lastKnownPosition = pos;
      // Push immediat aussi sur deplacement (pas que sur tick 30s).
      _pushIfPossible();
    });
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _pushIfPossible();
    });
  }

  void _pushIfPossible() {
    final pos = _lastKnownPosition;
    if (pos == null) return;
    _realtime.broadcastMyPosition(
      lat: pos.latitude,
      lng: pos.longitude,
      accuracyMeters: pos.accuracy,
    );
  }

  /// Arrete le push de position. Idempotent.
  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _positionSub?.cancel();
    _positionSub = null;
    _lastKnownPosition = null;
  }

  bool get isActive => _ticker != null;
}
