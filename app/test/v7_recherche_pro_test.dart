import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';
import 'package:opti_route/data/france_geocoding_service.dart';

void main() {
  group('AddressSuggestion.sourceBadge (V7.1)', () {
    test('Carnet -> "Carnet"', () {
      final s = _suggestion(source: AddressSource.carnet);
      expect(s.sourceBadge, 'Carnet');
    });

    test('BAN -> "BAN"', () {
      expect(_suggestion(source: AddressSource.ban).sourceBadge, 'BAN');
    });

    test('SIRENE -> "SIRENE"', () {
      expect(_suggestion(source: AddressSource.sirene).sourceBadge,
          'SIRENE');
    });

    test('Photon -> "OSM"', () {
      expect(_suggestion(source: AddressSource.photon).sourceBadge, 'OSM');
    });

    test('OSM direct -> "OSM"', () {
      expect(_suggestion(source: AddressSource.osm).sourceBadge, 'OSM');
    });

    test('unknown -> null (compat back)', () {
      expect(_suggestion(source: AddressSource.unknown).sourceBadge, isNull);
    });

    test('default source = unknown', () {
      // Constructeur sans `source:` -> AddressSource.unknown.
      const s = AddressSuggestion(displayName: 'X', lat: 0, lon: 0);
      expect(s.source, AddressSource.unknown);
      expect(s.sourceBadge, isNull);
    });
  });

  group('FranceGeocodingService.extractSiret (V7.2)', () {
    test('14 chiffres consecutifs -> SIRET', () {
      expect(
        FranceGeocodingService.extractSiret('12345678901234'),
        '12345678901234',
      );
    });

    test('SIRET avec espaces (format bordereau) -> nettoye', () {
      expect(
        FranceGeocodingService.extractSiret('832 023 558 00018'),
        '83202355800018',
      );
    });

    test('SIRET avec tirets -> nettoye', () {
      expect(
        FranceGeocodingService.extractSiret('832-023-558-00018'),
        '83202355800018',
      );
    });

    test('SIRET avec prefixe textuel -> nettoye', () {
      // Cas reel : Noah colle "SIRET : 12345678901234" depuis un PDF.
      expect(
        FranceGeocodingService.extractSiret('SIRET : 12345678901234'),
        '12345678901234',
      );
    });

    test('9 chiffres -> SIREN (forme courte)', () {
      expect(
        FranceGeocodingService.extractSiret('832023558'),
        '832023558',
      );
    });

    test('10 chiffres -> null (ni SIRET ni SIREN)', () {
      expect(FranceGeocodingService.extractSiret('1234567890'), isNull);
    });

    test('15 chiffres -> null', () {
      expect(
        FranceGeocodingService.extractSiret('123456789012345'),
        isNull,
      );
    });

    test('texte sans chiffres -> null', () {
      expect(FranceGeocodingService.extractSiret('Carrefour'), isNull);
    });

    test('vide -> null', () {
      expect(FranceGeocodingService.extractSiret(''), isNull);
      expect(FranceGeocodingService.extractSiret('   '), isNull);
    });

    test('telephone FR (10 chiffres) -> null (pas SIRET)', () {
      // On laisse les telephones a une future regle, pour l'instant
      // ils ne matchent ni SIRET (14) ni SIREN (9).
      expect(
        FranceGeocodingService.extractSiret('06 12 34 56 78'),
        isNull,
      );
    });

    test('adresse "14 Rue de la Paix" -> null', () {
      // Pas de 14 chiffres consecutifs : pas un SIRET.
      expect(
        FranceGeocodingService.extractSiret('14 Rue de la Paix'),
        isNull,
      );
    });
  });
}

AddressSuggestion _suggestion({required AddressSource source}) {
  return AddressSuggestion(
    displayName: 'Test',
    lat: 48.0,
    lon: 1.0,
    source: source,
  );
}
