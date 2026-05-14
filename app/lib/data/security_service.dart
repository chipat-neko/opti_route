import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'parametres_repository.dart';

/// Service de verrouillage local de l'app (PIN + biometrie optionnelle).
///
/// Phase 1 = tout local, donc pas de "compte utilisateur" : le PIN est
/// juste un cadenas devant les donnees clients (codes interphones,
/// telephones, photos preuves) au cas ou le phone serait vole ou perdu.
///
/// Le PIN en clair n'est JAMAIS stocke. Seul un hash SHA-256 est
/// persiste dans `parametres.pin_hash`. La biometrie passe par
/// `local_auth` qui delegue au TEE Android (StrongBox / TrustZone) :
/// aucune empreinte ne transite par l'app.
class SecurityService {
  SecurityService(this._params);

  final ParametresRepository _params;
  final LocalAuthentication _auth = LocalAuthentication();

  /// Etat actuel : verrou actif ET PIN defini ?
  Future<bool> isLockEnabled() async {
    if (!await _params.getVerrouActif()) return false;
    final hash = await _params.getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  /// Hash SHA-256 d'un PIN (utilise tant a l'enregistrement qu'a la
  /// verification). Pas de sel : le PIN est si court qu'un sel ne
  /// changerait rien face a un attaquant determine. Le vrai bouclier
  /// est le chiffrement disque Android (active par defaut depuis
  /// Android 10) + le screen lock du systeme.
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Active le verrou avec ce PIN. Retourne false si PIN invalide
  /// (longueur, contenu).
  Future<bool> enableLock(String pin) async {
    if (!_isPinValid(pin)) return false;
    await _params.setPinHash(hashPin(pin));
    await _params.setVerrouActif(true);
    return true;
  }

  /// Desactive le verrou ET efface le PIN stocke.
  Future<void> disableLock() async {
    await _params.setVerrouActif(false);
    await _params.clearPinHash();
    await _params.setBiometrieActive(false);
  }

  /// Verifie un PIN soumis a l'ecran de deverrouillage.
  Future<bool> verifyPin(String pin) async {
    final stored = await _params.getPinHash();
    if (stored == null) return false;
    return hashPin(pin) == stored;
  }

  /// Change le PIN apres verification de l'ancien.
  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    if (!_isPinValid(newPin)) return false;
    if (!await verifyPin(oldPin)) return false;
    await _params.setPinHash(hashPin(newPin));
    return true;
  }

  /// Biometrie disponible sur ce device (empreinte / face / iris) ?
  Future<bool> canUseBiometrics() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final available = await _auth.canCheckBiometrics;
      if (!available) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Lance l'authentification biometrique systeme. Retourne true si
  /// l'utilisateur a passe avec succes, false sinon (annule, echec,
  /// indisponible). Ne throw jamais.
  ///
  /// Note migration v2 -> v3 : `AuthenticationOptions` wrapper a saute,
  /// les options passent en params directs. `stickyAuth` est devenu
  /// `persistAcrossBackgrounding`, `useErrorDialogs` a ete retire (les
  /// erreurs systeme sont desormais propagees via `LocalAuthException`
  /// et c'est a l'app de les afficher si besoin). Cote messages,
  /// `biometricHint` est devenu `signInHint`.
  Future<bool> authenticateBiometric() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Deverrouiller opti_route',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'opti_route',
            signInHint: 'Touche le capteur ou montre ton visage',
            cancelButton: 'Utiliser le PIN',
          ),
        ],
      );
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Format du PIN : 4 a 6 chiffres uniquement.
  bool _isPinValid(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(pin);
  }
}
