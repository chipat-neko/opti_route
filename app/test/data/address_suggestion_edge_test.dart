import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';

// Complete address_suggestion_test : strictness fromJson, fallbacks
// primaryLabel, adressePostale, et defauts.
void main() {
  group('AddressSuggestion.fromJson — strictness', () {
    test('lat manquant -> FormatException', () {
      expect(
        () => AddressSuggestion.fromJson({
          'display_name': 'X',
          'lon': '1.0',
        }),
        throwsFormatException,
      );
    });

    test('lon manquant -> FormatException', () {
      expect(
        () => AddressSuggestion.fromJson({
          'display_name': 'X',
          'lat': '48.0',
        }),
        throwsFormatException,
      );
    });

    test('lat non-numerique -> FormatException', () {
      expect(
        () => AddressSuggestion.fromJson({
          'display_name': 'X',
          'lat': 'pas-un-nombre',
          'lon': '1.0',
        }),
        throwsFormatException,
      );
    });

    test('lat fourni en num (pas string) : accepte via toString', () {
      final s = AddressSuggestion.fromJson({
        'display_name': 'X',
        'lat': 48.5, // double, pas string
        'lon': 1.2,
      });
      expect(s.lat, 48.5);
      expect(s.lon, 1.2);
    });

    test('cle "name" -> poiName', () {
      final s = AddressSuggestion.fromJson({
        'display_name': 'Carrefour, 28 rue X, Paris',
        'name': 'Carrefour',
        'lat': '48.0',
        'lon': '2.0',
      });
      expect(s.poiName, 'Carrefour');
      expect(s.isPoi, isTrue);
    });

    test('display_name manquant : defaut chaine vide', () {
      final s = AddressSuggestion.fromJson({
        'lat': '48.0',
        'lon': '1.0',
      });
      expect(s.displayName, '');
    });

    test('address absent : tous les sous-champs null', () {
      final s = AddressSuggestion.fromJson({
        'display_name': 'X',
        'lat': '48.0',
        'lon': '1.0',
      });
      expect(s.road, isNull);
      expect(s.city, isNull);
      expect(s.postcode, isNull);
      expect(s.country, isNull);
      expect(s.houseNumber, isNull);
    });
  });

  group('AddressSuggestion.primaryLabel — fallbacks', () {
    test('ni POI ni rue : fallback first part displayName', () {
      const s = AddressSuggestion(
        displayName: 'Quelque part, en France, le monde',
        lat: 48,
        lon: 1,
      );
      expect(s.primaryLabel, 'Quelque part');
    });

    test('road vide et POI vide : fallback displayName', () {
      const s = AddressSuggestion(
        displayName: 'XYZ, fallback',
        lat: 48,
        lon: 1,
        road: '',
        poiName: '',
      );
      expect(s.primaryLabel, 'XYZ');
    });

    test('road sans houseNumber : juste road', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        road: 'Avenue Foch',
      );
      expect(s.primaryLabel, 'Avenue Foch');
    });
  });

  group('AddressSuggestion.adressePostale — combinaisons', () {
    test('road seul (sans cp/ville) : juste road', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        road: 'Rue X',
      );
      expect(s.adressePostale, 'Rue X');
    });

    test('cp+ville seuls (sans rue) : secondaryLabel', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        postcode: '75011',
        city: 'Paris',
      );
      expect(s.adressePostale, '75011 Paris');
    });

    test('rien : fallback complet displayName', () {
      const s = AddressSuggestion(
        displayName: 'Fallback complete',
        lat: 48,
        lon: 1,
      );
      expect(s.adressePostale, 'Fallback complete');
    });

    test('houseNumber + road + cp + ville : format complet', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        houseNumber: '12',
        road: 'Rue X',
        postcode: '28100',
        city: 'Dreux',
      );
      expect(s.adressePostale, '12 Rue X, 28100 Dreux');
    });
  });

  group('AddressSuggestion — defauts', () {
    test('fromCarnet defaut false', () {
      const s = AddressSuggestion(displayName: 'X', lat: 48, lon: 1);
      expect(s.fromCarnet, isFalse);
    });

    test('toString contient primary et secondary separes par ·', () {
      const s = AddressSuggestion(
        displayName: 'X',
        lat: 48,
        lon: 1,
        road: 'Avenue Foch',
        postcode: '75116',
        city: 'Paris',
      );
      expect(s.toString(), contains('Avenue Foch'));
      expect(s.toString(), contains('75116 Paris'));
      expect(s.toString(), contains('·'));
    });
  });
}
