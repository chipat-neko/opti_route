import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/ambient_light_service.dart';

// Complete ambient_light_service_test : pipeline themeModeStream
// (premier emit, debounce, hysteresis) via overrideStream injecte.
void main() {
  group('AmbientLightService.themeModeStream — premier emit', () {
    test('premier lux < seuil : emit dark immediat (pas de debounce)',
        () async {
      final svc = AmbientLightService(
        seuilLux: 50,
        debounce: const Duration(seconds: 5),
        overrideStream: Stream.fromIterable([10]),
      );
      final emits = await svc.themeModeStream().take(1).toList();
      expect(emits, [ThemeMode.dark]);
    });

    test('premier lux >= seuil : emit light immediat', () async {
      final svc = AmbientLightService(
        seuilLux: 50,
        overrideStream: Stream.fromIterable([100]),
      );
      final emits = await svc.themeModeStream().take(1).toList();
      expect(emits, [ThemeMode.light]);
    });
  });

  group('AmbientLightService.themeModeStream — hysteresis', () {
    test('lux dans la zone tampon apres dark : reste dark', () async {
      // dark a 10 -> emit dark, puis 45 (dans tampon [40, 60]) -> reste dark
      final svc = AmbientLightService(
        seuilLux: 50,
        hysteresisLux: 10,
        overrideStream: Stream.fromIterable([10, 45]),
      );
      final emits = await svc.themeModeStream().take(1).toList();
      expect(emits, [ThemeMode.dark],
          reason: 'le 45 est dans la zone tampon, pas de nouvelle emission');
    });

    test('lux franchit le seuil + hysteresis avec debounce 0 : bascule',
        () async {
      // Avec debounce 0 et hysteresisLux 10 :
      // 10 -> dark, puis 70 (>= 60) -> 2eme emit light immediat
      final svc = AmbientLightService(
        seuilLux: 50,
        hysteresisLux: 10,
        debounce: Duration.zero,
        overrideStream: Stream.fromIterable([10, 70, 70]),
      );
      final emits = await svc.themeModeStream().take(2).toList();
      expect(emits, [ThemeMode.dark, ThemeMode.light]);
    });
  });

  group('AmbientLightService.themeModeStream — debounce', () {
    test('un seul candidat different ne suffit pas (besoin de tenir debounce)',
        () async {
      // 1ere valeur 10 -> dark emis
      // Puis sequence 70 (light candidat), 30 (revient dark candidat avant
      // d'avoir tenu debounce 200ms) -> reset pending -> reste dark
      final controller = StreamController<int>();
      final svc = AmbientLightService(
        seuilLux: 50,
        hysteresisLux: 10,
        debounce: const Duration(milliseconds: 200),
        overrideStream: controller.stream,
      );
      final emits = <ThemeMode>[];
      final sub = svc.themeModeStream().listen(emits.add);
      controller.add(10);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      controller.add(70); // pending light
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.add(30); // revient sous le seuil, mais pending reset
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await controller.close();
      await sub.cancel();
      // 30 est sous seuil (en partant de dark : 30 < 60 hysteresis +) ->
      // reste dark. Donc on a juste eu l'emit initial dark.
      expect(emits, [ThemeMode.dark]);
    });
  });

  group('AmbientLightService — defaut', () {
    test('rawLuxStream sans override sur platform non supportee : Stream vide',
        () async {
      // Le test tourne sur la VM Dart (pas Android) => isSupported=false
      // donc le stream brut est vide.
      final svc = AmbientLightService();
      final emits = await svc.rawLuxStream().toList()
          .timeout(const Duration(seconds: 1), onTimeout: () => []);
      expect(emits, isEmpty);
    });

    test('overrideStream prioritaire sur la detection plateforme', () async {
      final svc = AmbientLightService(
        overrideStream: Stream.fromIterable([1, 2, 3]),
      );
      final emits = await svc.rawLuxStream().toList();
      expect(emits, [1, 2, 3]);
    });
  });
}
