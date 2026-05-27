import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Helpers de presentation pour les 5 types de frais (carburant, peage,
/// parking, repas, autre). Centralise label + couleur + icone pour
/// eviter la duplication entre `frais_form_screen.dart` et la liste
/// `frais_screen.dart`.

/// Liste des types proposes dans le picker chips. Ordre = frequence
/// estimee d'utilisation (carburant > peage > parking > repas > autre).
const typesDispos = <String>[
  'carburant',
  'peage',
  'parking',
  'repas',
  'autre',
];

String labelForType(String type) {
  return switch (type) {
    'carburant' => 'Carburant',
    'peage' => 'Peage',
    'parking' => 'Parking',
    'repas' => 'Repas',
    'autre' => 'Autre',
    _ => type[0].toUpperCase() + type.substring(1),
  };
}

Color colorForType(String type) {
  return switch (type) {
    'carburant' => AppColors.amber,
    'peage' => AppColors.emerald,
    'parking' => const Color(0xFF7C4DFF),
    'repas' => AppColors.red,
    'autre' => AppColors.textMute,
    _ => AppColors.textMute,
  };
}

IconData iconForType(String type) {
  return switch (type) {
    'carburant' => Icons.local_gas_station_outlined,
    'peage' => Icons.toll_outlined,
    'parking' => Icons.local_parking_outlined,
    'repas' => Icons.restaurant_outlined,
    'autre' => Icons.receipt_outlined,
    _ => Icons.receipt_outlined,
  };
}
