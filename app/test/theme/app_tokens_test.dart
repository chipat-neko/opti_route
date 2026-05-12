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

  group('AppPalette - copyWith + lerp', () {
    test('copyWith sans override : meme palette', () {
      final p = AppPalette.light.copyWith();
      expect(p.cream, AppPalette.light.cream);
      expect(p.ink, AppPalette.light.ink);
    });

    test('copyWith override : nouvelle valeur appliquee', () {
      final p = AppPalette.light.copyWith(cream: const Color(0xFFAABBCC));
      expect(p.cream, const Color(0xFFAABBCC));
      // Les autres champs restent inchanges
      expect(p.ink, AppPalette.light.ink);
    });

    test('lerp(t=0) : valeur de depart', () {
      final p = AppPalette.light.lerp(AppPalette.dark, 0);
      expect(p.cream, AppPalette.light.cream);
    });

    test('lerp(t=1) : valeur d\'arrivee', () {
      final p = AppPalette.light.lerp(AppPalette.dark, 1);
      expect(p.cream, AppPalette.dark.cream);
    });
  });

  group('AppSpacing / AppRadius constants', () {
    test('AppSpacing : valeurs croissantes', () {
      expect(AppSpacing.x4, 4.0);
      expect(AppSpacing.x6, 6.0);
      expect(AppSpacing.x8, 8.0);
      expect(AppSpacing.x10, 10.0);
      expect(AppSpacing.x28, 28.0);
      // L'echelle est croissante
      expect(AppSpacing.x4 < AppSpacing.x28, isTrue);
    });

    test('AppRadius : valeurs croissantes', () {
      expect(AppRadius.r6, 6.0);
      expect(AppRadius.r28, 28.0);
      expect(AppRadius.r6 < AppRadius.r28, isTrue);
    });
  });
}
