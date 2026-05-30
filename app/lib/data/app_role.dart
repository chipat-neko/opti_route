/// Rôle de l'utilisateur (carte "split chauffeur/chef" 2026-05-30).
///
/// **Chauffeur** (defaut) : voit uniquement le terrain — tournée du
/// jour, scan, photo preuve, ETA, mémo vocal, SOS, etc. UI épurée.
///
/// **Chef** : voit en plus tout ce qui est administration — compta
/// URSSAF, entretien véhicule, rapport hebdo, dispatch équipe, etc.
enum AppRole {
  chauffeur,
  chef;

  String get label => switch (this) {
        AppRole.chauffeur => 'Chauffeur',
        AppRole.chef => 'Chef d\'équipe',
      };
}

/// Helpers de gating UI par feature.
/// Le caller appelle `FeatureRegistry.requires(featureKey)` pour
/// récupérer le rôle minimum requis. La logique `canSee` est ensuite
/// triviale : `currentRole.index >= required.index` (chef voit tout).
class FeatureRegistry {
  FeatureRegistry._();

  /// Map des features de l'app -> rôle minimum pour les voir/utiliser.
  /// Si une feature n'est PAS dans la map -> default `chauffeur` (= visible par tous).
  /// Naming convention : `<module>.<feature>` en snake_case.
  static const Map<String, AppRole> _registry = {
    // ===== App / système =====
    'app.update_checker': AppRole.chef,

    // ===== Pointage & temps =====
    'pointage.toggle_service': AppRole.chauffeur,
    'pointage.cumul_jour': AppRole.chauffeur,
    'pointage.cumul_semaine': AppRole.chef,
    'pointage.cumul_mois': AppRole.chef,

    // ===== Compta / fiscal =====
    'compta.km_urssaf': AppRole.chef,
    'compta.fec_export': AppRole.chef,
    'compta.facturation': AppRole.chef,
    'compta.cod_total_caisse': AppRole.chef,

    // ===== Véhicule =====
    'vehicule.entretien_alerts': AppRole.chef,
    'vehicule.constat_sinistre': AppRole.chef,

    // ===== Stats avancées =====
    'stats.heatmap_echecs': AppRole.chef,
    'stats.historique_client': AppRole.chef,
    'stats.comparateur_tournees': AppRole.chef,
    'stats.carte_chaleur_temps_perdu': AppRole.chef,
    'stats.weekly_report_donneur_ordre': AppRole.chef,

    // ===== Equipe / dispatch =====
    'equipe.dispatch_live': AppRole.chef,
    'equipe.invitation_coequipier': AppRole.chef,
    'equipe.split_paie_double_cabine': AppRole.chef,

    // ===== Logistique =====
    'logistique.plan_chargement_3d': AppRole.chef,
    'logistique.stock_fournitures': AppRole.chef,

    // ===== Tournée terrain (chauffeur) =====
    'tournee.eta_dynamique': AppRole.chauffeur,
    'tournee.fin_retour_depot': AppRole.chauffeur,
    'tournee.recalc_position': AppRole.chauffeur,
    'tournee.compteur_colis_camion': AppRole.chauffeur,
    'tournee.recap_depot': AppRole.chauffeur,
    'tournee.briefing_matinal': AppRole.chauffeur,
    'tournee.debrief_vocal': AppRole.chauffeur,
    'tournee.passation_remplacant': AppRole.chauffeur,

    // ===== Stop / livraison (chauffeur) =====
    'stop.memo_vocal': AppRole.chauffeur,
    'stop.notation_emoji': AppRole.chauffeur,
    'stop.depose_sans_contact': AppRole.chauffeur,
    'stop.mentions_ocr': AppRole.chauffeur,
    'stop.preferences_client': AppRole.chauffeur,
    'stop.litige_dossier': AppRole.chauffeur,
    'stop.scan_doublons': AppRole.chauffeur,

    // ===== Carnet (chauffeur) =====
    'carnet.note_stationnement': AppRole.chauffeur,
    'carnet.parking_spots': AppRole.chauffeur,
    'carnet.vigilance': AppRole.chauffeur,
    'carnet.fenetre_horaire_suggeree': AppRole.chauffeur,

    // ===== Securite chauffeur =====
    'securite.sos_button': AppRole.chauffeur,
    'securite.pin_app_lock': AppRole.chauffeur,
    'securite.temps_conduite': AppRole.chauffeur,
    'securite.eco_conduite': AppRole.chauffeur,
    'securite.battery_mode': AppRole.chauffeur,

    // ===== Autre chauffeur =====
    'meteo.tournee': AppRole.chauffeur,
    'colis.chaine_froid': AppRole.chauffeur,
    'message.jarrive_client': AppRole.chauffeur,
    'geofence.arrivee': AppRole.chauffeur,
  };

  /// Rôle minimum requis pour voir/utiliser une feature.
  /// Default `chauffeur` si non listée.
  static AppRole requires(String featureKey) {
    return _registry[featureKey] ?? AppRole.chauffeur;
  }

  /// True si [role] peut voir/utiliser la feature [featureKey].
  /// `chef.index > chauffeur.index` donc le chef voit tout.
  static bool canSee({
    required String featureKey,
    required AppRole role,
  }) {
    final required = requires(featureKey);
    return role.index >= required.index;
  }

  /// Liste de toutes les features connues (pour tests / audit UI).
  static Iterable<String> get knownFeatures => _registry.keys;
}
