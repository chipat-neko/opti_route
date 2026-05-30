/// Briefing matinal 60s : météo + nb colis + zones à risque + meteo
/// (carte #317). Pure fn qui compose le texte TTS. Le caller fait
/// `FlutterTts.speak`.
class MorningBriefing {
  MorningBriefing._();

  /// Compose le texte TTS court (~60 s) à dire au pointage début
  /// service (#279) sur la 1ère tournée du jour.
  static String composeTts({
    required String tourneeName,
    required int nbStops,
    required int nbColis,
    String? meteoSummary,
    List<String> riskZonesCp = const [],
  }) {
    final parts = <String>[
      'Bonjour. Tournée du jour : $tourneeName.',
      '$nbStops arrêts, ${nbColis == 1 ? '1 colis' : '$nbColis colis'}.',
    ];
    if (meteoSummary != null && meteoSummary.trim().isNotEmpty) {
      parts.add('Météo : $meteoSummary.');
    }
    if (riskZonesCp.isNotEmpty) {
      final cps = riskZonesCp.take(3).join(', ');
      parts.add('Attention zones à risque : $cps.');
    }
    parts.add('Bonne tournée.');
    return parts.join(' ');
  }

  /// Compose une phrase météo simple depuis un WeatherForecast (cf
  /// #295). Sans dépendre du type pour rester pure.
  static String composeMeteoLine({
    required bool hasRain,
    required double maxTempC,
  }) {
    final buf = StringBuffer();
    if (hasRain) buf.write('pluie attendue');
    if (maxTempC > 30) {
      if (buf.isNotEmpty) buf.write(', ');
      buf.write('canicule jusqu\'à ${maxTempC.round()}°C');
    } else if (maxTempC > 0) {
      if (buf.isEmpty) {
        buf.write('temps sec, jusqu\'à ${maxTempC.round()}°C');
      } else {
        buf.write(', max ${maxTempC.round()}°C');
      }
    }
    return buf.toString();
  }
}
