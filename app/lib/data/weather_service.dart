import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client open-meteo (gratuit, sans cle) pour afficher la meteo de la
/// tournee du jour. Carte #295.
///
/// Endpoint : https://api.open-meteo.com/v1/forecast
/// Best-effort : si pas de reseau ou erreur HTTP, retourne null.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Recupere la meteo horaire (temp, precip, code) pour [lat,lng]
  /// sur les prochaines 12h. Retourne null en cas d'erreur.
  Future<WeatherForecast?> fetchHourly({
    required double lat,
    required double lng,
  }) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'hourly': 'temperature_2m,precipitation,weathercode',
        'forecast_days': '1',
        'timezone': 'auto',
      });
      final resp = await _client
          .get(uri, headers: {'User-Agent': 'opti_route/0.1'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body);
      if (j is! Map) return null;
      final hourly = j['hourly'];
      if (hourly is! Map) return null;
      final times = (hourly['time'] as List?)?.cast<String>() ?? const [];
      final temps =
          (hourly['temperature_2m'] as List?)?.cast<num>() ?? const [];
      final precs =
          (hourly['precipitation'] as List?)?.cast<num>() ?? const [];
      final codes =
          (hourly['weathercode'] as List?)?.cast<num>() ?? const [];
      if (times.isEmpty) return null;
      final entries = <HourEntry>[];
      for (var i = 0; i < times.length; i++) {
        entries.add(HourEntry(
          time: DateTime.parse(times[i]),
          tempC: i < temps.length ? temps[i].toDouble() : 0,
          precipMm: i < precs.length ? precs[i].toDouble() : 0,
          weatherCode: i < codes.length ? codes[i].toInt() : 0,
        ));
      }
      return WeatherForecast(hourly: entries);
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}

class WeatherForecast {
  const WeatherForecast({required this.hourly});
  final List<HourEntry> hourly;

  bool get hasRain => hourly.any((h) => h.precipMm > 0.5);
  double get maxTempC =>
      hourly.isEmpty ? 0 : hourly.map((h) => h.tempC).reduce((a, b) => a > b ? a : b);
}

class HourEntry {
  const HourEntry({
    required this.time,
    required this.tempC,
    required this.precipMm,
    required this.weatherCode,
  });
  final DateTime time;
  final double tempC;
  final double precipMm;
  final int weatherCode;
}
