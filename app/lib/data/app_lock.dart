import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Helpers pin/biometrie (carte #326). Pure fns pour hash + verify.
/// Le stockage du `pinHash` se fait dans la table Parametres (clé
/// `app_lock.pin_hash` + `app_lock.active`) ; le caller s'en occupe.
class AppLock {
  AppLock._();

  static const String keyActive = 'app_lock.active';
  static const String keyPinHash = 'app_lock.pin_hash';

  /// Hash SHA-256 d'un PIN. Pas de salt pour rester simple (4-6
  /// chiffres) — la protection est anti-curieux occasionnel, pas
  /// anti-attaquant sophistiqué.
  static String hashPin(String pin) {
    final normalized = pin.trim();
    if (normalized.isEmpty) return '';
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  /// Verifie un PIN entree contre un hash stocke. Constant-time pour
  /// éviter une timing attack (overkill mais pas cher).
  static bool verify({required String pin, required String storedHash}) {
    final h = hashPin(pin);
    if (h.length != storedHash.length) return false;
    var result = 0;
    for (var i = 0; i < h.length; i++) {
      result |= h.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Validation de format : 4 à 6 chiffres uniquement.
  static bool isValidPin(String pin) {
    final t = pin.trim();
    if (t.length < 4 || t.length > 6) return false;
    return RegExp(r'^\d+$').hasMatch(t);
  }
}
