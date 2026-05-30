import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/weather_service.dart';

void main() {
  group('WeatherService.fetchHourly (#295)', () {
    test('200 OK parse hourly', () async {
      final body = jsonEncode({
        'hourly': {
          'time': ['2026-05-30T08:00', '2026-05-30T09:00'],
          'temperature_2m': [12.3, 14.1],
          'precipitation': [0.0, 1.2],
          'weathercode': [0, 61],
        }
      });
      final svc = WeatherService(
        client: MockClient((req) async => http.Response(body, 200)),
      );
      final r = await svc.fetchHourly(lat: 48, lng: 1);
      expect(r, isNotNull);
      expect(r!.hourly, hasLength(2));
      expect(r.hourly[1].tempC, 14.1);
      expect(r.hasRain, isTrue);
      expect(r.maxTempC, 14.1);
    });

    test('500 -> null', () async {
      final svc = WeatherService(
        client: MockClient((req) async => http.Response('err', 500)),
      );
      expect(await svc.fetchHourly(lat: 48, lng: 1), isNull);
    });

    test('reseau down -> null silencieux', () async {
      final svc = WeatherService(
        client: MockClient((req) async => throw Exception('down')),
      );
      expect(await svc.fetchHourly(lat: 48, lng: 1), isNull);
    });

    test('JSON sans hourly -> null', () async {
      final svc = WeatherService(
        client: MockClient(
            (req) async => http.Response(jsonEncode({'foo': 1}), 200)),
      );
      expect(await svc.fetchHourly(lat: 48, lng: 1), isNull);
    });

    test('hasRain false si toutes precip = 0', () {
      final f = WeatherForecast(hourly: [
        HourEntry(
          time: DateTime(2026, 5, 30, 8),
          tempC: 10,
          precipMm: 0,
          weatherCode: 0,
        ),
      ]);
      expect(f.hasRain, isFalse);
    });
  });
}
