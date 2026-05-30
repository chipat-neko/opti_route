/// Décide ce qui doit être désactivé selon le % batterie (carte #325).
/// Pure fn : seuil 15% = bascule en mode dégradé pour finir la tournée
/// sans risquer de perdre une photo preuve / un SOS.
class BatteryMode {
  BatteryMode._();

  static const int criticalThresholdPct = 15;
  static const int lowThresholdPct = 30;

  static BatteryProfile decide(int batteryPct) {
    if (batteryPct <= criticalThresholdPct) return BatteryProfile.critical;
    if (batteryPct <= lowThresholdPct) return BatteryProfile.low;
    return BatteryProfile.normal;
  }

  /// True si la météo (#295) doit être désactivée pour ce profil.
  static bool shouldDisableWeather(BatteryProfile p) =>
      p != BatteryProfile.normal;

  /// True si OSRM auto-update (#397) doit être suspendu.
  static bool shouldSuspendOsrm(BatteryProfile p) =>
      p == BatteryProfile.critical;

  /// True si la heatmap d'anomalies (#122) doit être suspendue.
  static bool shouldSuspendHeatmap(BatteryProfile p) =>
      p == BatteryProfile.critical;

  /// True si le tracking GPS continu doit passer en intervalle long.
  static bool shouldSlowGpsTracking(BatteryProfile p) =>
      p != BatteryProfile.normal;
}

enum BatteryProfile { normal, low, critical }
