import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/theme/app_theme.dart';
import 'package:opti_route/theme/app_tokens.dart';

void main() {
  group('buildAppTheme()', () {
    test('expose une AppPalette light', () {
      final t = buildAppTheme();
      final p = t.extension<AppPalette>();
      expect(p, isNotNull);
      // En mode clair : cream est le fond clair
      expect(p!.cream, AppColors.cream);
      expect(p.ink, AppColors.ink);
    });

    test('brightness = light', () {
      final t = buildAppTheme();
      expect(t.brightness, Brightness.light);
    });
  });

  group('buildAppThemeDark()', () {
    test('expose une AppPalette dark (inversion)', () {
      final t = buildAppThemeDark();
      final p = t.extension<AppPalette>();
      expect(p, isNotNull);
      // En mode sombre : "cream" = ink (#0E1410), "ink" = cream
      expect(p!.cream, AppColors.ink);
      expect(p.ink, AppColors.cream);
    });

    test('brightness = dark', () {
      final t = buildAppThemeDark();
      expect(t.brightness, Brightness.dark);
    });
  });
}
