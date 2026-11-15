import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties (ignored by git), written by
// tool/release/crear_clave_android.ps1 locally or by the Builds workflow.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// The release APK (flutter build apk) is what GitHub Releases publishes and
// people download straight to the phone, often on mobile data. Two changes
// cut the download from 51 MB to about 16 MB and keep a single APK for every
// phone:
// - native libraries compressed inside the APK (Android unpacks them when
//   installing, so the space used on the phone also drops);
// - no x86_64 code: phones never used it with Android 7+, and the few Intel
//   Chromebooks run ARM apps through translation.
// Debug builds (emulators) and the Play bundle (flutter build appbundle, which
// Play splits per device) keep the defaults.
val sideload = gradle.startParameter.taskNames.any {
    it.contains("assembleRelease", ignoreCase = true)
}

android {
    namespace = "com.correiacristofer.dominovenezolano"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.correiacristofer.dominovenezolano"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        if (sideload) {
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
    }

    if (sideload) {
        packaging {
            jniLibs {
                useLegacyPackaging = true
            }
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // Relative to android/, or an absolute path (keystore kept
                // outside the repo on the developer's machine).
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Without the upload key, fall back to the debug key so release
            // builds still install on a test phone. Play rejects those, so
            // they cannot be published by mistake.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
