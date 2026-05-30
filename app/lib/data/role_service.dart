import 'app_role.dart';
import 'parametres_repository.dart';

/// Service de lecture/écriture du rôle courant.
///
/// Sources, dans l'ordre de priorité :
/// 1. **Override serveur** (Supabase user metadata `role: 'chef'`) si
///    le caller le fournit. Force `chef` quel que soit le toggle local.
/// 2. **Toggle local** dans Parametres (`mode_chef_equipe`, existant
///    depuis longtemps mais sous-utilisé).
/// 3. **Default** : `chauffeur`.
class RoleService {
  RoleService(this._parametres);

  final ParametresRepository _parametres;

  /// Rôle stocké localement (toggle Paramètres).
  Future<AppRole> readLocalRole() async {
    final isChef = await _parametres.getModeChef();
    return isChef ? AppRole.chef : AppRole.chauffeur;
  }

  /// Met à jour le toggle local.
  Future<void> writeLocalRole(AppRole role) {
    return _parametres.setModeChef(role == AppRole.chef);
  }

  /// Stream du rôle local (UI réactive pour le toggle).
  Stream<AppRole> watchLocalRole() {
    return _parametres
        .watchModeChef()
        .map((v) => v ? AppRole.chef : AppRole.chauffeur);
  }

  /// Résolution finale : override serveur > local > default.
  ///
  /// [serverRoleRaw] : `user.app_metadata['role']` Supabase (null si
  /// pas connecté). Si serveur dit 'chef' → on force chef. Sinon on
  /// suit le toggle local. L'override serveur PROMEUT seulement
  /// (jamais rétrograde) — un user tagué chauffeur côté serveur peut
  /// quand même activer le mode chef en local s'il y a accès (confort
  /// UI, pas un vrai contrôle d'accès).
  Future<AppRole> resolveCurrentRole({String? serverRoleRaw}) async {
    if (serverRoleRaw != null && _normalize(serverRoleRaw) == AppRole.chef) {
      return AppRole.chef;
    }
    return readLocalRole();
  }

  static AppRole _normalize(String raw) {
    final t = raw.toLowerCase().trim();
    if (t == 'chef' || t == 'manager' || t == 'admin') return AppRole.chef;
    return AppRole.chauffeur;
  }
}
