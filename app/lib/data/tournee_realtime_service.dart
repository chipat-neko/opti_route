import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_auto_push_service.dart';
import 'database.dart';

/// Position GPS live d'un coequipier (jalon 3.C). Recue via Realtime
/// Broadcast sur le channel `tournee:<uuid>`. Ephemere — pas stockee
/// en DB, juste maintenue en memoire le temps de la session.
class LivePosition {
  const LivePosition({
    required this.userCloudId,
    required this.lat,
    required this.lng,
    required this.accuracyMeters,
    required this.timestamp,
  });

  final String userCloudId;
  final double lat;
  final double lng;
  final double accuracyMeters;
  final DateTime timestamp;
}

/// ════════════════════════════════════════════════════════════════
/// Realtime live des stops d'une tournée partagée (jalon 3.A).
/// ════════════════════════════════════════════════════════════════
///
/// Quand Noah ouvre une tournée partagée, ce service subscribe le
/// channel Supabase `tournee:<cloudUuid>` et écoute les events
/// Postgres Changes sur la table `stops` filtrés par `tournee_id`. À
/// chaque event (INSERT / UPDATE / DELETE), on merge dans la DB Drift
/// locale → la liste des stops à l'écran se met à jour en quelques
/// secondes sans pull manuel.
///
/// **Pourquoi pas du polling** : un fetch toutes les 5s coûterait des
/// kB inutiles 99% du temps (rien ne change). Le push WebSocket de
/// Realtime est gratuit dans la quota Supabase free tier (jusqu'à 2
/// millions de messages/mois) et donne une latence < 1s.
///
/// **Limitation MVP** : un seul channel actif à la fois. Si Noah passe
/// de tournée partagée A à B, on désabonne A et abonne B. Pas de
/// pooling de channels pour le moment (sera utile si plusieurs
/// tournées partagées sont watchées simultanément en background).
///
/// **Auto-reconnect** : géré par supabase_flutter sous le capot — si
/// le réseau coupe, le client tente de re-subscribe automatiquement
/// quand il revient. On ne fait rien de spécial côté app.
class TourneeRealtimeService {
  TourneeRealtimeService(this._db, this._autoPush);

  final AppDatabase _db;
  /// Auto-push service du device — sert a suppress les push apres
  /// chaque write Realtime, pour casser la boucle ping-pong entre
  /// 2 devices d'une tournee partagee. Cf [_handleStopChange].
  final CloudAutoPushService _autoPush;
  RealtimeChannel? _activeChannel;
  String? _activeTourneeCloudId;
  String? _myUserCloudId;

  /// Jalon 3.C : positions GPS live des AUTRES membres de la tournee
  /// (le user courant est exclu). Maintenu en memoire via le handler
  /// onBroadcast. Expose via [othersPositionsStream].
  final Map<String, LivePosition> _othersPositions = {};
  final _othersController =
      StreamController<Map<String, LivePosition>>.broadcast();

  /// Stream de la map userId -> LivePosition des autres members.
  /// Sert au CarteScreen pour afficher les markers live du livreur.
  Stream<Map<String, LivePosition>> get othersPositionsStream =>
      _othersController.stream;

  /// Snapshot synchrone de la map (utile au 1er build avant que le
  /// StreamBuilder ait recu une emission).
  Map<String, LivePosition> get othersPositions =>
      Map.unmodifiable(_othersPositions);

  /// True si on est déjà subscribed à cette tournée.
  bool isSubscribedTo(String tourneeCloudId) =>
      _activeTourneeCloudId == tourneeCloudId && _activeChannel != null;

