import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/backup_service.dart';
import 'data/notifications_service.dart';
import 'providers/database_providers.dart';
import 'providers/geocoding_providers.dart';
import 'screens/app_lock_gate.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bloque le fetch HTTP de google_fonts : les .ttf Manrope +
  // JetBrainsMono sont desormais bundle en `assets/fonts/` (cf
  // pubspec.yaml). Sans ce flag, google_fonts essaye d'abord HTTP
  // au cold start, ce qui ralentit l'ouverture si offline et fait
  // crasher les widget_smoke_test (HTTP mock par TestWidgetsBinding).
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('fr_FR');
  // **CRITIQUE** : applique un eventuel restore en attente AVANT
  // d'ouvrir Drift. Si un fichier `.pending_restore` est present
  // (cf BackupService.prepareRestore), il sera swap a la place de la
  // DB courante. Sans ce check ici, Drift ouvre l'ancienne DB et le
  // swap ne se fait plus jamais.
  //
  // Skip en Web : path_provider.getApplicationDocumentsDirectory()
  // n'est pas implemente sur la plateforme web. Sans ce guard, le
  // build Flutter Web crashe au boot avec UnimplementedError et l'app
  // reste sur une page blanche (regression observee sur le 1er deploy
  // GitHub Pages 2026-05-14). La feature backup/restore zip n'a de
  // toute facon pas de sens en web (pas de stockage local pour la DB).
  if (!kIsWeb) {
    try {
      await BackupService.applyPendingRestoreIfAny();
    } catch (e) {
      // Best-effort : si l'I/O echoue on continue plutot que de bloquer
      // le boot complet. Le pire cas est qu'un restore manuel n'est
      // pas applique - l'utilisateur peut re-tenter via Parametres.
      debugPrint('[main] applyPendingRestoreIfAny failed: $e');
    }
  }
  // Init notifications locales (best-effort, ne pas bloquer le boot
  // si echec). En web : flutter_local_notifications fonctionne mais
  // sans permission notif systeme l'init ne fait rien.
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
    // Densite UI : 'large' multiplie le textScaleFactor par 1.15
    // (mode conduite / Mode XL).
    final densite =
        ref.watch(densiteUiProvider).asData?.value ?? 'normal';
    final textScaleBoost = densite == 'large' ? 1.15 : 1.0;

    // Demarre l'automate de re-geocodage hors-ligne. `ref.read` (et
    // pas `watch`) car on ne veut pas rebuilder a chaque tentative.
    // Le Provider auto-appelle start() a la 1ere lecture.
    ref.read(offlineGeocodeAutomationProvider);

    // Auto-backup local : check si la periode est echue et genere
    // un .zip dans /Android/data/.../files/auto_backups/. En arriere-
    // plan (unawaited) pour ne pas bloquer l'UI au demarrage.
    unawaited(ref.read(autoBackupServiceProvider).maybeRunAutoBackup());

    // Branche le ParametresRepository sur le NotificationsService
    // pour qu'il puisse consulter le creneau quiet hours avant chaque
    // notif immediate (showEndOfRouteSummary, showPendingStopsAlert).
    NotificationsService.instance
        .attachParametres(ref.read(parametresRepositoryProvider));

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
      builder: (context, child) {
        Widget wrapped = AppLockGate(child: child!);
        if (textScaleBoost == 1.0) return wrapped;
        final mq = MediaQuery.of(context);
        // Multiplie le scale systeme Android par notre boost. Ex :
        // user Android x1.3 + mode XL x1.15 = x1.495.
        final systemScale = mq.textScaler.scale(1.0);
        return MediaQuery(
          data: mq.copyWith(
            textScaler:
                TextScaler.linear(systemScale * textScaleBoost),
          ),
          child: wrapped,
        );
      },
    );
  }
}
