import 'cloud_sync_service.dart';

/// ════════════════════════════════════════════════════════════════
/// Auto-pull cloud a chaque sign-in (jalon 2.D-1d).
/// ════════════════════════════════════════════════════════════════
///
/// Au cold start / sign-in, ce service est appele via un listener qui
/// watch `cloudUserProvider`. Il delegue tout a
/// [CloudSyncService.pullAllForCurrentUser].
///
/// **Historique** :
/// - 2.D-1b : pull initial une fois par user/telephone via un flag
///   SharedPreferences (`cloud_pull_done_for_<uuid>`). Justifie a
///   l'epoque parce que le pull etait du cloud-wins strict — un
///   re-pull aurait ecrase silencieusement les modifs locales offline.
/// - 2.D-1c : ajout de `updated_at` + last-write-wins fin dans le
///   pull. Re-puller devient safe (les rows locales plus recentes
///   sont preservees).
/// - 2.D-1d (ici) : retrait du flag. On pull a chaque sign-in pour
///   garantir que le device est a jour des modifs faites sur d'autres
///   appareils, sans risquer d'ecraser les modifs locales.
///
/// **Use cases** :
/// - 1er install : auto-pull -> toutes les tournees apparaissent.
/// - Sign-in apres une session sur un 2e device : recupere les modifs
///   faites ailleurs depuis le dernier sign-in.
/// - Re-sign-in apres logout : idem, recupere tout ce qui a change.
class CloudAutoPullService {
  CloudAutoPullService(this._sync);

  final CloudSyncService _sync;

  /// Lance le pull last-write-wins pour le user courant.
  ///
  /// Propage [CloudSyncException] en cas d'erreur reseau / RLS / etc.
  /// Le [CloudPullResult] renvoye expose les compteurs inserted /
  /// updated / skipped par table — l'UI s'en sert pour afficher une
  /// SnackBar resume.
  Future<CloudPullResult> runAutoPullOnSignIn() {
    return _sync.pullAllForCurrentUser();
  }
}
