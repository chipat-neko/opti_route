import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/backup_service.dart';
import 'data/battery_monitor_service.dart';
import 'data/notifications_service.dart';
import 'data/share_intent_service.dart';
import 'data/supabase_service.dart';
import 'providers/database_providers.dart';
import 'providers/geocoding_providers.dart';
import 'providers/supabase_providers.dart';
import 'screens/app_lock_gate.dart';
import 'screens/bulk_paste_screen.dart';
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
  // Init Supabase (Phase 2 backend cloud, jalon 1 = auth seule).
  // No-op silencieux si --dart-define SUPABASE_URL pas fourni.
  // L'app continue de fonctionner en mode local-only.
  unawaited(SupabaseService.instance.init());
  runApp(const ProviderScope(child: OptiRouteApp()));
}

/// Singleton du service de reception des partages externes
/// (ACTION_SEND Android). L'init est differe dans le build d'
/// OptiRouteApp pour pouvoir ecouter le stream avec acces au
/// Navigator (push BulkPasteScreen pre-rempli).
final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  final svc = ShareIntentService();
  // Init lazy : la 1ere lecture du provider declenche l'ecoute.
  unawaited(svc.init());
  ref.onDispose(svc.dispose);
  return svc;
});

/// Stream des adresses partagees (ACTION_SEND) expose en provider, pour
/// l'ecouter via ref.listen sans creer un nouvel abonnement a chaque
/// rebuild de build() (carte #263 : .listen() dans build fuyait).
final _sharedAddressProvider = StreamProvider(
  (ref) => ref.watch(shareIntentServiceProvider).addressStream,
);

/// GlobalKey pour pouvoir push une route depuis le listener
/// share_intent (qui s'execute hors d'un BuildContext). Set sur le
/// MaterialApp dans OptiRouteApp.
final _navigatorKey = GlobalKey<NavigatorState>();

class OptiRouteApp extends ConsumerWidget {
  const OptiRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mode de theme effectif : si le mode auto luminosite est ON et
    // que le capteur a emis au moins une valeur, on override le choix
    // user. Sinon retombe sur le choix user (system / light / dark).
    // Voir carte Trello #95.
    final themeMode = ref.watch(effectiveThemeModeProvider);
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

    // Demarre la surveillance batterie (carte #258) : notif quand le
    // niveau passe sous le seuil bas en tournee. Auto-start a la 1ere
    // lecture, comme l'automate de re-geocodage.
    ref.read(batteryMonitorServiceProvider);

    // Auto-backup local : check si la periode est echue et genere
    // un .zip dans /Android/data/.../files/auto_backups/. En arriere-
    // plan (unawaited) pour ne pas bloquer l'UI au demarrage.
    unawaited(ref.read(autoBackupServiceProvider).maybeRunAutoBackup());

    // Tournees recurrentes (carte #113) : genere a l'ouverture de l'app
    // les tournees dont la recurrence cible aujourd'hui (dedup intra-jour).
    // En arriere-plan, best-effort. Pas de WorkManager (cf RecurrenceService).
    unawaited(ref.read(recurrenceServiceProvider).runDue());

    // Applique le flag Android FLAG_SECURE selon le toggle "masquer
    // dans le selecteur d'apps" (carte #111). Reactif : le listener se
    // declenche a la 1ere emission du stream (etat initial au demarrage)
    // puis a chaque bascule du toggle dans Parametres > Securite. No-op
    // hors Android.
    ref.listen<AsyncValue<bool>>(secureScreenEnabledProvider, (_, next) {
      final enabled = next.asData?.value;
      if (enabled != null) {
        ref.read(secureScreenServiceProvider).setSecure(enabled);
      }
    });

    // Branche le ParametresRepository sur le NotificationsService
    // pour qu'il puisse consulter le creneau quiet hours avant chaque
    // notif immediate (showEndOfRouteSummary, showPendingStopsAlert).
    NotificationsService.instance
        .attachParametres(ref.read(parametresRepositoryProvider));

