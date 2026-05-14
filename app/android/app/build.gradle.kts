import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lecture du keystore release depuis android/key.properties s'il existe.
// Ce fichier est gitignored : Noah le genere localement avec sa keystore
// privee quand il prepare une publication Play Store.
// Cf docs/keystore-release.md pour la procedure.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.optiroute.opti_route"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par flutter_local_notifications (qui utilise des
        // classes Java 8+ comme java.time non disponibles sur les
        // anciennes versions Android).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.optiroute.opti_route"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Config release : creee uniquement si la keystore Noah est
        // presente sur la machine. Sinon, on retombe sur debug ci-dessous.
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Si la keystore release est disponible, on signe pour Play
            // Store. Sinon, fallback debug pour pouvoir continuer a
            // builder localement avec `flutter run --release` sans
            // demander la keystore.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    // Split par ABI : genere un APK par architecture CPU. L'APK
    // monolithique fait 98+ MB (ML Kit + flutter_map + Drift). Limite
    // Play Store = 100 MB par APK. Avec split, chaque APK pese ~55-65 MB
    // (le device ne telecharge que l'ABI dont il a besoin).
    // - armeabi-v7a : vieux smartphones (>2015), ~5% du parc actuel
    // - arm64-v8a   : tous les smartphones modernes, ~95% du parc
    // Le universalApk fournit aussi un fat APK pour distribution
    // hors-Play (sideload Noah / partage direct).
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a")
            isUniversalApk = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
