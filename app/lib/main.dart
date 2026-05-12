import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/notifications_service.dart';
import 'providers/database_providers.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  // Init notifications locales (best-effort, ne pas bloquer le boot
  // si echec).
  unawaited(NotificationsService.instance.init());
  runApp(const ProviderScope(child: OptiRouteApp()));
}

class OptiRouteApp extends ConsumerWidget {
  const OptiRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mode de theme depuis Parametres ; default ThemeMode.system tant
    // que le stream n'a pas encore emis (1er frame).
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
    // Preset de palette choisi par l'utilisateur. Default lime tant
    // que le stream n'a pas emis.
    final preset = ref.watch(themePresetProvider).asData?.value ??
        AppThemePreset.lime;

    return MaterialApp(
      title: 'opti_route',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(preset: preset),
      darkTheme: buildAppThemeDark(preset: preset),
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),
      home: const HomeScreen(),
    );
  }
}
