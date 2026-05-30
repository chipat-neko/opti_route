/// Decide si on doit activer le mode nuit (contraste fort + bouton
/// torche visible) selon la luminosite ambiante. Carte #307.
///
/// Distinct du `AmbientLightService` existant (qui decide dark/light
/// theme) : ici on cible le contraste +++ pour lire un interphone
/// dans une cage d'escalier sombre.
///
/// Seuil par defaut : 5 lux (typique d'une cage d'escalier non
/// allumee). Hysteresis 3 lux pour eviter le flicker.
class NightModeDecision {
  NightModeDecision._();

  static const double defaultThresholdLux = 5;
  static const double hysteresisLux = 3;

  /// Decision fonction pure : prend la luminosite courante + l'etat
  /// precedent + retourne true/false. Si previousIsNight, on attend
  /// que lux remonte au-dessus de seuil+hysteresis pour sortir.
  static bool isNight({
    required double currentLux,
    bool previousIsNight = false,
    double thresholdLux = defaultThresholdLux,
  }) {
    if (previousIsNight) {
      return currentLux < thresholdLux + hysteresisLux;
    }
    return currentLux < thresholdLux;
  }
}
