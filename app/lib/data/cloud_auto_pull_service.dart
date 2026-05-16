import 'cloud_sync_service.dart';
import 'parametres_repository.dart';

/// ════════════════════════════════════════════════════════════════
/// Pull initial automatique au 1er sign-in d'un user (jalon 2.D-1b).
/// ════════════════════════════════════════════════════════════════
///
/// Au cold start / sign-in, ce service est appele via un listener qui
/// watch [cloudUserProvider]. Il check un flag par-user dans Parametres
/// (`cloud_pull_done_for_<uuid>`) :
/// - Si le pull initial a deja ete fait pour ce user sur ce telephone
///   -> no-op (on ne re-pull pas automatiquement aux sign-ins suivants
///   pour eviter d'ecraser silencieusement des modifs locales offline).
/// - Sinon -> lance [CloudSyncService.pullAllForCurrentUser] et marque
///   le flag a true en cas de succes.
///
/// **Pourquoi 1 fois uniquement** : sans colonne `updated_at` cote
/// Drift (sera ajoutee au 2.D-1b.2), on n'a pas de last-write-wins
/// fin. Re-pull = cloud-wins strict = ecrasement des modifs locales.
/// Trop dangereux pour l'auto-trigger. Le user peut toujours forcer
/// un re-pull via le bouton "Re-telecharger depuis le cloud" (avec
/// dialog warning, jalon 2.D-1a).
///
/// **Use case principal** : install l'app sur un 2e telephone, sign-in
/// avec le meme email -> auto-pull -> toutes les tournees apparaissent
/// sans intervention manuelle. Magic moment pour Noah / les futurs
/// chefs d'equipe.
class CloudAutoPullService {
  CloudAutoPullService(this._sync, this._params);

  final CloudSyncService _sync;
  final ParametresRepository _params;

  /// Lance le pull si jamais fait pour [userId], no-op sinon.
  /// Marque le flag `cloud_pull_done_for_<userId>` a true en cas de
  /// succes — ne le marque PAS en cas d'erreur (pour permettre un
  /// retry au prochain cold start).
  ///
  /// Retourne le [CloudPullResult] si pull effectue, null sinon.
  /// Propage [CloudSyncException] en cas d'erreur reseau / RLS / etc.
  Future<CloudPullResult?> maybeRunInitialPull(String userId) async {
    final done = await _params.isCloudPullDoneFor(userId);
    if (done) return null;
    final result = await _sync.pullAllForCurrentUser();
    await _params.setCloudPullDoneFor(userId);
    return result;
  }
}
