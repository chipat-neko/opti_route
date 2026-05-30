/// Detection eco-conduite + crash via accelerometre (carte #313). Pure
/// fns - le caller fournit la lecture sensors_plus. Pas de plugin
/// natif ici (decouplage : facile a tester).
///
/// Seuils empiriques :
/// - **freinage sec** : decel > 4 m/s2 sur l'axe avant-arriere
/// - **acceleration brute** : accel > 3 m/s2
/// - **crash potentiel** : pic > 4g (39.2 m/s2) sur n'importe quel axe
class EcoDriving {
  EcoDriving._();

  static const double brakingThreshold = 4.0;
  static const double accelThreshold = 3.0;
  static const double crashG = 4.0;
  static const double crashMps2 = crashG * 9.81;

  /// Classe un sample (accel x/y/z en m/s2) en evenement.
  static DrivingEvent classify({
    required double accelX,
    required double accelY,
    required double accelZ,
  }) {
    final magnitude = _magnitude(accelX, accelY, accelZ);
    if (magnitude >= crashMps2) return DrivingEvent.crash;
    final fwdBack = accelY.abs(); // axe Y typique en mode portrait dock
    if (fwdBack >= brakingThreshold && accelY > 0) {
      return DrivingEvent.hardBrake;
    }
    if (fwdBack >= accelThreshold && accelY < 0) {
      return DrivingEvent.hardAccel;
    }
    return DrivingEvent.normal;
  }

  /// Score eco-conduite 0-100 a partir d'un compteur d'evenements
  /// pendant la tournee (durationMin = durée totale d'activite).
  /// Plus de freinages/accels = score plus bas. Borne 0-100.
  static int computeScore({
    required int hardBrakes,
    required int hardAccels,
    required int durationMin,
  }) {
    if (durationMin <= 0) return 100;
    // 1 evenement/min = -10 pts. Apres 10 evenements/min = 0.
    final ratio = (hardBrakes + hardAccels) / durationMin;
    final score = (100 - ratio * 10).round();
    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

  static double _magnitude(double x, double y, double z) {
    return _sqrt(x * x + y * y + z * z);
  }

  // Square root via newton (eviter dart:math dependance pour test pure).
  static double _sqrt(double v) {
    if (v <= 0) return 0;
    var x = v;
    for (var i = 0; i < 16; i++) {
      x = 0.5 * (x + v / x);
    }
    return x;
  }
}

enum DrivingEvent { normal, hardAccel, hardBrake, crash }
