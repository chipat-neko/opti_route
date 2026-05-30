import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/screens/frais_form/type_helpers.dart';
import 'package:opti_route/theme/app_tokens.dart';

// Tests des helpers pures de frais_form/type_helpers.dart : labelForType,
// colorForType, iconForType + constante typesDispos.
void main() {
  group('typesDispos', () {
    test('5 types : carburant en tete (frequence), autre en queue', () {
      expect(typesDispos, hasLength(5));
      expect(typesDispos.first, 'carburant');
      expect(typesDispos.last, 'autre');
      expect(typesDispos, containsAll(const [
        'carburant', 'peage', 'parking', 'repas', 'autre',
      ]));
    });

    test('pas de doublons', () {
      expect(typesDispos.toSet().length, typesDispos.length);
    });
  });

  group('labelForType', () {
    test('5 types connus -> labels capitalises', () {
      expect(labelForType('carburant'), 'Carburant');
      expect(labelForType('peage'), 'Peage');
      expect(labelForType('parking'), 'Parking');
      expect(labelForType('repas'), 'Repas');
      expect(labelForType('autre'), 'Autre');
    });

    test('type inconnu : 1ere lettre majuscule', () {
      expect(labelForType('inconnu'), 'Inconnu');
      expect(labelForType('xyz'), 'Xyz');
    });

    test('chaine vide : retourne vide', () {
      expect(labelForType(''), '');
    });

    test('1 caractere : retourne maj', () {
      expect(labelForType('a'), 'A');
    });
  });

  group('colorForType', () {
    test('carburant : amber', () {
      expect(colorForType('carburant'), AppColors.amber);
    });

    test('peage : emerald', () {
      expect(colorForType('peage'), AppColors.emerald);
    });

    test('parking : violet hex (#7C4DFF)', () {
      expect(colorForType('parking'), const Color(0xFF7C4DFF));
    });

    test('repas : red', () {
      expect(colorForType('repas'), AppColors.red);
    });

    test('autre : textMute (gris)', () {
      expect(colorForType('autre'), AppColors.textMute);
    });

    test('type inconnu : fallback textMute (gris)', () {
      expect(colorForType('inconnu'), AppColors.textMute);
    });
  });

  group('iconForType', () {
    test('carburant : station service', () {
      expect(iconForType('carburant'), Icons.local_gas_station_outlined);
    });

    test('peage : toll', () {
      expect(iconForType('peage'), Icons.toll_outlined);
    });

    test('parking : parking', () {
      expect(iconForType('parking'), Icons.local_parking_outlined);
    });

    test('repas : restaurant', () {
      expect(iconForType('repas'), Icons.restaurant_outlined);
    });

    test('autre : receipt', () {
      expect(iconForType('autre'), Icons.receipt_outlined);
    });

    test('type inconnu : fallback receipt', () {
      expect(iconForType('inconnu'), Icons.receipt_outlined);
    });
  });
}
