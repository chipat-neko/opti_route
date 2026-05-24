// Tests des regex centralisees dans BordereauPatterns. Verifie chaque
// pattern sur les cas d'usage typiques + cas limites observes sur les
// vrais bordereaux Noah (2026-05-22).
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_patterns.dart';

void main() {
  group('BordereauPatterns.cpVilleRegex', () {
    test('match format standard 28190 COURVILLE SUR EURE', () {
      final m = BordereauPatterns.cpVilleRegex.firstMatch(
        '28190 COURVILLE SUR EURE',
      );
      expect(m, isNotNull);
      expect(m!.group(1), '28190');
      expect(m.group(2)!.trim(), 'COURVILLE SUR EURE');
    });

    test('match format FR-CP-VILLE Transports France Alliance', () {
      final m = BordereauPatterns.cpVilleRegex.firstMatch(
        'FR-28190-CHARTRES',
      );
      expect(m, isNotNull);
      expect(m!.group(1), '28190');
    });

    test('match format FR - CP - VILLE avec espaces', () {
      final m = BordereauPatterns.cpVilleRegex.firstMatch(
        'FR - 28190 - CHARTRES',
      );
      expect(m, isNotNull);
      expect(m!.group(1), '28190');
    });

    test('ne matche PAS au milieu d\'un long numero', () {
      // Cas reel : "0237911586 THEODORE CHARTRES" ne doit PAS donner
      // "11586 THEODORE" (\b interdit le match au milieu du tel).
      final m = BordereauPatterns.cpVilleRegex.firstMatch(
        '0237911586 THEODORE CHARTRES',
      );
      // \b est respecte, donc le 11586 ne matche pas (precede de chiffres).
      expect(m, isNull);
    });
  });

  group('BordereauPatterns.cpRegex', () {
    test('extrait 5 chiffres isoles', () {
      final m = BordereauPatterns.cpRegex.firstMatch('Adresse 28190 ici');
      expect(m, isNotNull);
      expect(m!.group(1), '28190');
    });

    test('ne matche pas au milieu d\'un numero plus long', () {
      // 123456 ne doit pas etre matche comme 12345 (besoin word boundary)
      final m = BordereauPatterns.cpRegex.firstMatch('REF 123456789');
      expect(m, isNull);
    });
  });

  group('BordereauPatterns.telRegex', () {
    test('match 06 12 34 56 78 avec espaces', () {
      final m = BordereauPatterns.telRegex.firstMatch('Tel: 06 12 34 56 78');
      expect(m, isNotNull);
      expect(m!.group(1), '06 12 34 56 78');
    });

    test('match 06.12.34.56.78 avec points', () {
      final m = BordereauPatterns.telRegex.firstMatch('06.12.34.56.78');
      expect(m, isNotNull);
    });

    test('match 0612345678 sans separateur', () {
      final m = BordereauPatterns.telRegex.firstMatch('0612345678');
      expect(m, isNotNull);
      expect(m!.group(1), '0612345678');
    });

    test('telSepRegex strip les separateurs', () {
      final normalized = '06 12.34-56 78'.replaceAll(
        BordereauPatterns.telSepRegex,
        '',
      );
      expect(normalized, '0612345678');
    });
  });

  group('BordereauPatterns.chronopostTrackingRegex', () {
    test('match XR123456789FR', () {
      expect(
        BordereauPatterns.chronopostTrackingRegex.hasMatch('XR123456789FR'),
        isTrue,
      );
    });

    test('match XE123456789FR (case insensitive)', () {
      expect(
        BordereauPatterns.chronopostTrackingRegex.hasMatch('xe987654321fr'),
        isTrue,
      );
    });

    test('ne matche pas un Colissimo 6A...', () {
      expect(
        BordereauPatterns.chronopostTrackingRegex.hasMatch('6A12345678'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.streetLineRegex', () {
    test('match "24 AVENUE LOUIS PASTEUR"', () {
      expect(
        BordereauPatterns.streetLineRegex.hasMatch('24 AVENUE LOUIS PASTEUR'),
        isTrue,
      );
    });

    test('match "31 RUE ARISTIDE BRIAND"', () {
      expect(
        BordereauPatterns.streetLineRegex.hasMatch('31 RUE ARISTIDE BRIAND'),
        isTrue,
      );
    });

    test('match "12 bis RUE DES LILAS"', () {
      expect(
        BordereauPatterns.streetLineRegex.hasMatch('12 bis RUE DES LILAS'),
        isTrue,
      );
    });

    test('ne matche pas "GARAGE LANCTIN DAMIEN" (pas de chiffre initial)', () {
      expect(
        BordereauPatterns.streetLineRegex.hasMatch('GARAGE LANCTIN DAMIEN'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.bpPattern', () {
    test('match "BP 10077"', () {
      expect(BordereauPatterns.bpPattern.hasMatch('BP 10077'), isTrue);
    });

    test('match "BP10077" sans espace', () {
      expect(BordereauPatterns.bpPattern.hasMatch('BP10077'), isTrue);
    });

    test('ne matche pas "B P 10077" (espace au milieu)', () {
      expect(BordereauPatterns.bpPattern.hasMatch('B P 10077'), isFalse);
    });
  });

  group('BordereauPatterns.enlevementLabelRegex', () {
    test('match "ENLEVEMENT" tout seul', () {
      expect(
        BordereauPatterns.enlevementLabelRegex.hasMatch('ENLEVEMENT'),
        isTrue,
      );
    });

    test('match "ENLEVEMENT" dans une phrase', () {
      expect(
        BordereauPatterns.enlevementLabelRegex
            .hasMatch('Mode : ENLEVEMENT obligatoire'),
        isTrue,
      );
    });

    test('ne matche pas "enlevement" minuscule', () {
      expect(
        BordereauPatterns.enlevementLabelRegex.hasMatch('enlevement'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.upperCaseSequenceRegex', () {
    test('match "GARAGE LANCTIN DAMIEN"', () {
      final m = BordereauPatterns.upperCaseSequenceRegex
          .firstMatch('Texte avec GARAGE LANCTIN DAMIEN dedans');
      expect(m, isNotNull);
      expect(m!.group(1), 'GARAGE LANCTIN DAMIEN');
    });

    test('ne matche pas un seul mot majuscule (besoin de >= 2)', () {
      expect(
        BordereauPatterns.upperCaseSequenceRegex.hasMatch('GARAGE'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.colisSameLineRegex', () {
    test('match "Total colis : 3"', () {
      final m = BordereauPatterns.colisSameLineRegex
          .firstMatch('Total colis : 3');
      expect(m, isNotNull);
      expect(m!.group(1), '3');
    });

    test('match "colis: 12" sans espace avant : ', () {
      final m = BordereauPatterns.colisSameLineRegex.firstMatch('colis: 12');
      expect(m, isNotNull);
      expect(m!.group(1), '12');
    });

    test('case insensitive', () {
      final m = BordereauPatterns.colisSameLineRegex.firstMatch('COLIS: 5');
      expect(m, isNotNull);
    });

    test('Sprint OCR B-3 : match "PIECES AUTO. total colis: 1"', () {
      // page_25 batch_eval : prefixe metier avant le label.
      final m = BordereauPatterns.colisSameLineRegex
          .firstMatch('PIECES AUTO. total colis: 1');
      expect(m, isNotNull);
      expect(m!.group(1), '1');
    });

    test('Sprint OCR B-3 : match "Nb colis 5" (sans :)', () {
      final m = BordereauPatterns.colisSameLineRegex.firstMatch('Nb colis 5');
      expect(m, isNotNull);
      expect(m!.group(1), '5');
    });

    test('Sprint OCR B-3 : NE matche PAS le boilerplate "La remise des '
        'colis entraine l\'acceptation de nos conditions"', () {
      // Phrase legale presente sur 99% des bordereaux. Pas de chiffre
      // court apres "colis", donc safe.
      expect(
        BordereauPatterns.colisSameLineRegex.hasMatch(
          'La remise des colis entraine l\'acceptation de nos conditions',
        ),
        isFalse,
      );
    });

    test('Sprint OCR B-3 : NE matche PAS un CP de 5 chiffres apres colis', () {
      // Si un CP traine apres "colis" dans une ligne mal segmentee, on
      // ne doit pas capturer ses 2-3 premiers chiffres comme nbColis.
      expect(
        BordereauPatterns.colisSameLineRegex.hasMatch('colis 28190 CHARTRES'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.colisTotauxRegex (Sprint OCR B-3)', () {
    test('match "COLIS TOTAUX: 1" (page_33 Eure-et-Loir)', () {
      final m = BordereauPatterns.colisTotauxRegex
          .firstMatch('COLIS TOTAUX: 1');
      expect(m, isNotNull);
      expect(m!.group(1), '1');
    });

    test('case insensitive "colis totaux : 7"', () {
      final m = BordereauPatterns.colisTotauxRegex
          .firstMatch('colis totaux : 7');
      expect(m, isNotNull);
      expect(m!.group(1), '7');
    });

    test('ne matche pas "total colis : 3" (cas inverse couvert ailleurs)', () {
      // L'autre sens est couvert par colisSameLineRegex.
      expect(
        BordereauPatterns.colisTotauxRegex.hasMatch('total colis : 3'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.umFractionRegex (Sprint OCR B-3)', () {
    test('match "UM: 1/3" -> 3 (denominateur = total)', () {
      final m = BordereauPatterns.umFractionRegex.firstMatch('UM: 1/3');
      expect(m, isNotNull);
      expect(m!.group(1), '3');
    });

    test('match "U.M. 2/5"', () {
      final m = BordereauPatterns.umFractionRegex.firstMatch('U.M. 2/5');
      expect(m, isNotNull);
      expect(m!.group(1), '5');
    });

    test('match "u.m.: 1/1" (sans espace)', () {
      final m = BordereauPatterns.umFractionRegex.firstMatch('u.m.: 1/1');
      expect(m, isNotNull);
      expect(m!.group(1), '1');
    });

    test('match au milieu de "PaDs:8 KG UM: 1/3" (ligne agglomeree OCR)', () {
      // Bordereaux Eure-et-Loir ont souvent "PaDs:8 KG" + "UM: 1/1"
      // sur la meme ligne OCR.
      final m = BordereauPatterns.umFractionRegex
          .firstMatch('PaDs:8 KG UM: 1/3');
      expect(m, isNotNull);
      expect(m!.group(1), '3');
    });

    test('ne matche pas "1/3" sans prefixe UM', () {
      // On exige le label UM pour ne pas confondre avec des dates,
      // refs, ou autres fractions.
      expect(
        BordereauPatterns.umFractionRegex.hasMatch('1/3'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.unitColisLineRegex', () {
    test('match "1" entier seul', () {
      final m = BordereauPatterns.unitColisLineRegex.firstMatch('1');
      expect(m, isNotNull);
      expect(m!.group(1), '1');
    });

    test('match "1.0" decimal X.0', () {
      final m = BordereauPatterns.unitColisLineRegex.firstMatch('1.0');
      expect(m, isNotNull);
      expect(m!.group(1), '1');
    });

    test('match "2,0" virgule decimal', () {
      final m = BordereauPatterns.unitColisLineRegex.firstMatch('2,0');
      expect(m, isNotNull);
      expect(m!.group(1), '2');
    });

    test('ne matche pas "1.5" (decimal non zero)', () {
      // X.5 n'est pas une quantite valide d'U.M. (toujours entier).
      expect(
        BordereauPatterns.unitColisLineRegex.hasMatch('1.5'),
        isFalse,
      );
    });

    test('Sprint OCR B-3 ext : ne matche pas "75" (2 chiffres = '
        'probablement dpt/code, pas nb_colis)', () {
      // Plafond à 1 chiffre pour éviter faux positifs U.M. dans
      // les tableaux MESEXP où "75" / "28" apparaissent comme
      // n° département ou autres champs.
      expect(
        BordereauPatterns.unitColisLineRegex.hasMatch('75'),
        isFalse,
      );
    });

    test('ne matche pas "100" (3 chiffres)', () {
      // Plafond a 9 pour eviter de matcher des codes / refs / dpts.
      expect(
        BordereauPatterns.unitColisLineRegex.hasMatch('100'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.trackingCodeRegex', () {
    test('match "270521 /6552AGNCMVZ04L" (lettres+chiffres adjacents)', () {
      expect(
        BordereauPatterns.trackingCodeRegex
            .hasMatch('270521 /6552AGNCMVZ04L'),
        isTrue,
      );
    });

    test('ne matche pas "GARAGE LANCTIN" (que des lettres)', () {
      expect(
        BordereauPatterns.trackingCodeRegex.hasMatch('GARAGE LANCTIN'),
        isFalse,
      );
    });
  });

  group('BordereauPatterns.digitsOnlyRegex', () {
    test('replaceAll garde uniquement les chiffres', () {
      expect(
        'FA280000440358'.replaceAll(BordereauPatterns.digitsOnlyRegex, ''),
        '280000440358',
      );
    });
  });
}
