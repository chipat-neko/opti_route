import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Markers de la carte de tournee.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `carte_screen.dart` (674 lignes initiales). 3 classes
/// liees au rendu des pin sur le `FlutterMap` :
/// - [buildDepotMarker]  : pin lime "entrepot" pour le point de depart
/// - [buildStopMarker]   : pin numerote (ou check / !) pour chaque
///                          arret selon son statut
/// - [PinShell]          : container circulaire reutilise par les 2,
///                          avec border + shadow consistants

/// Construit le marker du depot (point de depart de la tournee). Pin
/// lime + icone entrepot, distinct visuellement des stops numerotes.
Marker buildDepotMarker(LatLng latLng, Tournee tournee) {
  return Marker(
    point: latLng,
    width: 48,
    height: 48,
    alignment: Alignment.center,
    child: const PinShell(
      bg: AppColors.lime,
      border: AppColors.ink,
      child: Icon(
        Icons.warehouse_outlined,
        size: 22,
        color: AppColors.ink,
      ),
    ),
  );
}

/// Construit le marker d'un arret. Style visual selon le statut :
/// - livre   : pin emerald + check
/// - echec   : pin rouge + "!"
/// - autre   : pin paper + numero d'ordre dans la tournee
Marker buildStopMarker({
  required Stop stop,
  required int index,
  required VoidCallback onTap,
}) {
  final (bg, fg, label) = _styleForStop(stop, index);
  return Marker(
    point: LatLng(stop.lat!, stop.lng!),
    width: 40,
    height: 40,
    alignment: Alignment.center,
    child: GestureDetector(
      onTap: onTap,
      child: PinShell(
        bg: bg,
        border: AppColors.ink,
        child: Center(
          child: label is Widget
              ? label
              : Text(
                  label as String,
                  style: appMonoStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
        ),
      ),
    ),
  );
}

/// Tuple (couleur fond, couleur texte, contenu) pour un stop. Le
/// contenu peut etre soit une string (numero) soit un Widget direct
/// (Icon check pour livre, Text "!" pour echec).
(Color, Color, Object) _styleForStop(Stop stop, int index) {
  return switch (stop.statutLivraison) {
    'livre' => (
        AppColors.emerald,
        AppColors.paper,
        const Icon(Icons.check, color: AppColors.paper, size: 18),
      ),
    'echec' => (
        AppColors.red,
        AppColors.paper,
        const Text(
          '!',
          style: TextStyle(
            color: AppColors.paper,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    _ => (AppColors.paper, AppColors.ink, '$index'),
  };
}

/// Container circulaire reutilise pour tous les markers : fond
/// configurable + border 1.5 px + shadow FAB pour relief.
class PinShell extends StatelessWidget {
  const PinShell({
    super.key,
    required this.bg,
    required this.border,
    required this.child,
  });

  final Color bg;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
        boxShadow: AppShadows.fab,
      ),
      child: Center(child: child),
    );
  }
}
