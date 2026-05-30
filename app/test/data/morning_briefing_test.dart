import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/morning_briefing.dart';

void main() {
  group('MorningBriefing.composeTts (#317)', () {
    test('minimal', () {
      final s = MorningBriefing.composeTts(
        tourneeName: 'Lundi',
        nbStops: 12,
        nbColis: 18,
      );
      expect(s, contains('Lundi'));
      expect(s, contains('12 arrêts'));
      expect(s, contains('18 colis'));
    });
    test('avec meteo + zones', () {
      final s = MorningBriefing.composeTts(
        tourneeName: 'Lundi',
        nbStops: 5,
        nbColis: 5,
        meteoSummary: 'pluie attendue, max 14°C',
        riskZonesCp: ['28000', '28100', '28190', '99999'],
      );
      expect(s, contains('pluie'));
      expect(s, contains('28000'));
      expect(s, contains('28190'));
      expect(s, isNot(contains('99999')), reason: 'limite a 3 zones');
    });
    test('1 colis singulier', () {
      final s = MorningBriefing.composeTts(
        tourneeName: 'T', nbStops: 1, nbColis: 1);
      expect(s, contains('1 colis'));
    });
  });

  group('MorningBriefing.composeMeteoLine (#317)', () {
    test('pluie + max 12', () {
      final s = MorningBriefing.composeMeteoLine(
          hasRain: true, maxTempC: 12);
      expect(s, contains('pluie'));
      expect(s, contains('12'));
    });
    test('sec + canicule', () {
      final s = MorningBriefing.composeMeteoLine(
          hasRain: false, maxTempC: 35);
      expect(s, contains('canicule'));
    });
    test('sec normal', () {
      final s = MorningBriefing.composeMeteoLine(
          hasRain: false, maxTempC: 20);
      expect(s, contains('temps sec'));
    });
  });
}
