package com.optiroute.opti_route

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (et non FlutterActivity) est REQUIS par
// local_auth pour pouvoir afficher le BiometricPrompt systeme Android.
// Sans ca, authenticate() retourne false silencieusement et la
// biometrie ne se declenche jamais.
// Cf. https://pub.dev/packages/local_auth#android-integration
class MainActivity : FlutterFragmentActivity() {
    // Canal pour piloter FLAG_SECURE depuis Flutter (carte #111). Cote
    // Dart : SecureScreenService.setSecure(bool). FLAG_SECURE masque
    // l'apercu de l'app dans le selecteur de taches et bloque les
    // captures d'ecran -- protege les donnees clients affichees.
    private val secureScreenChannel = "com.optiroute.opti_route/secure_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            secureScreenChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    if (enable) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
