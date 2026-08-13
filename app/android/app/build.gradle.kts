import java.util.Properties
import java.io.File
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Lecture du keystore release. Le fichier key.properties (mots de passe en
// clair) et la keystore .jks sont gitignored, mais tant qu'ils vivent DANS
// l'arbre du repo ils restent a portee d'un `git add -f`, d'un zip du dossier
// ou d'une sauvegarde du disque. On les cherche donc d'abord hors du repo.
//
// Ordre de resolution (premier trouve gagne) :
//   1. $OPTIROUTE_KEY_PROPERTIES  -> chemin complet du fichier (CI / machine
//      atypique) ;
//   2. ~/keystores/opti_route/key.properties  -> emplacement recommande,
//      hors de l'arbre du repo ;
//   3. android/key.properties  -> emplacement historique, conserve pour ne
//      pas casser les machines pas encore migrees.
// Cf docs/keystore-release.md pour la procedure de migration.
val keystoreCandidates = listOfNotNull(
    System.getenv("OPTIROUTE_KEY_PROPERTIES")?.takeIf { it.isNotBlank() }?.let { File(it) },
    File(System.getProperty("user.home"), "keystores/opti_route/key.properties"),
    rootProject.file("key.properties"),
)
val keystorePropertiesFile = keystoreCandidates.firstOrNull { it.isFile }
val hasReleaseKeystore = keystorePropertiesFile != null
val keystoreProperties = Properties()
if (keystorePropertiesFile != null) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    logger.lifecycle("Signing release : key.properties lu depuis ${keystorePropertiesFile.absolutePath}")
}

// `storeFile` peut etre absolu, ou relatif. Historiquement il etait relatif a
// android/app/ (comportement de `file(...)` dans ce script). Depuis que le
// key.properties peut vivre hors de l'arbre, un chemin relatif se lit d'abord
// par rapport au dossier qui contient ce key.properties. On essaie les deux
// bases pour que les deux conventions continuent de marcher.
val resolveStoreFile: (String) -> File = { raw ->
    val direct = File(raw)
    if (direct.isAbsolute) {
        direct
    } else {
        val bases = listOfNotNull(keystorePropertiesFile?.parentFile, projectDir)
        bases.map { File(it, raw) }.firstOrNull { it.isFile }
            ?: run {
                // Pas d'echec ici : ce bloc est evalue a la configuration, donc
                // meme pour un `flutter run` debug. On garde l'ancien
                // comportement (chemin relatif a android/app/) et on previent ;
                // c'est la signature du build release qui echouera, comme avant.
                logger.warn(
                    "Keystore introuvable : storeFile=\"$raw\" (cherche dans " +
                        bases.joinToString(", ") { it.absolutePath } + "). " +
                        "Le build release ne sera pas signe correctement. " +
                        "Voir docs/keystore-release.md.",
                )
                File(projectDir, raw)
            }
    }
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

    // Note : le forcing JVM 17 sur les sous-projets (plugins Kotlin
    // tiers comme receive_sharing_intent) est fait au niveau root
    // dans android/build.gradle.kts pour s'appliquer a tous.

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
                storeFile = resolveStoreFile(keystoreProperties["storeFile"] as String)
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
            // Le split ABI est utile pour les APK (sideload : 1 APK par
            // archi, ~55-65 MB). MAIS il casse le build de bundle (AAB) :
            // combiner split ABI + shrinkResources fait echouer
            // :app:buildReleasePreBundle ("Multiple shrunk-resources",
            // bug AGP issuetracker 402800800). Le bundle gere de toute
            // facon lui-meme la separation par ABI cote Play Store. On
            // desactive donc le split quand on build un bundle.
            val isBundleBuild = gradle.startParameter.taskNames.any {
                it.contains("bundle", ignoreCase = true)
            }
            isEnable = !isBundleBuild
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
