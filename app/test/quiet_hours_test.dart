import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/parametres_repository.dart';

void main() {
  group('ParametresRepository.isWithinQuietHours', () {
    /// Helper : crée un DateTime a l'heure HH:mm le 14/05/2026.
    DateTime at(int h, int m) => DateTime(2026, 5, 14, h, m);

    group('creneau dans la meme journee (start < end)', () {
      // ex : pause dejeuner 12h -> 14h
      test('avant le creneau : false', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(11, 30),
            startHHmm: '12:00',
            endHHmm: '14:00',
          ),
          false,
        );
      });

      test('au debut exact du creneau : true (inclusif start)', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(12, 0),
            startHHmm: '12:00',
            endHHmm: '14:00',
          ),
          true,
        );
      });

      test('au milieu du creneau : true', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(13, 15),
            startHHmm: '12:00',
            endHHmm: '14:00',
          ),
          true,
        );
      });

      test('a la fin exacte du creneau : false (exclusif end)', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(14, 0),
            startHHmm: '12:00',
            endHHmm: '14:00',
          ),
          false,
        );
      });

      test('apres le creneau : false', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(15, 30),
            startHHmm: '12:00',
            endHHmm: '14:00',
          ),
          false,
        );
      });
    });

    group('creneau qui passe minuit (start > end)', () {
      // ex : nuit 22h -> 06h
      test('avant le creneau : false', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(21, 30),
            startHHmm: '22:00',
            endHHmm: '06:00',
          ),
          false,
        );
      });

      test('au debut de soiree : true', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(22, 30),
            startHHmm: '22:00',
            endHHmm: '06:00',
          ),
          true,
        );
      });

      test('au milieu de la nuit (apres minuit) : true', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(2, 30),
            startHHmm: '22:00',
            endHHmm: '06:00',
          ),
          true,
        );
      });

      test('au lever : true (5h59)', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(5, 59),
            startHHmm: '22:00',
            endHHmm: '06:00',
          ),
          true,
        );
      });

      test('a la fin (6h00) : false', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(6, 0),
            startHHmm: '22:00',
            endHHmm: '06:00',
          ),
          false,
        );
      });

      test('en journee : false', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(12, 0),
            startHHmm: '22:00',
            endHHmm: '06:00',
          ),
          false,
        );
      });
    });

    group('cas degraderes', () {
      test('format HH:mm invalide : false', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(12, 0),
            startHHmm: 'plop',
            endHHmm: '14:00',
          ),
          false,
        );
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(12, 0),
            startHHmm: '12:00',
            endHHmm: '',
          ),
          false,
        );
      });

      test('heures hors plage : false', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(12, 0),
            startHHmm: '25:00',
            endHHmm: '14:00',
          ),
          false,
        );
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(12, 0),
            startHHmm: '12:99',
            endHHmm: '14:00',
          ),
          false,
        );
      });

      test('start == end : creneau vide -> jamais quiet', () {
        expect(
          ParametresRepository.isWithinQuietHours(
            now: at(12, 0),
            startHHmm: '12:00',
            endHHmm: '12:00',
          ),
          false,
        );
      });
    });
  });

  group('ParametresRepository.parseHHmm', () {
    test('format valide -> tuple (h, m)', () {
      final r = ParametresRepository.parseHHmm('09:30');
      expect(r, isNotNull);
      expect(r!.hour, 9);
      expect(r.minute, 30);
    });

    test('null en entree -> null', () {
      expect(ParametresRepository.parseHHmm(null), isNull);
    });

    test('format invalide (pas de :) -> null', () {
      expect(ParametresRepository.parseHHmm('0930'), isNull);
    });

    test('heure hors borne -> null', () {
      expect(ParametresRepository.parseHHmm('25:00'), isNull);
      expect(ParametresRepository.parseHHmm('-1:30'), isNull);
    });

    test('minute hors borne -> null', () {
      expect(ParametresRepository.parseHHmm('12:60'), isNull);
      expect(ParametresRepository.parseHHmm('12:-1'), isNull);
    });

    test('non-numerique -> null', () {
      expect(ParametresRepository.parseHHmm('ab:cd'), isNull);
      expect(ParametresRepository.parseHHmm(''), isNull);
      expect(ParametresRepository.parseHHmm('12:'), isNull);
    });
  });
}
