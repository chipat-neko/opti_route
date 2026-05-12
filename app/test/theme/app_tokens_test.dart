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

  group('AppPalette - inversion dark', () {
    test('paper devient inkSoft (surface secondaire)', () {
      expect(AppPalette.dark.paper, AppColors.inkSoft);
    });

    test('inkSoft devient creamSoft', () {
      expect(AppPalette.dark.inkSoft, AppColors.creamSoft);
    });

    test('inkLine garde un contraste suffisant en sombre', () {
      // En sombre, inkLine = cream avec alpha 20% = (alpha 0x33)
      // Verifie que la couleur a bien un alpha < 255.
      final c = AppPalette.dark.inkLine;
      expect(c.a, lessThan(1.0));
    });

    test('divider en sombre : cream alpha 10%', () {
      final c = AppPalette.dark.divider;
      // alpha encode 0x1A / 255 ~= 0.10
      expect(c.a, closeTo(0.10, 0.02));
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

  group('colorFromTag - tags secondaires', () {
    test('"red" : AppColors.red', () {
      final c = colorFromTag('red', defaultColor: AppColors.cream);
      expect(c, AppColors.red);
    });

    test('"amber" : AppColors.amber', () {
      final c = colorFromTag('amber', defaultColor: AppColors.cream);
      expect(c, AppColors.amber);
    });

    test('"cream" : AppColors.creamSoft', () {
      // Note : "cream" tag mappe a creamSoft (pas cream pur) pour
      // garder un peu de contraste avec le fond.
      final c = colorFromTag('cream', defaultColor: AppColors.lime);
      expect(c, AppColors.creamSoft);
    });

    test('"ink" : AppColors.ink', () {
      final c = colorFromTag('ink', defaultColor: AppColors.lime);
      expect(c, AppColors.ink);
    });

    test('case sensitive : "LIME" majuscules : fallback', () {
      // colorFromTag est strict lowercase. Si quelqu'un envoie
      // "LIME", on retombe sur defaultColor.
      final c = colorFromTag('LIME', defaultColor: AppColors.cream);
      expect(c, AppColors.cream);
    });

    test('chaine vide : fallback', () {
      final c = colorFromTag('', defaultColor: AppColors.amber);
      expect(c, AppColors.amber);
    });
  });

  group('colorTagOptions', () {
    test('liste non vide', () {
      expect(colorTagOptions, isNotEmpty);
    });

    test('contient au moins 4 entrees (lime/emerald/amber/red)', () {
      expect(colorTagOptions.length, greaterThanOrEqualTo(4));
    });

    test('contient lime', () {
      final tags = colorTagOptions.map((e) => e.$1).toList();
      expect(tags, contains('lime'));
    });
  });

  group('AppPalette.lerp - mix intermediaire', () {
    test('lerp(t=0.5) : valeur intermediaire entre les 2 palettes', () {
      final mid = AppPalette.light.lerp(AppPalette.dark, 0.5);
      // Le cream lerp(0.5) doit etre entre cream (0xFFF5F3EE) et
      // ink (0xFF0E1410) : un gris moyen.
      // On verifie juste que ce n'est ni l'un ni l'autre.
      expect(mid.cream, isNot(AppPalette.light.cream));
      expect(mid.cream, isNot(AppPalette.dark.cream));
    });

    test('lerp(other non-AppPalette) : retourne this', () {
      // ThemeExtension d'un autre type -> on retourne soi-meme.
      // Ici on passe null force via cast, mais l'impl protege via
      // `if (other is! AppPalette) return this;`
      final p = AppPalette.light;
      // ignore: avoid_dynamic_calls
      final result = p.lerp(null, 0.5);
      expect(result, p);
    });
  });

  group('AppShadows - structure', () {
    test('card : 1 ombre', () {
      expect(AppShadows.card.length, 1);
    });

    test('fab : 1 ombre', () {
      expect(AppShadows.fab.length, 1);
    });

    test('sheet : offset Y negatif (ombre vers le haut)', () {
      expect(AppShadows.sheet.first.offset.dy, lessThan(0));
    });
  });

  group('AppThemePreset - catalogue', () {
    test('all : contient 4 presets', () {
      expect(AppThemePreset.all.length, 4);
    });

    test('all : noms distincts', () {
      final names = AppThemePreset.all.map((p) => p.name).toSet();
      expect(names.length, 4);
      expect(names, containsAll(['lime', 'ocean', 'terracotta', 'mono']));
    });

    test('fromName : retourne le bon preset', () {
      expect(AppThemePreset.fromName('lime').name, 'lime');
      expect(AppThemePreset.fromName('ocean').name, 'ocean');
      expect(AppThemePreset.fromName('terracotta').name, 'terracotta');
      expect(AppThemePreset.fromName('mono').name, 'mono');
    });

    test('fromName : fallback sur lime si nom inconnu', () {
      expect(AppThemePreset.fromName('inexistant').name, 'lime');
      expect(AppThemePreset.fromName(null).name, 'lime');
      expect(AppThemePreset.fromName('').name, 'lime');
    });

    test('lime : pointe sur AppPalette.light/dark (alias historique)',
        () {
      expect(AppThemePreset.lime.light, AppPalette.light);
      expect(AppThemePreset.lime.dark, AppPalette.dark);
    });

    test('chaque preset : light != dark (vraie inversion)', () {
      for (final p in AppThemePreset.all) {
        expect(p.light.cream, isNot(p.dark.cream),
            reason: '${p.name} : light.cream doit differ de dark.cream');
        expect(p.light.ink, isNot(p.dark.ink),
            reason: '${p.name} : light.ink doit differ de dark.ink');
      }
    });

    test('chaque preset : previewColor non null', () {
      for (final p in AppThemePreset.all) {
        expect(p.previewColor, isNotNull, reason: p.name);
      }
    });

    test('ocean : surfaces bleutees (cream avec une teinte bleue)', () {
      // L'octet "bleu" du cream doit etre >= aux autres (B >= R, G)
      final cream = AppPalette.oceanLight.cream;
      expect(cream.b.round(), greaterThanOrEqualTo(cream.r.round() - 5));
    });

    test('mono light : background blanc (#FAFAFA)', () {
      expect(AppPalette.monoLight.cream, const Color(0xFFFAFAFA));
      expect(AppPalette.monoLight.paper, const Color(0xFFFFFFFF));
    });

    test('mono dark : noir pur (#0A0A0A)', () {
      expect(AppPalette.monoDark.cream, const Color(0xFF0A0A0A));
    });
  });

  group('AppPaletteContext extension', () {
    testWidgets('context.palette : retourne AppPalette.light par defaut',
        (tester) async {
      AppPalette? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppPalette.light],
          ),
          home: Builder(
            builder: (ctx) {
              captured = ctx.palette;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, isNotNull);
      expect(captured!.cream, AppColors.cream);
    });

    testWidgets('context.palette : retourne AppPalette.dark dans theme dark',
        (tester) async {
      AppPalette? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppPalette.dark],
          ),
          home: Builder(
            builder: (ctx) {
              captured = ctx.palette;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured, isNotNull);
      expect(captured!.cream, AppColors.ink);
    });

    testWidgets('context.palette : fallback sur light si extension absente',
        (tester) async {
      AppPalette? captured;
      await tester.pumpWidget(
        MaterialApp(
          // pas d'extensions
          home: Builder(
            builder: (ctx) {
              captured = ctx.palette;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured!.cream, AppColors.cream);
    });
  });
}
