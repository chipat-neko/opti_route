import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service de notifications locales (rappels "tournee a preparer",
/// "tournee non finie", + tests). 100% local au telephone via
/// flutter_local_notifications, aucune CB / backend / Firebase.
class NotificationsService {
  NotificationsService._();
  static final instance = NotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    // Local timezone : on prend Europe/Paris par defaut (Noah). Si on
    // veut etre plus general, on detecterait via flutter_timezone.
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

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
      _testId,
      'Test notification opti_route',
      'Bravo, les notifs locales marchent ! (declenchee a ${_format(when)})',
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'opti_route',
          channelDescription: 'Rappels de tournee',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTest() => _plugin.cancel(_testId);

  static const _testId = 9999;
  static const _channelId = 'opti_route_reminders';

  static String _format(tz.TZDateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}
