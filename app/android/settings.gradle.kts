pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 8.12.1 minimum : c'est le plancher exige par battery_plus 7
    // (cf le bump Dependabot). Prerequis verifies avant de monter :
    // Gradle 8.14 (>= 8.13 demande) et JDK 17, deja forces par
    // app/build.gradle.kts. Attention : aucun job de CI ne compile
    // Android, ce bump se valide en lancant build-android.yml a la main
    // (workflow_dispatch).
    id("com.android.application") version "8.12.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
