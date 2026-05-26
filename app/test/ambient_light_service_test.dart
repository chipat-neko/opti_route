import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/ambient_light_service.dart';

/// Tests de la logique de decision du AmbientLightService (carte
/// Trello #95). On se limite a la fonction pure `decide()` qui est le
/// coeur metier : seuil + hysteresis. Le debounce + l'integration avec
/// le capteur natif sont testes en device (le package `light` n'a pas
/// de mock officiel).
void main() {
  group('AmbientLightService.decide (hysteresis)', () {
    test('premier emit : seuil strict sans hysteresis', () {
      final svc = AmbientLightService(seuilLux: 50);
      expect(svc.decide(10, null), ThemeMode.dark, reason: '10 < 50');
      expect(svc.decide(100, null), ThemeMode.light, reason: '100 >= 50');
      expect(svc.decide(50, null), ThemeMode.light,
          reason: 'borne exacte = light');
    });

    test('hysteresis depuis dark : ne switch que si >= seuil + h', () {
      final svc = AmbientLightService(seuilLux: 50, hysteresisLux: 10);
      // En dark, valeur 55 (entre 40 et 60) -> reste dark (null = no change)
      expect(svc.decide(55, ThemeMode.dark), isNull);
      // En dark, valeur 60 (= seuil + h) -> switch light
      expect(svc.decide(60, ThemeMode.dark), ThemeMode.light);
      // En dark, valeur 100 -> switch light
      expect(svc.decide(100, ThemeMode.dark), ThemeMode.light);
    });

    test('hysteresis depuis light : ne switch que si <= seuil - h', () {
      final svc = AmbientLightService(seuilLux: 50, hysteresisLux: 10);
      // En light, valeur 45 (entre 40 et 60) -> reste light
      expect(svc.decide(45, ThemeMode.light), isNull);
      // En light, valeur 40 (= seuil - h) -> switch dark
      expect(svc.decide(40, ThemeMode.light), ThemeMode.dark);
      // En light, valeur 5 -> switch dark
      expect(svc.decide(5, ThemeMode.light), ThemeMode.dark);
    });

    test('valeur exactement au seuil sans etat precedent', () {
      final svc = AmbientLightService(seuilLux: 50);
      // Convention: borne >= seuil = light
      expect(svc.decide(50, null), ThemeMode.light);
      expect(svc.decide(49, null), ThemeMode.dark);
    });

    test('hysteresis large (20 lux) elargit la zone neutre', () {
      final svc = AmbientLightService(seuilLux: 100, hysteresisLux: 20);
      // En dark : zone neutre [80, 120[ -> 110 reste dark
      expect(svc.decide(110, ThemeMode.dark), isNull);
      expect(svc.decide(119, ThemeMode.dark), isNull);
      expect(svc.decide(120, ThemeMode.dark), ThemeMode.light);
      // En light : zone neutre ]80, 120] -> 90 reste light
      expect(svc.decide(90, ThemeMode.light), isNull);
      expect(svc.decide(81, ThemeMode.light), isNull);
      expect(svc.decide(80, ThemeMode.light), ThemeMode.dark);
    });
  });
}
