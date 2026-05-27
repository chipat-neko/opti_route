import 'database.dart';

/// Type d'un point affiche sur la carte chef du jour.
enum ChefPointType { depot, stop }

/// Un point geolocalise a afficher sur la carte chef (epopee #88,
/// [#88·3]) : soit un point de depart de tournee (depot), soit un
/// arret (stop) avec son statut de livraison.
class ChefCartePoint {
  const ChefCartePoint({
    required this.lat,
    required this.lng,
    required this.type,
    this.statut,
    this.label,
  });

  final double lat;
  final double lng;
  final ChefPointType type;

  /// Statut de livraison du stop (`livre` / `echec` / `a_livrer`).
  /// Null pour un depot.
  final String? statut;

  /// Libelle court (nom de tournee pour un depot, nom client / adresse
  /// pour un stop). Optionnel.
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is ChefCartePoint &&
      other.lat == lat &&
      other.lng == lng &&
      other.type == type &&
      other.statut == statut &&
      other.label == label;

  @override
  int get hashCode => Object.hash(lat, lng, type, statut, label);
}

/// Agregat des points geolocalises de la journee pour la carte chef.
class ChefCarteJour {
  const ChefCarteJour({required this.points});

  static const empty = ChefCarteJour(points: <ChefCartePoint>[]);

  final List<ChefCartePoint> points;

  bool get isEmpty => points.isEmpty;

  int get nbDepots =>
      points.where((p) => p.type == ChefPointType.depot).length;
  int get nbStops =>
      points.where((p) => p.type == ChefPointType.stop).length;

  /// Construit la liste des points (depots + stops geolocalises) a
  /// partir des tournees du jour et de leurs stops. Fonction pure.
  ///
  /// - 1 point depot par tournee (lat/lng du point de depart).
  /// - 1 point stop par arret ayant des coordonnees (lat & lng non
  ///   null). Les arrets non geocodes sont ignores (pas de coords).
  static ChefCarteJour computeFromBundle({
    required List<Tournee> tournees,
    required List<Stop> stops,
  }) {
    if (tournees.isEmpty) return empty;

    final tourneeIds = tournees.map((t) => t.id).toSet();
    final points = <ChefCartePoint>[
      for (final t in tournees)
        ChefCartePoint(
          lat: t.pointDepartLat,
          lng: t.pointDepartLng,
          type: ChefPointType.depot,
          label: t.nom,
        ),
      for (final s in stops)
        if (tourneeIds.contains(s.tourneeId) &&
            s.lat != null &&
            s.lng != null)
          ChefCartePoint(
            lat: s.lat!,
            lng: s.lng!,
            type: ChefPointType.stop,
            statut: s.statutLivraison,
            label: s.nomClient ?? s.adresseBrute,
          ),
    ];
    return ChefCarteJour(points: points);
  }
}
