import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'parametres_repository.dart';

/// Service de notifications locales (rappels "tournee a preparer",
/// "tournee non finie", + tests). 100% local au telephone via
/// flutter_local_notifications, aucune CB / backend / Firebase.
///
/// Note migration v18 -> v21 : toutes les methodes du plugin sont
/// passees aux named parameters (breaking change v20). Le param
/// `uiLocalNotificationDateInterpretation` a aussi ete retire de
/// `zonedSchedule` en v19 -- les notifs iOS l'utilisent dorenavant
/// implicitement comme "absoluteTime".
class NotificationsService {
  NotificationsService._();
  static final instance = NotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Reference optionnelle au ParametresRepository pour pouvoir
  /// consulter le creneau quiet hours avant chaque notif immediate.
  /// Branche au boot via [attachParametres] - sans ca, les notifs
  /// passent toujours (comportement legacy).
  ParametresRepository? _params;

  /// Branche le ParametresRepository utilise pour respecter le mode
  /// "ne pas deranger" (quiet hours). Appele depuis main.dart au boot.
  void attachParametres(ParametresRepository params) {
    _params = params;
  }

  /// Vrai si on est actuellement dans le creneau quiet hours. Retourne
  /// false si `_params` non branche ou creneau non configure.
  /// Best-effort : en cas d'exception (Drift KO au boot), retourne
  /// false pour ne pas bloquer une notif legitime.
  Future<bool> _isQuietHours() async {
    if (_params == null) return false;
    try {
      return await _params!.isQuietHoursNow();
    } catch (e) {
      debugPrint('[NotificationsService] quiet hours check failed: $e');
      return false;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    // Local timezone : on prend Europe/Paris par defaut (Noah). Si on
    // veut etre plus general, on detecterait via flutter_timezone.
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);

    // Demande la permission pour Android 13+ (POST_NOTIFICATIONS).
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    // Permission de planifier des notifs exactes (Android 12+).
    await androidImpl?.requestExactAlarmsPermission();
    _initialized = true;
  }

