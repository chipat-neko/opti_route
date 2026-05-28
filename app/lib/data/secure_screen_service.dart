import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pilote le flag Android `FLAG_SECURE` via un MethodChannel natif
/// (carte #111). Quand il est actif, Android :
/// - masque l'apercu (thumbnail) de l'app dans le selecteur de taches
///   (multitache) -> un swipe "recent apps" n'expose plus l'adresse /
///   le telephone du client visibles a l'ecran,
/// - bloque les captures d'ecran (Power + Volume bas) et la capture par
///   d'autres apps.
///
/// No-op silencieux hors Android (iOS / desktop / web) : le flag n'a
/// pas d'equivalent natif identique et le logiciel chef Windows n'a pas
/// le meme besoin. Best-effort : la methode n'echoue jamais (un build
/// sans le handler natif lance une [MissingPluginException] qu'on avale).
class SecureScreenService {
  const SecureScreenService();

  /// Doit correspondre au nom declare dans `MainActivity.kt`.
  static const MethodChannel channel =
      MethodChannel('com.optiroute.opti_route/secure_screen');

  Future<void> setSecure(bool enable) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod<void>('setSecure', {'enable': enable});
    } on PlatformException catch (e) {
      debugPrint('[SecureScreen] setSecure echec: ${e.message}');
    } on MissingPluginException {
      // Handler natif absent (vieux build / autre plateforme) -> ignore.
    }
  }
}
