import 'database.dart';

/// Plan de chargement 3D simplifié (carte #332) : prend la liste des
/// colis avec metadonnees (fragile, lourd, ordre livraison) et propose
/// une disposition par zone (avant/arrière) + niveau (haut/bas).
///
/// Modèle ultra-simplifié pour le MVP : pas de vraie 3D, juste des
/// règles de placement. Le widget Flutter dessinera une grille via
/// CustomPainter.
class LoadingPlan3D {
  LoadingPlan3D._();

  /// Place chaque colis selon :
  /// - fragile  -> niveau HAUT
  /// - lourd    -> niveau BAS
  /// - livre tot -> zone AVANT (sortir en 1er)
  /// - livre tard -> zone FOND
  static List<PlacedItem> compute(List<LoadingItem> items) {
    return [
      for (final item in items)
        PlacedItem(
          item: item,
          zone: _zoneFor(item.deliveryOrder, items.length),
          level: _levelFor(item),
        ),
    ];
  }

  static LoadingZone _zoneFor(int order, int total) {
    if (total <= 1) return LoadingZone.front;
    // <= pour gerer les cas petits totaux (1/3=0.333, 2/3=0.666 doit
    // etre middle).
    final ratio = order / total;
    if (ratio <= 1 / 3 + 1e-9) return LoadingZone.front;
    if (ratio <= 2 / 3 + 1e-9) return LoadingZone.middle;
    return LoadingZone.back;
  }

  static LoadingLevel _levelFor(LoadingItem item) {
    if (item.fragile) return LoadingLevel.top;
    if (item.heavy) return LoadingLevel.bottom;
    return LoadingLevel.middle;
  }
}

class LoadingItem {
  const LoadingItem({
    required this.stopId,
    required this.deliveryOrder,
    this.fragile = false,
    this.heavy = false,
  });

  final int stopId;
  final int deliveryOrder; // 1 = livre en premier
  final bool fragile;
  final bool heavy;
}

class PlacedItem {
  const PlacedItem({
    required this.item,
    required this.zone,
    required this.level,
  });

  final LoadingItem item;
  final LoadingZone zone;
  final LoadingLevel level;
}

enum LoadingZone { front, middle, back }

enum LoadingLevel { top, middle, bottom }

/// Helper qui derive les LoadingItem depuis les stops + mentions OCR
/// du bordereau (carte #329).
extension StopsLoadingPlan on List<Stop> {
  List<LoadingItem> toLoadingItems({
    Set<int> fragileStopIds = const {},
    Set<int> heavyStopIds = const {},
  }) {
    final out = <LoadingItem>[];
    for (var i = 0; i < length; i++) {
      final s = this[i];
      out.add(LoadingItem(
        stopId: s.id,
        deliveryOrder: i + 1,
        fragile: fragileStopIds.contains(s.id),
        heavy: heavyStopIds.contains(s.id),
      ));
    }
    return out;
  }
}
