import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:light/light.dart';

/// Service qui ecoute le capteur de luminosite ambiante du telephone
/// et expose un stream `ThemeMode` (light/dark) calcule selon un seuil
/// en lux + un debounce pour eviter le flickering (carte Trello #95).
///
/// Cas d'usage :
/// - Noah conduit la nuit ou passe sous un tunnel -> l'ecran passe
///   automatiquement en mode sombre (anti-eblouissement, moins de
///   fatigue oculaire).
/// - Sort en plein soleil -> mode clair auto (meilleur contraste).
///
/// Limitations volontaires :
/// - **Android only** : iOS n'expose pas le capteur ambient light cote
///   public. Sur iOS / desktop / web, [stream] emet immediatement OFF
///   (= ThemeMode.system) et l'UI sait masquer le toggle.
/// - **Debounce 5s** : evite le flickering quand on passe rapidement
///   sous un pont, derriere un camion, dans un ascenseur. La bascule
///   ne se declenche que si la luminosite reste de l'autre cote du
///   seuil >= 5 sec.
/// - **Hysteresis +/- 10 lux** autour du seuil : evite le tremblement
///   pour les valeurs proches du seuil exact (ex: 48-52 lux qui
///   oscillent).
class AmbientLightService {
  AmbientLightService({
    int seuilLux = 50,
    Duration debounce = const Duration(seconds: 5),
    int hysteresisLux = 10,
    @visibleForTesting Stream<int>? overrideStream,
  })  : _seuilLux = seuilLux,
        _debounce = debounce,
        _hysteresisLux = hysteresisLux,
        _overrideStream = overrideStream;

  final int _seuilLux;
  final Duration _debounce;
  final int _hysteresisLux;
  final Stream<int>? _overrideStream;

  /// Vrai si la plateforme courante a un capteur ambient light
  /// utilisable (Android uniquement pour le moment). Sert au toggle UI
  /// pour rester desactive sur iOS / desktop / web.
  static bool get isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Stream brut du capteur (en lux). Expose tel quel pour faciliter
  /// les tests + une UI eventuelle "valeur actuelle de luminosite".
  /// Renvoie un stream vide sur les plateformes non supportees.
  Stream<int> rawLuxStream() {
    if (_overrideStream != null) return _overrideStream;
    if (!isSupported) return const Stream<int>.empty();
    return Light().lightSensorStream;
  }

  /// Stream de ThemeMode (light/dark) derive du capteur. Emission :
  /// - Premiere valeur immediate des qu'on a 1 lecture du capteur
  /// - Bascule uniquement si la nouvelle decision tient `_debounce`
  /// - Hysteresis : on ne bascule pas si lux est dans [seuil -h, seuil +h]
  ///
  /// L'UI peut binder ce stream directement et utiliser la derniere
  /// valeur comme override du themeMode user.
  Stream<ThemeMode> themeModeStream() async* {
    final raw = rawLuxStream();
    ThemeMode? lastEmitted;
    ThemeMode? pending;
    DateTime? pendingSince;

    await for (final lux in raw) {
      final candidate = _decide(lux, lastEmitted);
      if (candidate == null) continue; // dans la zone d'hysteresis
      if (lastEmitted == null) {
        // Premier emit : pas de debounce.
        lastEmitted = candidate;
        yield candidate;
        continue;
      }
      if (candidate == lastEmitted) {
        // Stable : reset le pending eventuel.
        pending = null;
        pendingSince = null;
        continue;
      }
      // Candidat different : demarre/poursuit le debounce.
      if (pending != candidate) {
        pending = candidate;
        pendingSince = DateTime.now();
        continue;
      }
      final elapsed = DateTime.now().difference(pendingSince!);
      if (elapsed >= _debounce) {
        lastEmitted = candidate;
        pending = null;
        pendingSince = null;
        yield candidate;
      }
    }
  }

  /// Decide le ThemeMode pour une valeur lux + un etat precedent. La
  /// zone d'hysteresis depend de l'etat precedent :
  /// - Si on est en dark : on ne passe en light que si lux >= seuil + h
  /// - Si on est en light : on ne passe en dark que si lux <= seuil - h
  /// - Premier emit (lastEmitted == null) : seuil strict sans hysteresis
  ///
  /// Retourne null si la valeur est dans la zone "ambigue" (on reste
  /// sur l'etat courant).
  @visibleForTesting
  ThemeMode? decide(int lux, ThemeMode? lastEmitted) =>
      _decide(lux, lastEmitted);

  ThemeMode? _decide(int lux, ThemeMode? lastEmitted) {
    if (lastEmitted == null) {
      return lux < _seuilLux ? ThemeMode.dark : ThemeMode.light;
    }
    final highBound = _seuilLux + _hysteresisLux;
    final lowBound = _seuilLux - _hysteresisLux;
    if (lastEmitted == ThemeMode.dark) {
      if (lux >= highBound) return ThemeMode.light;
      return null;
    }
    // lastEmitted == light
    if (lux <= lowBound) return ThemeMode.dark;
    return null;
  }
}
