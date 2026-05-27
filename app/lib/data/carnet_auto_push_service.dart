import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import 'cloud_sync_service.dart';
import 'database.dart';
import 'supabase_service.dart';

/// ════════════════════════════════════════════════════════════════
/// Auto-push du carnet vers Supabase (carte Trello #57 V2).
/// ════════════════════════════════════════════════════════════════
///
/// Watche la table `saved_destinations` en continu via Drift et push
/// silencieux vers Supabase 5 secondes apres le dernier changement
/// (debounce). Couvre TOUS les sites de modification du carnet (et
/// pas juste les 3 ecrans wires en V1) :
///   - `upsertFromValidatedStop` (chaque livraison qui matche un nouveau
///     client genere une entree carnet auto-creee)
///   - Carnet backfill au demarrage
///   - Import vCard / CSV
///   - Toggles favori / color tag depuis l'UI (deja wires en V1, mais
///     un double push silencieux fait pas de mal)
///
/// **Strategie de detection** : on garde un snapshot `Map<int, DateTime>`
/// (localId -> updatedAt vu au dernier tick). A chaque emit du watch
/// Drift, on identifie les rows dont `updatedAt > snapshot[id]` (ou
/// absent du snapshot = nouvelle row). On push uniquement ces rows.
///
/// **Debounce 5s** : pendant un import vCard, on enchaine N inserts.
/// On groupe les push pour ne pas faire N round-trips reseau.
///
/// **Silencieux** : pas de SnackBar success/error. Un echec (offline,
/// non auth, RLS) est swallowed -- le pull global retroactif rattrapera.
///
/// **Pre-requis** : user connecte au cloud. Re-check a chaque tick (si
/// le user se deconnecte, on garde le snapshot updated mais on ne push
/// pas). Au prochain sign-in + pull global, tout sera resync.
///
/// **Pas de garantie d'ordre** : si une row est modifiee 2x avant le
/// debounce, seul le dernier etat est push (le snapshot voit la 2e
/// modif, jamais la 1ere). C'est OK : l'etat final est ce qui compte.
///
/// **Lifecycle** : [start] au sign-in (callback du cloudUserProvider),
/// [stop] au sign-out. Idempotent : start sur un service deja actif
/// est no-op.
class CarnetAutoPushService {
  CarnetAutoPushService(this._sync, this._db, this._supabase);

  final CloudSyncService _sync;
  final AppDatabase _db;
  final SupabaseService _supabase;

  StreamSubscription<List<SavedDestination>>? _sub;
  Timer? _debounce;

  /// Snapshot des `updatedAt` connus, indexe par id local. Rempli au
  /// premier emit (qui sert de baseline -- on ne re-push pas tout le
  /// carnet, c'est deja fait par `pullAllForCurrentUser`).
  final Map<int, DateTime> _knownUpdatedAt = {};

  /// IDs en attente de push (accumules par les emits successifs jusqu'au
  /// fire du debounce). Set pour dedup si une meme row est modifiee
  /// plusieurs fois pendant le debounce.
  final Set<int> _pendingIds = {};

  bool _initialized = false;

  /// Demarre le watch. Idempotent : re-appel sur service deja actif
  /// est no-op.
  void start() {
    if (_sub != null) return;
    _sub = _db.select(_db.savedDestinations).watch().listen(_onTick);
  }

  /// Arrete le watch + cancel le debounce en cours. Idempotent.
  /// Le snapshot et les ids en attente sont conserves (utile si on
  /// `start` a nouveau apres un sign-out / sign-in court).
  void stop() {
    _sub?.cancel();
    _sub = null;
    _debounce?.cancel();
    _debounce = null;
  }

  /// Force un push immediat des ids en attente, court-circuite le
  /// debounce. Sert au cas "le user vient de faire une action critique
  /// et l'app va peut-etre etre fermee dans la foulee". Idempotent.
  Future<void> flush() async {
    if (_debounce == null && _pendingIds.isEmpty) return;
    _debounce?.cancel();
    _debounce = null;
    await _pushPending();
  }

  void _onTick(List<SavedDestination> rows) {
    // Premier emit : baseline. On enregistre l'etat connu et on ne push
    // rien (le pull global au sign-in s'occupe deja du retro-push).
    if (!_initialized) {
      for (final r in rows) {
        _knownUpdatedAt[r.id] = r.updatedAt;
      }
      _initialized = true;
      return;
    }

    // Identifie les rows nouvelles ou modifiees depuis le dernier tick.
    for (final r in rows) {
      final last = _knownUpdatedAt[r.id];
      if (last == null || r.updatedAt.isAfter(last)) {
        _pendingIds.add(r.id);
        _knownUpdatedAt[r.id] = r.updatedAt;
      }
    }

    if (_pendingIds.isEmpty) return;
    // Replanifie un push : annule le timer precedent si pas encore tire.
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), _pushPending);
  }

  Future<void> _pushPending() async {
    if (_pendingIds.isEmpty) return;
    if (_supabase.currentUser == null) {
      // Pas connecte : on garde les ids en attente, ils repartiront au
      // prochain tick OU au prochain sign-in + pull global.
      return;
    }
    // Snapshot des ids puis clear : si un nouveau push arrive pendant
    // qu'on traite le batch, il sera capture par le prochain tick.
    final ids = _pendingIds.toList();
    _pendingIds.clear();
    for (final id in ids) {
      try {
        await _sync.pushSavedDestination(id);
      } on Object catch (e) {
        debugPrint('[CarnetAutoPushService] Push id=$id echec : $e');
        // No-op : on re-tentera quand cette row sera modifiee a nouveau,
        // OU au prochain pull global qui re-push tout retroactivement.
      }
    }
  }
}
