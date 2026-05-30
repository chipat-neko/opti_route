/// Stock fournitures (scotch, étiquettes, sacs isothermes) avec
/// seuil bas + alertes (carte #331). Pure fn / models, storage Drift
/// dans PR future si validation.
class SupplyItem {
  const SupplyItem({
    required this.id,
    required this.name,
    required this.currentQty,
    required this.minQty,
    this.purchaseUrl,
  });

  final String id;
  final String name;

  /// Quantité actuelle en stock (rouleaux, paquets, sacs).
  final int currentQty;

  /// Seuil bas — en dessous, on alerte.
  final int minQty;

  /// URL où racheter (Amazon, Cdiscount, fournisseur local). Pas
  /// d'affiliation, juste un lien épinglé.
  final String? purchaseUrl;

  bool get isLow => currentQty <= minQty;

  /// Niveau d'alerte 0-3 (0 = ok, 3 = urgence rupture).
  int get alertLevel {
    if (currentQty <= 0) return 3;
    if (currentQty <= minQty / 2) return 2;
    if (currentQty <= minQty) return 1;
    return 0;
  }
}

class SuppliesStock {
  SuppliesStock._();

  /// Filtre les items qui meritent une notification J-3 / J-7 selon
  /// la consommation moyenne. Pour le MVP : juste isLow.
  static List<SupplyItem> needAttention(List<SupplyItem> items) {
    return items.where((i) => i.isLow).toList()
      ..sort((a, b) => b.alertLevel.compareTo(a.alertLevel));
  }
}
