import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/notifications_service.dart';
import 'providers/database_providers.dart';
import 'screens/home_screen.dart';
import 'services/share_intent_handler.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  // Init notifications locales (best-effort, ne pas bloquer le boot
  // si echec).
  unawaited(NotificationsService.instance.init());
  // Init du handler Share Intent : recupere les adresses partagees
  // depuis Google Maps (menu "Partager -> opti_route").
  unawaited(ShareIntentHandler.instance.init());
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

    return MaterialApp(
      title: 'opti_route',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppThemeDark(),
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
