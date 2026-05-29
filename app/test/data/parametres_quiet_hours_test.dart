import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/parametres_repository.dart';

// Premier test pour les helpers PURS de ParametresRepository :
// isWithinQuietHours (creneau journee / passage minuit) et parseHHmm.
void main() {
  // Date arbitraire, seule la partie heure/minute compte.
  DateTime at(int h, int m) => DateTime(2026, 5, 29, h, m);

  group('ParametresRepository.isWithinQuietHours — creneau meme journee',
      () {
    test('debut == fin : creneau vide -> false', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(12, 0),
          startHHmm: '12:00',
          endHHmm: '12:00',
        ),
        isFalse,
      );
    });

    test('avant le start : false', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(11, 59),
          startHHmm: '12:00',
          endHHmm: '14:00',
        ),
        isFalse,
      );
    });

    test('pile au start : true (inclusif)', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(12, 0),
          startHHmm: '12:00',
          endHHmm: '14:00',
        ),
        isTrue,
      );
    });

    test('au milieu : true', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(13, 0),
          startHHmm: '12:00',
          endHHmm: '14:00',
        ),
        isTrue,
      );
    });

    test('pile au end : false (exclusif)', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(14, 0),
          startHHmm: '12:00',
          endHHmm: '14:00',
        ),
        isFalse,
      );
    });

    test('apres le end : false', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(14, 1),
          startHHmm: '12:00',
          endHHmm: '14:00',
        ),
        isFalse,
      );
    });
  });

  group('ParametresRepository.isWithinQuietHours — passage minuit', () {
    test('22h -> 06h : 22h45 -> true', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(22, 45),
          startHHmm: '22:00',
          endHHmm: '06:00',
        ),
        isTrue,
      );
    });

    test('22h -> 06h : 23h59 -> true', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(23, 59),
          startHHmm: '22:00',
          endHHmm: '06:00',
        ),
        isTrue,
      );
    });

    test('22h -> 06h : 00h00 -> true (debut de la 2e moitie)', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(0, 0),
          startHHmm: '22:00',
          endHHmm: '06:00',
        ),
        isTrue,
      );
    });

    test('22h -> 06h : 05h59 -> true', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(5, 59),
          startHHmm: '22:00',
          endHHmm: '06:00',
        ),
        isTrue,
      );
    });

    test('22h -> 06h : 06h00 pile -> false (fin exclusive)', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(6, 0),
          startHHmm: '22:00',
          endHHmm: '06:00',
        ),
        isFalse,
      );
    });

    test('22h -> 06h : 12h00 -> false (hors creneau)', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(12, 0),
          startHHmm: '22:00',
          endHHmm: '06:00',
        ),
        isFalse,
      );
    });
  });

  group('ParametresRepository.isWithinQuietHours — formats invalides', () {
    test('start invalide -> false', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(12, 0),
          startHHmm: 'abc',
          endHHmm: '14:00',
        ),
        isFalse,
      );
    });

    test('end invalide -> false', () {
      expect(
        ParametresRepository.isWithinQuietHours(
          now: at(12, 0),
          startHHmm: '12:00',
          endHHmm: 'xyz',
        ),
        isFalse,
      );
    });
  });

  group('ParametresRepository.parseHHmm', () {
    test('format valide HH:mm -> tuple', () {
      final r = ParametresRepository.parseHHmm('14:30');
      expect(r, isNotNull);
      expect(r!.hour, 14);
      expect(r.minute, 30);
    });

    test('null -> null', () {
      expect(ParametresRepository.parseHHmm(null), isNull);
    });

    test('chaine vide -> null', () {
      expect(ParametresRepository.parseHHmm(''), isNull);
    });

    test('sans deux-points -> null', () {
      expect(ParametresRepository.parseHHmm('1430'), isNull);
    });

    test('heure hors borne (24) -> null', () {
      expect(ParametresRepository.parseHHmm('24:00'), isNull);
    });

    test('minute hors borne (60) -> null', () {
      expect(ParametresRepository.parseHHmm('14:60'), isNull);
    });

    test('valeurs negatives -> null', () {
      expect(ParametresRepository.parseHHmm('-1:00'), isNull);
    });

    test('00:00 minuit pile -> valide', () {
      final r = ParametresRepository.parseHHmm('00:00');
      expect(r!.hour, 0);
      expect(r.minute, 0);
    });

    test('23:59 dernier moment -> valide', () {
      final r = ParametresRepository.parseHHmm('23:59');
      expect(r!.hour, 23);
      expect(r.minute, 59);
    });
  });
}
