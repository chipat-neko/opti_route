import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/theme/app_tokens.dart';

// Note : on ne teste pas directement `buildAppTheme()` / `buildAppThemeDark()`
// car ils chargent une font GoogleFonts (Manrope, JetBrains Mono) ce qui
// declenche un appel reseau en CI Ubuntu (sans cache), qui timeout.
// On teste donc directement les `AppPalette.light` et `AppPalette.dark`
// constantes, qui sont injectees telles quelles dans le ThemeData.

void main() {
  group('AppPalette - light vs dark (utilises par buildAppTheme)', () {
    test('light : cream est le fond clair', () {
      expect(AppPalette.light.cream, AppColors.cream);
      expect(AppPalette.light.ink, AppColors.ink);
    });

    test('dark : inversion des roles cream <-> ink', () {
      // En sombre : "cream" devient ink (#0E1410), "ink" devient cream
      expect(AppPalette.dark.cream, AppColors.ink);
      expect(AppPalette.dark.ink, AppColors.cream);
    });

    test('light textMute < ink en luminance', () {
      // textMute doit etre plus pale que ink (pour les sous-titres).
      // On verifie via la moyenne RGB approximative.
      final mute = AppPalette.light.textMute;
      final ink = AppPalette.light.ink;
      final muteAvg = (mute.r + mute.g + mute.b) * 255 ~/ 3;
      final inkAvg = (ink.r + ink.g + ink.b) * 255 ~/ 3;
      expect(muteAvg, greaterThan(inkAvg),
          reason: 'textMute doit etre plus clair que ink');
    });
  });
}