  /// Subscribe au channel `tournee:<cloudId>`. Désabonne le précédent
  /// si différent. No-op si déjà subscribed à ce même cloudId.
  ///
  /// `client` est passé en paramètre pour faciliter les tests, mais en
  /// prod c'est `Supabase.instance.client`.
  Future<void> subscribeTournee(
    SupabaseClient client,
    String tourneeCloudId,
  ) async {
    if (isSubscribedTo(tourneeCloudId)) return;
    await unsubscribe();
    _myUserCloudId = client.auth.currentUser?.id;
    final channel = client.channel('tournee:$tourneeCloudId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stops',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournee_id',
            value: tourneeCloudId,
          ),
          callback: (payload) {
            _handleStopChange(payload);
          },
        )
        // Jalon 3.C : broadcast event "position" pour la geoloc live.
        // Pas de filter cote serveur (broadcast Realtime ne supporte
        // pas les filters comme Postgres Changes) — on filtre cote
        // client dans le handler (skip si payload.user_id == moi).
        .onBroadcast(
          event: 'position',
          callback: (payload) {
            _handlePositionBroadcast(payload);
          },
        )
        .subscribe();
    _activeChannel = channel;
    _activeTourneeCloudId = tourneeCloudId;
  }

  /// Jalon 3.C : push la position GPS du device courant sur le channel
  /// actif. No-op si pas abonne (= pas en train de regarder une
  /// tournee partagee). Best-effort : silencieux en cas d'echec.
  Future<void> broadcastMyPosition({
    required double lat,
    required double lng,
    required double accuracyMeters,
  }) async {
    final channel = _activeChannel;
    final myUserId = _myUserCloudId;
    if (channel == null || myUserId == null) return;
    try {
      await channel.sendBroadcastMessage(
        event: 'position',
        payload: {
          'user_id': myUserId,
          'lat': lat,
          'lng': lng,
          'accuracy': accuracyMeters,
          'ts': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } on Object catch (e) {
      debugPrint('[TourneeRealtimeService] broadcastMyPosition fail : $e');
    }
  }

  void _handlePositionBroadcast(Map<String, dynamic> payload) {
    try {
      final userId = payload['user_id'] as String?;
      if (userId == null) return;
      // Skip nos propres positions (echo).
      if (userId == _myUserCloudId) return;
      final lat = (payload['lat'] as num?)?.toDouble();
      final lng = (payload['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final accuracy = (payload['accuracy'] as num?)?.toDouble() ?? 0;
      final ts = payload['ts'] is String
          ? DateTime.parse(payload['ts'] as String).toLocal()
          : DateTime.now();
      _othersPositions[userId] = LivePosition(
        userCloudId: userId,
        lat: lat,
        lng: lng,
        accuracyMeters: accuracy,
        timestamp: ts,
      );
      _othersController.add(Map.unmodifiable(_othersPositions));
    } on Object catch (e, st) {
      debugPrint('[TourneeRealtimeService] position handler fail : $e\n$st');
    }
  }

  /// Désabonne le channel actif. No-op si rien d'actif.
  Future<void> unsubscribe() async {
    final channel = _activeChannel;
    if (channel == null) return;
    try {
      await channel.unsubscribe();
    } on Object catch (e) {
      debugPrint('[TourneeRealtimeService] unsubscribe failed : $e');
    }
    _activeChannel = null;
    _activeTourneeCloudId = null;
    _myUserCloudId = null;
    _othersPositions.clear();
    _othersController.add(const {});
  }

  /// Handler Postgres Changes. Merge l'event dans Drift en UPSERT
  /// (INSERT si pas connu localement, UPDATE sinon, DELETE supprime).
  ///
  /// Best-effort : si l'event arrive avec des champs manquants ou si
  /// la tournée parente n'est pas en local (rare : devrait être pull
  /// avant qu'on subscribe), on log et on skip. Pas de throw — un
  /// crash dans le handler tuerait le channel.
  Future<void> _handleStopChange(PostgresChangePayload payload) async {
    try {
      // Suppress l'auto-push AVANT le write Drift : si on suppresse
      // apres, le watch Drift de auto-push aurait deja fire et
      // schedule un push avant qu'on suppress (race). 10s = largement
      // au-dessus du debounce 5s + drift transactionnel. Sans cette
      // suppression : ping-pong infini avec le device source de
      // l'event (il re-recoit le push, re-applique, re-push, etc).
      _autoPush.suppress(const Duration(seconds: 10));
      switch (payload.eventType) {
        case PostgresChangeEvent.delete:
          await _handleDelete(payload.oldRecord);
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          await _handleUpsert(payload.newRecord);
        case PostgresChangeEvent.all:
          // Ne devrait pas arriver (event subscription, pas filter).
          break;
      }
    } on Object catch (e, st) {
      debugPrint('[TourneeRealtimeService] handler failed : $e\n$st');
    }
  }

  Future<void> _handleDelete(Map<String, dynamic> oldRecord) async {
    final cloudId = oldRecord['id'] as String?;
    if (cloudId == null) return;
    await (_db.delete(_db.stops)..where((s) => s.cloudId.equals(cloudId)))
        .go();
  }

  Future<void> _handleUpsert(Map<String, dynamic> row) async {
    final cloudId = row['id'] as String?;
    final tourneeCloudId = row['tournee_id'] as String?;
    if (cloudId == null || tourneeCloudId == null) return;

    // Résoud la tournée parente en local. Si pas trouvée, on skip — la
    // tournée doit être pulled séparément avant que les events stops
    // puissent être appliqués.
    final tourneeLocalId = await (_db.select(_db.tournees)
          ..where((t) => t.cloudId.equals(tourneeCloudId)))
        .map((t) => t.id)
        .getSingleOrNull();
    if (tourneeLocalId == null) {
      debugPrint(
          '[TourneeRealtimeService] tournee parente non trouvee, skip stop');
      return;
    }

    final coequipierCloudId = row['coequipier_id'] as String?;
    final coequipierLocalId = coequipierCloudId == null
        ? null
        : await (_db.select(_db.coequipiers)
              ..where((c) => c.cloudId.equals(coequipierCloudId)))
            .map((c) => c.id)
            .getSingleOrNull();

    final updatedAt = row['updated_at'] is String
        ? DateTime.parse(row['updated_at'] as String).toLocal()
        : DateTime.now();

    final companion = StopsCompanion(
      tourneeId: Value(tourneeLocalId),
      adresseBrute: Value(row['adresse_brute'] as String),
      adresseNormalisee: Value(row['adresse_normalisee'] as String?),
      lat: Value((row['lat'] as num?)?.toDouble()),
      lng: Value((row['lng'] as num?)?.toDouble()),
      nbColis: Value(row['nb_colis'] as int? ?? 1),
      priorite: Value(row['priorite'] as String? ?? 'flexible'),
      fenetreDebut: Value(row['fenetre_debut'] as String?),
      fenetreFin: Value(row['fenetre_fin'] as String?),
      dureeArretMin: Value(row['duree_arret_min'] as int? ?? 3),
      notes: Value(row['notes'] as String?),
      nomClient: Value(row['nom_client'] as String?),
      statutLivraison:
          Value(row['statut_livraison'] as String? ?? 'a_livrer'),
      raisonEchec: Value(row['raison_echec'] as String?),
      livreLat: Value((row['livre_lat'] as num?)?.toDouble()),
      livreLng: Value((row['livre_lng'] as num?)?.toDouble()),
      livreLe: Value(row['livre_le'] == null
          ? null
          : DateTime.parse(row['livre_le'] as String)),
      ordreOptimise: Value(row['ordre_optimise'] as int?),
      ordrePriorite: Value(row['ordre_priorite'] as int?),
      preuvePhotoPath: Value(row['preuve_photo_path'] as String?),
      cloudPhotoPath: Value(row['cloud_photo_path'] as String?),
      coequipierId: Value(coequipierLocalId),
      creeLe: Value(row['cree_le'] is String
          ? DateTime.parse(row['cree_le'] as String)
          : DateTime.now()),
      cloudId: Value(cloudId),
      updatedAt: Value(updatedAt),
    );

    final existing = await (_db.select(_db.stops)
          ..where((s) => s.cloudId.equals(cloudId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.stops).insert(companion);
    } else {
      await (_db.update(_db.stops)..where((s) => s.id.equals(existing.id)))
          .write(companion);
    }
  }
}