  /// Notification de test : se declenche apres [seconds] secondes.
  /// Sert a verifier sur l'appareil que le plugin / permission /
  /// channel marche bien.
  Future<void> scheduleTest({int seconds = 120}) async {
    await init();
    final when = tz.TZDateTime.now(tz.local)
        .add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      id: _testId,
      title: 'Test notification opti_route',
      body:
          'Bravo, les notifs locales marchent ! (declenchee a ${_format(when)})',
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'opti_route',
          channelDescription: 'Rappels de tournee',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTest() => _plugin.cancel(id: _testId);

  /// Programme un rappel de tournee pour [when] (DateTime local).
  /// L'id est derive de l'id Drift de la tournee pour eviter les
  /// conflits entre tournees et permettre l'annulation.
  ///
  /// Si [when] est dans le passe, on annule la notif precedente
  /// (s'il y en a une) et on ne reprogramme rien. C'est ce que veut
  /// le user quand il "efface" le rappel.
  Future<void> scheduleTourneeRappel({
    required int tourneeId,
    required String nomTournee,
    required DateTime when,
  }) async {
    await init();
    final notifId = _tourneeNotifId(tourneeId);
    await _plugin.cancel(id: notifId);
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzWhen.isAfter(now)) {
      // Date passee : on n'avait que la cancellation a faire.
      return;
    }
    await _plugin.zonedSchedule(
      id: notifId,
      title: 'Tournee a preparer : $nomTournee',
      body: 'C\'est l\'heure de demarrer ta tournee dans opti_route.',
      scheduledDate: tzWhen,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'opti_route',
          channelDescription: 'Rappels de tournee',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Annule le rappel programme pour une tournee. Safe a appeler meme
  /// si aucun rappel n'etait planifie.
  Future<void> cancelTourneeRappel(int tourneeId) async {
    await init();
    await _plugin.cancel(id: _tourneeNotifId(tourneeId));
  }

  /// Cancel global : utile a la desinstallation simulee depuis
  /// Parametres si on ajoute un bouton "purger tous les rappels".
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Programme un rappel "prepare tes colis" la veille de la tournee
  /// a [when] (heure fixe choisie par Noah, ex: 21h00).
  ///
  /// Distinct du rappel "matin de tournee" (scheduleTourneeRappel) qui
  /// reveille Noah. Celui-ci sert a la preparation pre-tournee.
  Future<void> scheduleVeilleReminder({
    required int tourneeId,
    required String nomTournee,
    required DateTime when,
  }) async {
    await init();
    final notifId = _veilleNotifId(tourneeId);
    await _plugin.cancel(id: notifId);
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzWhen.isAfter(now)) return;
    await _plugin.zonedSchedule(
      id: notifId,
      title: 'Demain : $nomTournee',
      body: 'Pense a preparer tes colis ce soir.',
      scheduledDate: tzWhen,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'opti_route',
          channelDescription: 'Rappels de tournee',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelVeilleReminder(int tourneeId) async {
    await init();
    await _plugin.cancel(id: _veilleNotifId(tourneeId));
  }

  /// Notification immediate post-tournee : "X livrees / Y echecs / Z min
  /// totales". Affichee a la bascule de la tournee en 'terminee'.
  ///
  /// Respecte le mode "ne pas deranger" : si on est actuellement dans
  /// le creneau quiet hours (defini dans Parametres), la notif est
  /// silencieusement skip. La tournee est quand meme marquee terminee
  /// en base, juste la notif n'est pas affichee.
  Future<void> showEndOfRouteSummary({
    required int tourneeId,
    required String nomTournee,
    required int nbLivres,
    required int nbEchecs,
    required int dureeTotaleMin,
  }) async {
    await init();
    if (await _isQuietHours()) {
      debugPrint(
          '[NotificationsService] quiet hours - skip showEndOfRouteSummary');
      return;
    }
    final notifId = _endOfRouteNotifId(tourneeId);
    final body = '$nbLivres livraisons, $nbEchecs echecs, '
        '${_humanDuration(dureeTotaleMin)}';
    await _plugin.show(
      id: notifId,
      title: 'Tournee terminee : $nomTournee',
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'opti_route',
          channelDescription: 'Rappels de tournee',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Notification "arrets oubliés" : declenchee si la tournee est mise
  /// en pause / fermee alors qu'il reste des stops a_livrer.
  ///
  /// Respecte le mode "ne pas deranger" : skip silencieux si on est
  /// dans le creneau quiet hours configure.
  Future<void> showPendingStopsAlert({
    required int tourneeId,
    required String nomTournee,
    required int nbPending,
  }) async {
    await init();
    if (nbPending == 0) return;
    if (await _isQuietHours()) {
      debugPrint(
          '[NotificationsService] quiet hours - skip showPendingStopsAlert');
      return;
    }
    final notifId = _pendingStopsNotifId(tourneeId);
    await _plugin.show(
      id: notifId,
      title: 'Arrets oublies : $nomTournee',
      body: 'Il reste $nbPending arret${nbPending > 1 ? "s" : ""} a livrer.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'opti_route',
          channelDescription: 'Rappels de tournee',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Notification immediate apres un backup auto reussi. Discrete
  /// (importance low/default au lieu de high : pas besoin de buzzer
  /// l'user en pleine tournee). Affiche la taille du fichier pour
  /// donner un signal "ca tourne et c'est de la vraie data".
  ///
  /// Respecte le mode "ne pas deranger" (skip silencieux pendant le
  /// creneau quiet hours).
  ///
  /// [sizeBytes] permet a la notif d'afficher "5.2 MB" plutot qu'un
  /// nombre brut. [filename] = nom du fichier (sans path) pour info.
  Future<void> showBackupSuccess({
    required String filename,
    required int sizeBytes,
  }) async {
    await init();
    if (await _isQuietHours()) {
      debugPrint(
          '[NotificationsService] quiet hours - skip showBackupSuccess');
      return;
    }
    final size = _humanSize(sizeBytes);
    await _plugin.show(
      id: _backupSuccessId,
      title: 'Sauvegarde auto reussie',
      body: 'Backup de $size cree. Consultable dans Parametres > Mes backups.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'opti_route',
          channelDescription: 'Rappels de tournee',
          // Volontairement LOW : on ne veut pas faire vibrer le phone
          // pour un evenement qui ne demande aucune action urgente.
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );
  }

  /// Format compact de taille fichier : "5.2 MB" / "523 KB" / "42 B".
  static String _humanSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  static String _humanDuration(int min) {
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  /// IDs distincts par type pour pouvoir programmer/annuler independamment.
  /// Plage reservee :
  ///   - matin (tourneeId direct) : 1 - 9999
  ///   - veille : 10000 - 19999
  ///   - end-of-route : 20000 - 29999
  ///   - pending-stops : 30000 - 39999
  ///   - backup auto : 40000 (id unique, on n'a qu'un seul backup
  ///     auto en cours a la fois -- la prochaine notif remplace
  ///     l'ancienne dans le tray)
  ///   - test : 9999 (reserve historique)
  static int _veilleNotifId(int tourneeId) => 10000 + tourneeId;
  static int _endOfRouteNotifId(int tourneeId) => 20000 + tourneeId;
  static int _pendingStopsNotifId(int tourneeId) => 30000 + tourneeId;
  static const _backupSuccessId = 40000;

  static const _testId = 9999;
  static const _channelId = 'opti_route_reminders';

  /// Id de notif derive de l'id tournee Drift. On garde le testId
  /// (9999) reserve et on prefere les ids < 9999 pour les rappels
  /// reels. Les ids Drift commencent a 1 et sont monotones, donc
  /// on est tranquille jusqu'a ~10 000 tournees creees.
  static int _tourneeNotifId(int tourneeId) => tourneeId;

  static String _format(tz.TZDateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}
