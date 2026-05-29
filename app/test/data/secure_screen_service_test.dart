import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/secure_screen_service.dart';

// Premier test pour SecureScreenService :
// - verifie le nom du MethodChannel (doit matcher MainActivity.kt)
// - verifie l'invocation native sous Android (avec stub handler)
// - verifie le no-op silencieux hors Android
// - verifie le no-op silencieux si le plugin natif est absent
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureScreenService', () {
    const svc = SecureScreenService();

    test('channel name match MainActivity.kt', () {
      expect(
        SecureScreenService.channel.name,
        'com.optiroute.opti_route/secure_screen',
        reason: 'casse l\'integration native si modifie sans le pendant Kotlin',
      );
    });

    test('Android : appelle setSecure avec le bool fourni', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      MethodCall? lastCall;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SecureScreenService.channel, (call) async {
        lastCall = call;
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SecureScreenService.channel, null);
      });

      await svc.setSecure(true);
      expect(lastCall, isNotNull);
      expect(lastCall!.method, 'setSecure');
      expect(lastCall!.arguments, {'enable': true});

      await svc.setSecure(false);
      expect(lastCall!.arguments, {'enable': false});
    });

    test('iOS : no-op silencieux', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      var called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SecureScreenService.channel, (call) async {
        called = true;
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SecureScreenService.channel, null);
      });

      await svc.setSecure(true);
      expect(called, isFalse, reason: 'no-op hors Android');
    });

    test('Linux : no-op silencieux', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      var called = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SecureScreenService.channel, (call) async {
        called = true;
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SecureScreenService.channel, null);
      });

      await svc.setSecure(true);
      expect(called, isFalse);
    });

    test('Android : PlatformException avalee (best-effort)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SecureScreenService.channel, (call) async {
        throw PlatformException(code: 'ERR', message: 'natif a craque');
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SecureScreenService.channel, null);
      });

      // Ne doit pas throw
      await svc.setSecure(true);
    });

    test('Android : MissingPluginException avalee (handler absent)',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      // Pas de handler enregistre -> Flutter throw MissingPluginException
      // que le service doit avaler silencieusement.
      await svc.setSecure(true);
    });
  });
}
