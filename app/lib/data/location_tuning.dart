import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
// AndroidSettings est re-exporte par geolocator (pas besoin d'importer
// geolocator_android directement).
import 'package:geolocator/geolocator.dart';

/// Réglage GPS selon l'usage, pour maîtriser la consommation batterie
/// SANS dépendre de l'exemption système Android "optimisation batterie"
/// (branche feat/opti-batterie, 2026-07-04).
///
/// Le levier clé introduit ici est `intervalDuration` (via
/// [AndroidSettings]) : sans lui, le provider FUSED d'Android calcule
/// des fixes à sa cadence par défaut dès que le `distanceFilter` est
/// franchi. En plafonnant l'intervalle, on borne le nombre de fixes
/// haute précision par seconde — gain batterie réel, transparent pour
/// l'utilisateur (aucun toggle à activer).
enum GpsUsage {
  /// Affichage passif de la distance jusqu'au prochain arrêt
  /// (ProchainArretCard, liste d'arrêts). Précision modérée suffisante.
  passive,

  /// Navigation active plein écran (NavigationScreen). Le seul cas qui
  /// justifie la haute précision + une cadence rapide.
  navigation,

  /// Push de la position du livreur vers le chef (LivePresenceService),
  /// rafraîchi toutes les ~30 s. Un marker de suivi n'a pas besoin de
  /// haute précision.
  presence,
}

/// Triplet (précision, filtre de distance, intervalle Android) résolu
/// pour un [GpsUsage] donné et l'état du mode éco batterie.
class GpsProfile {
  const GpsProfile({
    required this.accuracy,
    required this.distanceFilterMeters,
    required this.androidInterval,
  });

  final LocationAccuracy accuracy;
  final int distanceFilterMeters;
  final Duration androidInterval;

  @override
  bool operator ==(Object other) =>
      other is GpsProfile &&
      other.accuracy == accuracy &&
      other.distanceFilterMeters == distanceFilterMeters &&
      other.androidInterval == androidInterval;

  @override
  int get hashCode =>
      Object.hash(accuracy, distanceFilterMeters, androidInterval);

  @override
  String toString() =>
      'GpsProfile($accuracy, ${distanceFilterMeters}m, $androidInterval)';
}

/// Résout le profil GPS pour un usage donné. Fonction PURE (testable).
///
/// - navigation : haute précision + 10 m + intervalle 2 s (nav live).
/// - presence   : précision moyenne + 50 m + intervalle 10 s.
/// - passive    : moyenne/100 m/20 s en mode éco, sinon haute/25 m mais
///   avec un intervalle plafonné à 4 s (l'accuracy n'est PAS dégradée
///   par défaut — on ne fait que borner la cadence).
GpsProfile resolveGpsProfile({
  required GpsUsage usage,
  required bool eco,
}) {
  switch (usage) {
    case GpsUsage.navigation:
      return const GpsProfile(
        accuracy: LocationAccuracy.high,
        distanceFilterMeters: 10,
        androidInterval: Duration(seconds: 2),
      );
    case GpsUsage.presence:
      return const GpsProfile(
        accuracy: LocationAccuracy.medium,
        distanceFilterMeters: 50,
        androidInterval: Duration(seconds: 10),
      );
    case GpsUsage.passive:
      return eco
          ? const GpsProfile(
              accuracy: LocationAccuracy.medium,
              distanceFilterMeters: 100,
              androidInterval: Duration(seconds: 20),
            )
          : const GpsProfile(
              accuracy: LocationAccuracy.high,
              distanceFilterMeters: 25,
              androidInterval: Duration(seconds: 4),
            );
  }
}

/// Construit le [LocationSettings] à passer à `getPositionStream`.
///
/// Sur Android on renvoie un [AndroidSettings] avec `intervalDuration`
/// (plafond de cadence) + `forceLocationManager: false` pour garder le
/// provider FUSED (plus économe que le LocationManager brut). Ailleurs
/// (iOS/web/desktop) on retombe sur le [LocationSettings] générique qui
/// n'expose pas d'intervalle.
///
/// [isAndroid] est injecté (au lieu de lire la plateforme en dur) pour
/// rendre la fonction testable sur la VM.
LocationSettings buildLocationSettings({
  required LocationAccuracy accuracy,
  required int distanceFilterMeters,
  required Duration androidInterval,
  required bool isAndroid,
}) {
  if (isAndroid) {
    return AndroidSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterMeters,
      intervalDuration: androidInterval,
      // false = provider FUSED (Google Play Services), plus econome en
      // batterie que le LocationManager systeme (forceLocationManager).
      forceLocationManager: false,
    );
  }
  return LocationSettings(
    accuracy: accuracy,
    distanceFilter: distanceFilterMeters,
  );
}

/// Vrai si la plateforme courante est Android natif (pas web). Centralisé
/// ici pour que [buildLocationSettings] et ses appelants partagent la
/// même détection.
bool get isAndroidRuntime =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
