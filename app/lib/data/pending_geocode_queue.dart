/// Queue persistante des adresses en attente de geocoding (carte #297).
/// Quand l'app est offline (zone blanche, campagne, parking sous-terrain),
/// les nouveaux stops sont sauvegardes localement sans coords. La queue
/// memorise leurs ids pour les retenter au prochain "online".
///
/// MVP : in-memory (perdu au restart). Une iteration v2 pourra
/// persister via une nouvelle table ou via Parametres key/value.
class PendingGeocodeQueue {
  PendingGeocodeQueue();

  final Set<int> _stopIds = <int>{};

  /// Empile un stop a re-geocoder. Idempotent (Set).
  void enqueue(int stopId) {
    if (stopId > 0) _stopIds.add(stopId);
  }

  /// Vide la queue + retourne le snapshot des ids pending pour
  /// traitement batch au retour du signal reseau.
  List<int> drain() {
    final out = List<int>.of(_stopIds);
    _stopIds.clear();
    return out;
  }

  /// Snapshot sans vidage : utile pour afficher un compteur UI.
  List<int> snapshot() => List<int>.of(_stopIds);

  int get length => _stopIds.length;
  bool get isEmpty => _stopIds.isEmpty;

  /// Retire un id specifique (apres geocoding reussi unitaire).
  void remove(int stopId) => _stopIds.remove(stopId);
}
