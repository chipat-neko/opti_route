import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tournee_realtime_service.dart' show LivePosition;

/// Fraicheur d'une position live (carte #174) : sert a colorer le
/// marker du chauffeur sur la carte chef.
enum LiveFreshness { fresh, recent, stale }

/// Seuils de fraicheur (memes conventions que la carte mobile).
const Duration kFreshThreshold = Duration(seconds: 60);
const Duration kRecentThreshold = Duration(seconds: 300);

/// Fonction PURE : niveau de fraicheur a partir de l'age de la position.
/// < 60s = fresh (emerald), < 300s = recent (amber), sinon stale (faded).
LiveFreshness freshnessOf(Duration age) {
  if (age < kFreshThreshold) return LiveFreshness.fresh;
  if (age < kRecentThreshold) return LiveFreshness.recent;
  return LiveFreshness.stale;
}

/// ════════════════════════════════════════════════════════════════
/// Presence live multi-tournees pour le logiciel chef (carte #174).
/// ════════════════════════════════════════════════════════════════
///
/// S'abonne aux channels Realtime `tournee:<cloudId>` de TOUTES les
/// tournees d'equipe en cours et agrege les broadcasts `position` des
/// chauffeurs en une seule map `userCloudId -> LivePosition`. Sert au
/// `ChefLiveMapPanel` pour afficher un marker mouvant par chauffeur.
///
/// Difference avec [TourneeRealtimeService] (mono-canal, mobile) :
/// - multi-canaux (N tournees observees simultanement)
/// - **observateur seul** : on ne `track()` PAS notre presence et on ne
///   broadcast PAS de position (le chef regarde, il ne livre pas)
/// - on n'ecoute que l'event `position` (les changements de stops
///   arrivent deja via la sync cloud normale)
///
/// Non-teste en automatique (Realtime multi-devices) : la logique pure
/// [freshnessOf] est testee ; le multiplexage est valide sur device.
class ChefPresenceService {
  ChefPresenceService();

  final Map<String, LivePosition> _positions = {};
  final _controller =
      StreamController<Map<String, LivePosition>>.broadcast();

  /// channels actifs, keyes par tourneeCloudId.
  final Map<String, RealtimeChannel> _channels = {};

  Stream<Map<String, LivePosition>> get positionsStream =>
      _controller.stream;
  Map<String, LivePosition> get positions => Map.unmodifiable(_positions);

  /// Synchronise les abonnements avec l'ensemble [tourneeCloudIds] des
  /// tournees a observer : abonne les nouvelles, desabonne celles qui ne
  /// sont plus dans l'ensemble. Idempotent (no-op si deja aligne).
  Future<void> sync(
    SupabaseClient client,
    Set<String> tourneeCloudIds,
  ) async {
    // Desabonne ce qui n'est plus voulu.
    final toRemove =
        _channels.keys.where((id) => !tourneeCloudIds.contains(id)).toList();
    for (final id in toRemove) {
      await _unsubscribeOne(id);
    }
    // Abonne les nouveaux.
    for (final id in tourneeCloudIds) {
      if (_channels.containsKey(id)) continue;
      _subscribeOne(client, id);
    }
  }

  void _subscribeOne(SupabaseClient client, String tourneeCloudId) {
    try {
      final channel = client.channel('tournee:$tourneeCloudId');
      channel
          .onBroadcast(
            event: 'position',
            callback: (payload) => _handlePosition(payload),
          )
          .subscribe();
      _channels[tourneeCloudId] = channel;
    } on Object catch (e) {
      debugPrint('[ChefPresenceService] subscribe $tourneeCloudId fail : $e');
    }
  }

  Future<void> _unsubscribeOne(String tourneeCloudId) async {
    final channel = _channels.remove(tourneeCloudId);
    if (channel == null) return;
    try {
      await channel.unsubscribe();
    } on Object catch (e) {
      debugPrint('[ChefPresenceService] unsubscribe fail : $e');
    }
  }

  void _handlePosition(Map<String, dynamic> payload) {
    try {
      final userId = payload['user_id'] as String?;
      final lat = (payload['lat'] as num?)?.toDouble();
      final lng = (payload['lng'] as num?)?.toDouble();
      if (userId == null || lat == null || lng == null) return;
      final accuracy = (payload['accuracy'] as num?)?.toDouble() ?? 0;
      final ts = payload['ts'] is String
          ? DateTime.parse(payload['ts'] as String).toLocal()
          : DateTime.now();
      _positions[userId] = LivePosition(
        userCloudId: userId,
        lat: lat,
        lng: lng,
        accuracyMeters: accuracy,
        timestamp: ts,
      );
      _controller.add(Map.unmodifiable(_positions));
    } on Object catch (e, st) {
      debugPrint('[ChefPresenceService] position handler fail : $e\n$st');
    }
  }

  /// Desabonne tout + vide. A appeler quand le panneau chef se ferme.
  Future<void> stop() async {
    for (final id in _channels.keys.toList()) {
      await _unsubscribeOne(id);
    }
    _positions.clear();
    _controller.add(const {});
  }

  void dispose() {
    _controller.close();
  }
}
