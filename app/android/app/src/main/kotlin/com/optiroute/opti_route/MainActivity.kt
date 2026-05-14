package com.optiroute.opti_route

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (et non FlutterActivity) est REQUIS par
// local_auth pour pouvoir afficher le BiometricPrompt systeme Android.
// Sans ca, authenticate() retourne false silencieusement et la
// biometrie ne se declenche jamais.
// Cf. https://pub.dev/packages/local_auth#android-integration
class MainActivity : FlutterFragmentActivity()
