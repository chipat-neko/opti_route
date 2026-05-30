import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/sector_color.dart';

void main() {
  group('SectorColor.forCp (#293)', () {
    test('cp vide ou ? -> gris', () {
      const grey = Color(0xFF9E9E9E);
      expect(SectorColor.forCp(''), grey);
      expect(SectorColor.forCp('?'), grey);
    });

    test('meme cp -> meme couleur (stable)', () {
      expect(SectorColor.forCp('28000'), SectorColor.forCp('28000'));
      expect(SectorColor.forCp('78250'), SectorColor.forCp('78250'));
    });

    test('cps differents donnent souvent des couleurs differentes', () {
      // Probabilite de collision : 1/8 -> on test plusieurs paires
      // pour s'assurer qu'au moins une couleur differente sort.
      final colors = {
        SectorColor.forCp('28000'),
        SectorColor.forCp('78250'),
        SectorColor.forCp('75001'),
        SectorColor.forCp('44000'),
      };
      expect(colors.length, greaterThan(1));
    });

    test('toutes les couleurs sortent de la palette', () {
      final palette = SectorColor.palette.toSet();
      for (final cp in ['28000', '78250', '75001', '44000', '13000']) {
        final c = SectorColor.forCp(cp);
        expect(palette.contains(c), isTrue,
            reason: 'couleur $c hors palette pour cp $cp');
      }
    });
  });
}
