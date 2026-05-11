import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/theme/app_tokens.dart';

void main() {
  group('colorFromTag', () {
    test('null : retourne defaultColor', () {
      final c = colorFromTag(null, defaultColor: AppColors.cream);
      expect(c, AppColors.cream);
    });

    test('"lime" : AppColors.lime', () {
      final c = colorFromTag('lime', defaultColor: AppColors.cream);
      expect(c, AppColors.lime);
    });

    test('"emerald" : AppColors.emerald', () {
      final c = colorFromTag('emerald', defaultColor: AppColors.cream);
      expect(c, AppColors.emerald);
    });

    test('inconnu : fallback sur defaultColor', () {
      final c = colorFromTag('hot-pink', defaultColor: AppColors.lime);
      expect(c, AppColors.lime);
    });

    test('tous les tags exposes dans colorTagOptions resolvent', () {
      for (final (tag, expected) in colorTagOptions) {
        final c = colorFromTag(tag, defaultColor: const Color(0xFFFFFFFF));
        expect(c, expected, reason: 'tag $tag doit retourner $expected');
      }
    });
  });

  group('AppPalette - light vs dark', () {
    test('light : cream != ink', () {
      expect(AppPalette.light.cream, isNot(AppPalette.light.ink));
    });

    test('dark : inversion des roles', () {
      // En sombre : "cream" devient ink (#0E1410), "ink" devient cream
      expect(AppPalette.dark.cream, AppColors.ink);
      expect(AppPalette.dark.ink, AppColors.cream);
    });

    test('AppShadows constants disponibles', () {
      expect(AppShadows.card, isNotEmpty);
      expect(AppShadows.fab, isNotEmpty);
      expect(AppShadows.sheet, isNotEmpty);
    });
  });
}
