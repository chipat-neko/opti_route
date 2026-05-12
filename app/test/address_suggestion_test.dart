import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';

void main() {
  group('AddressSuggestion.adressePostale', () {
    test('POI SIRENE : retire le nom de l\'entreprise du displayName', () {
      // Cas reel : SIRENE renvoie un displayName "BCI CHARTRES (BCI),
      // LE BOIS DE PARIS IMPASSE, 28000 CHARTRES". Le nom est ensuite
      // affiche en titre via `nomClient` -- on ne veut pas le voir
      // une 2e fois en sous-titre.
      const s = AddressSuggestion(
        displayName: 'BCI CHARTRES (BCI), LE BOIS DE PARIS IMPASSE, 28000 CHARTRES',
        lat: 48.4307,
        lon: 1.4892,
        road: 'IMPASSE LE BOIS DE PARIS',
        postcode: '28000',
        city: 'CHARTRES',
        poiName: 'BCI CHARTRES (BCI)',
      );
      // L'adresse postale ne doit plus contenir le nom de l'entreprise.
      expect(s.adressePostale.toUpperCase(),
          isNot(contains('BCI CHARTRES')));
      expect(s.adressePostale, contains('IMPASSE LE BOIS DE PARIS'));
      expect(s.adressePostale, contains('28000 CHARTRES'));
    });

    test('adresse classique avec numero : "{n} {rue}, {cp} {ville}"', () {
      const s = AddressSuggestion(
        displayName: '14, Rue du Faubourg Saint-Antoine, 75011 Paris',
        lat: 48.85,
        lon: 2.37,
        road: 'Rue du Faubourg Saint-Antoine',
        houseNumber: '14',
        postcode: '75011',
        city: 'Paris',
      );
      expect(s.adressePostale, '14 Rue du Faubourg Saint-Antoine, 75011 Paris');
    });

    test('adresse sans numero : juste la rue + ville', () {
      const s = AddressSuggestion(
        displayName: 'Rue de la Mouchetiere, 45140 Ingre',
        lat: 47.9,
        lon: 1.85,
        road: 'Rue de la Mouchetiere',
        postcode: '45140',
        city: 'Ingre',
      );
      expect(s.adressePostale, 'Rue de la Mouchetiere, 45140 Ingre');
    });

    test('aucune composante : fallback sur displayName', () {
      const s = AddressSuggestion(
        displayName: 'Quelque part en France',
        lat: 47,
        lon: 2,
      );
      expect(s.adressePostale, 'Quelque part en France');
    });
  });

  group('AddressSuggestion - notesCarnet (V8 carnet enrichi)', () {
    test('null par defaut', () {
      const s = AddressSuggestion(displayName: 'A', lat: 48, lon: 1);
      expect(s.notesCarnet, isNull);
    });

    test('fournit la valeur quand passe en constructeur', () {
      const s = AddressSuggestion(
        displayName: 'A',
        lat: 48,
        lon: 1,
        fromCarnet: true,
        notesCarnet: 'Code 1234B, sonner 2 fois',
      );
      expect(s.notesCarnet, 'Code 1234B, sonner 2 fois');
      expect(s.fromCarnet, isTrue);
    });
  });

  group('AddressSuggestion - isPoi', () {
    test('poiName null : isPoi = false', () {
      const s = AddressSuggestion(displayName: 'A', lat: 48, lon: 1);
      expect(s.isPoi, isFalse);
    });

    test('poiName vide : isPoi = false', () {
      const s = AddressSuggestion(
        displayName: 'A',
        lat: 48,
        lon: 1,
        poiName: '',
      );
      expect(s.isPoi, isFalse);
    });

    test('poiName renseigne : isPoi = true', () {
      const s = AddressSuggestion(
        displayName: 'A',
        lat: 48,
        lon: 1,
        poiName: 'Carrefour Dreux',
      );
      expect(s.isPoi, isTrue);
    });

    test('fromJson : parse une reponse Nominatim typique', () {
      final s = AddressSuggestion.fromJson({
        'display_name': '14 Rue X, 75011 Paris, France',
        'lat': '48.85',
        'lon': '2.37',
        'address': {
          'road': 'Rue X',
          'house_number': '14',
          'postcode': '75011',
          'city': 'Paris',
          'country': 'France',
        },
      });
      expect(s.displayName, '14 Rue X, 75011 Paris, France');
      expect(s.lat, 48.85);
      expect(s.lon, 2.37);
      expect(s.road, 'Rue X');
      expect(s.houseNumber, '14');
      expect(s.postcode, '75011');
      expect(s.city, 'Paris');
      expect(s.country, 'France');
    });

    test('fromJson : fallback pour les types alternatifs de rue + ville', () {
      // OSM expose parfois "pedestrian" au lieu de "road", "town" au
      // lieu de "city". Le parser doit gerer ces fallbacks.
      final s = AddressSuggestion.fromJson({
        'display_name': 'Quelque part',
        'lat': '48.0',
        'lon': '1.0',
        'address': {
          'pedestrian': 'Allee X',
          'town': 'Dreux',
        },
      });
      expect(s.road, 'Allee X');
      expect(s.city, 'Dreux');
    });

    test('secondaryLabel : "cp city"', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        postcode: '75011',
        city: 'Paris',
      );
      expect(s.secondaryLabel, '75011 Paris');
    });

    test('secondaryLabel : juste cp si pas de city', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        postcode: '75011',
      );
      expect(s.secondaryLabel, '75011');
    });

    test('secondaryLabel : vide si rien', () {
      const s = AddressSuggestion(displayName: 'X', lat: 48, lon: 1);
      expect(s.secondaryLabel, '');
    });

    test('toString : "primary · secondary"', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        road: 'rue X',
        houseNumber: '12',
        postcode: '75011',
        city: 'Paris',
      );
      // toString contient au moins primaryLabel
      expect(s.toString(), contains('12 rue X'));
      expect(s.toString(), contains('75011 Paris'));
    });

    test('fromJson : fallback cycleway pour road', () {
      final s = AddressSuggestion.fromJson({
        'display_name': 'Piste',
        'lat': '48.0',
        'lon': '1.0',
        'address': {'cycleway': 'Piste cyclable X'},
      });
      expect(s.road, 'Piste cyclable X');
    });

    test('fromJson : fallback village/municipality pour city', () {
      // village
      final s1 = AddressSuggestion.fromJson({
        'display_name': 'X',
        'lat': '48.0',
        'lon': '1.0',
        'address': {'village': 'Petit Village'},
      });
      expect(s1.city, 'Petit Village');

      // municipality
      final s2 = AddressSuggestion.fromJson({
        'display_name': 'X',
        'lat': '48.0',
        'lon': '1.0',
        'address': {'municipality': 'Commune X'},
      });
      expect(s2.city, 'Commune X');
    });

    test('fromJson : adresse minimale (juste lat/lon)', () {
      final s = AddressSuggestion.fromJson({
        'display_name': 'Quelque part',
        'lat': '48.0',
        'lon': '1.0',
      });
      expect(s.displayName, 'Quelque part');
      expect(s.lat, 48.0);
      expect(s.road, isNull);
      expect(s.city, isNull);
    });

    test('primaryLabel : retourne poiName si POI, sinon rue', () {
      const poi = AddressSuggestion(
        displayName: 'BCI CHARTRES, IMPASSE X, 28000',
        lat: 48,
        lon: 1,
        poiName: 'BCI CHARTRES',
        road: 'IMPASSE X',
      );
      expect(poi.primaryLabel, 'BCI CHARTRES');

      const addr = AddressSuggestion(
        displayName: '14 rue X',
        lat: 48,
        lon: 1,
        road: 'rue X',
        houseNumber: '14',
      );
      expect(addr.primaryLabel, '14 rue X');
    });
  });
}
