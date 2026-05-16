import 'dart:async';

import 'cloud_sync_service.dart';
import 'database.dart';
import 'supabase_service.dart';

/// ════════════════════════════════════════════════════════════════
/// Auto-push de la tournee active vers le cloud (jalon 2.D-2).
/// ════════════════════════════════════════════════════════════════
///
/// Watche en continu la tournee actuellement ouverte (row Tournees +
/// liste de ses Stops) et declenche un push silencieux vers Supabase
/// 5 secondes apres le dernier changement (debounce). Permet a Noah
/// de ne plus avoir a cliquer manuellement "Pousser au cloud" apres
/// chaque livraison validee — c'est transparent.
///
/// **Quand le service est-il actif ?**
/// - [TourneeDuJourScreen] appelle [watchTournee] dans `initState`
///   avec l'id de la tournee affichee
/// - L'ecran appelle [stop] dans `dispose` (quitter l'ecran arrete
///   le watch)
/// - Re-ouvrir l'ecran reactive le watch sur la nouvelle tournee
///
/// **Debounce 5s** : pendant la livraison Noah enchaine souvent des
/// updates (marquer livre + photo preuve + commentaire). On groupe
/// tout ca en 1 seul push, plutot que d'en faire 3 d'affilee.
///
/// **Silencieux** : pas de SnackBar success (trop de bruit). Erreurs
/// silencieuses aussi : si le push echoue (offline, RLS, etc.), on
/// re-tentera au prochain change. Le user a toujours le push manuel
/// via le menu Plus pour les cas explicites.
///
/// **Pre-requis** : user connecte au cloud (`SupabaseService.currentUser
/// != null`). Si pas connecte, [watchTournee] est appele quand meme
/// mais les push silencieux sont no-op. Re-check a chaque tick.
///
/// **Pas de garantie d'ordre** : si Noah modifie 2 tournees differentes
/// rapidement (en quittant/reouvrant), seul le dernier watch est actif.
/// C'est OK : les autres tournees peuvent etre push via le bouton
/// manuel (jalon 2.B/2.C) ou attendre la prochaine ouverture.
class CloudAutoPushService {
  CloudAutoPushService(this._sync, this._db, this._supabase);

  final CloudSyncService _sync;
  final AppDatabase _db;
  final SupabaseService _supabase;

  /// Subscriptions actives (row tournee + stream stops). Cancelees
  /// dans [stop] et avant un nouvel [watchTournee].
  StreamSubscription<dynamic>? _tourneeSub;
  StreamSubscription<dynamic>? _stopsSub;
  Timer? _debounce;
  int? _currentTourneeId;

  /// Date jusqu'a laquelle l'auto-push doit etre supprime, set par
  /// [suppress]. Sert a casser la boucle Realtime ↔ auto-push : quand
  /// le Realtime applique un event dans Drift local, l'auto-push voit
  /// un "changement" et veut re-push -> mais c'est exactement ce qu'on
  /// vient de recevoir, donc re-push = boucle. [suppress] est appele
  /// par le TourneeRealtimeService apres chaque write.
  DateTime? _suppressUntil;

  /// Demarre le watch sur [tourneeId]. Si un watch est deja actif
  /// (sur la meme tournee ou une autre), il est remplace.
  ///
  /// Le 1er emit du Stream se fait immediatement avec l'etat courant
  /// — on debounce quand meme pour ne pas push juste apres l'ouverture
  /// (le user n'a rien modifie).
  void watchTournee(int tourneeId) {
    if (_currentTourneeId == tourneeId &&
        _tourneeSub != null &&
        _stopsSub != null) {
      // Deja en cours sur cette tournee, no-op.
      return;
    }
    stop();
    _currentTourneeId = tourneeId;
    _tourneeSub = (_db.select(_db.tournees)
          ..where((t) => t.id.equals(tourneeId)))
        .watchSingleOrNull()
        .listen((_) => _scheduleDebouncedPush(tourneeId));
    _stopsSub = (_db.select(_db.stops)
          ..where((s) => s.tourneeId.equals(tourneeId)))
        .watch()
        .listen((_) => _scheduleDebouncedPush(tourneeId));
  }

  /// Arrete le watch et le timer en cours. Idempotent — peut etre
  /// appele meme si rien n'est actif.
  void stop() {
    _tourneeSub?.cancel();
    _stopsSub?.cancel();
    _debounce?.cancel();
    _tourneeSub = null;
    _stopsSub = null;
    _debounce = null;
    _currentTourneeId = null;
  }

  /// Suppresse les auto-push pendant [duration]. Appele par le
  /// TourneeRealtimeService apres avoir applique un event Postgres
  /// Changes en local : sans suppression, le watch Drift verrait
  /// le changement comme une modif user et re-push -> boucle infinie
  /// avec le device source de l'event (qui re-recevrait, re-applique,
  /// re-push, ad libitum). 10s suffit largement (debounce push = 5s).
  void suppress(Duration duration) {
    _suppressUntil = DateTime.now().add(duration);
  }

  /// Replanifie un push debounced. Annule le timer precedent (si
  /// pas encore tire) et en demarre un nouveau de 5 secondes.
  void _scheduleDebouncedPush(int tourneeId) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 5), () async {
      // Re-check juste avant le push : la tournee peut avoir ete
      // changee (autre tournee ouverte) ou le user peut s'etre
      // deconnecte entre le schedule et l'expiration du timer.
      if (_currentTourneeId != tourneeId) return;
      if (_supabase.currentUser == null) return;
      // Skip si on est dans la fenetre de suppression (write Realtime
      // recent). Cf [suppress].
      final until = _suppressUntil;
      if (until != null && DateTime.now().isBefore(until)) return;
      try {
        await _sync.pushTournee(tourneeId);
      } on Object {
        // Silent : on re-tentera au prochain change. Pas de SnackBar.
        // Eventuellement, on pourra ajouter un Provider d'etat
        // "derniere sync echouee" pour afficher un indicateur subtil
        // dans l'UI, mais pas dans ce sous-jalon.
      }
    });
  }
}
