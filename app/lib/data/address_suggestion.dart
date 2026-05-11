/// Source de donnees qui a produit une suggestion. Sert a afficher
/// un badge dans l'UI (transparence) et a debugger les choix de
/// cascade.
enum AddressSource {
  /// Carnet d'adresses local (clients deja livres). Toujours en 1er.
  carnet,

  /// Base Adresse Nationale (api-adresse.data.gouv.fr). Source
  /// officielle pour les adresses postales francaises.
  ban,

  /// Annuaire SIRENE / Recherche-Entreprises
  /// (recherche-entreprises.api.gouv.fr). Source officielle pour les
  /// entreprises immatriculees en France.
  sirene,

  /// Photon (OSM/Komoot). Couverture mondiale pour les enseignes,
  /// monuments, lieux publics.
  photon,

  /// Nominatim direct (rarement utilise, voir geocoding_service).
  osm,

  /// Source inconnue / pas precisee (compat back).
  unknown,
}

/// Une suggestion d'adresse retournee par la cascade de geocodage
/// (BAN / SIRENE / Photon) ou par le carnet local.
///
/// `lat` et `lon` ne sont jamais montres a l'utilisateur — ils sont
/// stockes en base et utilises pour le geocoding inverse, l'optimisation
/// et la navigation.
class AddressSuggestion {
  const AddressSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.road,
    this.houseNumber,
    this.postcode,
    this.city,
    this.country,
    this.poiName,
    this.fromCarnet = false,
    this.source = AddressSource.unknown,
  });

  /// Source qui a produit cette suggestion (BAN, SIRENE, Photon,
  /// Carnet, OSM). Sert a afficher un badge informatif a l'utilisateur
  /// et a debugger les choix de cascade.
  final AddressSource source;

  /// Vrai si la suggestion vient du carnet d'adresses local
  /// (un client deja livre). L'UI peut afficher un badge "DEJA LIVRE".
  ///
  /// Note : redondant avec `source == AddressSource.carnet` mais
  /// garde pour compat back avec le code historique.
  final bool fromCarnet;

  /// Reponse complete de Nominatim (`display_name`).
  /// Ex: "14, Rue du Faubourg Saint-Antoine, Saint-Marcel, ..., 75011, France".
  final String displayName;

  /// Coordonnees stockees mais jamais affichees a l'utilisateur.
  final double lat;
  final double lon;

  // Champs admin extraits de `address` (peuvent etre nuls selon le pays).
  final String? road;
  final String? houseNumber;
  final String? postcode;
  final String? city;
  final String? country;

  /// Nom d'un POI (Point Of Interest) : commerce, entreprise, site
  /// notable. Quand present, on l'affiche en titre dans l'UI a la place
  /// de l'adresse. Ex : "Carrosserie Coculo".
  final String? poiName;

  /// Vrai si la suggestion est un POI (entreprise / commerce / site).
  bool get isPoi => poiName != null && poiName!.isNotEmpty;

  /// Premiere ligne pour l'UI :
  /// - POI : nom du POI ("Carrosserie Coculo").
  /// - Adresse : "14 Rue du Faubourg Saint-Antoine".
  String get primaryLabel {
    if (isPoi) return poiName!;
    if (road != null && road!.isNotEmpty) {
      return houseNumber != null && houseNumber!.isNotEmpty
          ? '$houseNumber $road'
          : road!;
    }
    return displayName.split(',').first.trim();
  }

  /// Deuxieme ligne pour l'UI : "75011 Paris".
  String get secondaryLabel {
    final parts = <String>[
      if (postcode != null && postcode!.isNotEmpty) postcode!,
      if (city != null && city!.isNotEmpty) city!,
    ];
    return parts.join(' ');
  }

  /// Adresse postale propre, **sans le nom du commerce**, pour
  /// stockage dans `Stop.adresseBrute`.
  ///
  /// Le `displayName` contient typiquement "BCI CHARTRES (BCI), LE BOIS
  /// DE PARIS IMPASSE, 28000 CHARTRES" -- redondant avec `nomClient`
  /// quand on l'affiche en titre. On ne veut que l'adresse postale.
  ///
  /// Strategie :
  /// 1. Si on a road + city : reconstruction propre "{n} {rue}, {cp} {ville}".
  /// 2. Sinon, fallback sur displayName.
  String get adressePostale {
    final rueLine = road != null && road!.isNotEmpty
        ? (houseNumber != null && houseNumber!.isNotEmpty
            ? '$houseNumber $road'
            : road!)
        : null;
    final localityLine = secondaryLabel;
    if (rueLine != null && localityLine.isNotEmpty) {
      return '$rueLine, $localityLine';
    }
    if (rueLine != null) return rueLine;
    if (localityLine.isNotEmpty) return localityLine;
    return displayName;
  }

  factory AddressSuggestion.fromJson(
    Map<String, dynamic> json, {
    AddressSource source = AddressSource.osm,
  }) {
    final address = (json['address'] as Map?)?.cast<String, dynamic>();
    return AddressSuggestion(
      displayName: json['display_name'] as String? ?? '',
      lat: double.parse(json['lat'].toString()),
      lon: double.parse(json['lon'].toString()),
      road: address?['road'] as String? ??
          address?['pedestrian'] as String? ??
          address?['cycleway'] as String?,
      houseNumber: address?['house_number'] as String?,
      postcode: address?['postcode'] as String?,
      city: address?['city'] as String? ??
          address?['town'] as String? ??
          address?['village'] as String? ??
          address?['municipality'] as String?,
      country: address?['country'] as String?,
      poiName: json['name'] as String?,
      source: source,
    );
  }

  /// Label court pour le badge UI : `BAN`, `SIRENE`, `OSM`, `Carnet`.
  String? get sourceBadge {
    switch (source) {
      case AddressSource.carnet:
        return 'Carnet';
      case AddressSource.ban:
        return 'BAN';
      case AddressSource.sirene:
        return 'SIRENE';
      case AddressSource.photon:
        return 'OSM';
      case AddressSource.osm:
        return 'OSM';
      case AddressSource.unknown:
        return null;
    }
  }

  @override
  String toString() => 'AddressSuggestion($primaryLabel · $secondaryLabel)';
}