    // Auto-pull Supabase a chaque sign-in d'un user (Phase 2 jalon
    // 2.D-1d). Safe meme apres un sign-in repete grace au last-write-
    // wins fin du 2.D-1c : les rows locales plus recentes que le cloud
    // sont preservees, on n'ecrase plus aveuglement.
    //
    // Use cases :
    // - 1er install : recupere toutes les tournees existantes
    // - Sign-in apres une session sur un 2e device : recupere les
    //   modifs faites ailleurs depuis le dernier sign-in
    // - Re-sign-in apres logout : idem
    // Reception des partages Android (ACTION_SEND text/plain) :
    // l'utilisateur fait 'Partager -> opti_route' depuis Google Maps,
    // SMS, mail, etc. On parse le texte, on cherche la tournee active
    // (en_cours ou aujourd'hui), et on push BulkPasteScreen pre-rempli.
    // Si pas de tournee active : SnackBar invite a en creer une d'abord.
    ref.listen(shareIntentServiceProvider, (_, _) {
      // Force l'init du provider (le listen() ne lit pas le state si
      // on ne fait rien d'autre).
    });
    // Carte #263 : ref.listen sur un StreamProvider au lieu de
    // shareSvc.addressStream.listen() (qui se reabonnait a chaque rebuild
    // de build() -> fuite de listeners + navigation dupliquee).
    ref.listen(_sharedAddressProvider, (_, next) async {
      final shared = next.asData?.value;
      if (shared == null) return;
      // Cherche une tournee active (en_cours OU date=aujourd'hui).
      final current = ref.read(currentTourneeProvider).asData?.value;
      final nav = _navigatorKey.currentState;
      if (nav == null) return;
      // nav.context est stable (le Navigator survit aux awaits, c'est
      // un GlobalKey). L'analyseur ne peut pas le prouver, on ignore
      // le warning use_build_context_synchronously.
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(nav.context);
      if (current == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Adresse recue mais pas de tournee aujourd\'hui. '
              'Cree-en une d\'abord puis re-partage.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      // Pre-remplit avec le nom et / ou l'URL recue. Le BulkPasteScreen
      // ne sait pas encore parser l'URL Google Maps pour en extraire
      // coords, mais pour l'instant on push le nom + URL en 2 lignes ;
      // l'utilisateur peut ajuster avant import.
      final lines = <String>[
        if (shared.name != null) shared.name!,
        if (shared.sourceUrl != null) shared.sourceUrl!,
      ];
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => BulkPasteScreen(
            tourneeId: current.id,
            initialText: lines.join('\n'),
          ),
        ),
      );
    });

    ref.listen(cloudUserProvider, (prev, next) {
      final user = next.value;
      if (user == null) {
        // Sign-out : stop l'auto-push carnet (sera redemarre au prochain
        // sign-in). Le snapshot des updatedAt connus est conserve dans
        // le service pour eviter de re-push tout le carnet au reconnect.
        ref.read(carnetAutoPushServiceProvider).stop();
        return;
      }
      final notifier = ref.read(cloudPullStateProvider.notifier);
      notifier.set(const AsyncLoading());
      ref
          .read(cloudAutoPullServiceProvider)
          .runAutoPullOnSignIn()
          .then((result) {
        notifier.set(AsyncData(result));
        // Demarre l'auto-push carnet apres le pull initial : la baseline
        // (1er emit du watch Drift) sera donc post-pull, et l'auto-push
        // ne se declenchera que sur les modifs locales reelles -- pas
        // sur le retro-push pour les rows pull du serveur. Cf carte #57 V2.
        ref.read(carnetAutoPushServiceProvider).start();
      }, onError: (Object e, StackTrace st) {
        notifier.set(AsyncError(e, st));
      });
    });

    return MaterialApp(
      title: 'opti_route',
      navigatorKey: _navigatorKey,
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
