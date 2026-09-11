import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is supplied at build time via android/key.properties (gitignored).
// Absent that file, release builds fall back to the debug keys so `flutter run
// --release` and CI smoke builds still work.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.affluentlabs.cairn"
    // compileSdk 36: required by AndroidX libraries pulled in by the plugins
    // (build fails against 35). targetSdk stays at 35 (current Play requirement);
    // the two are independent (spec Section 11 note "check current requirement").
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.affluentlabs.cairn"
        // minSdk 26: foreground service types, adaptive icons, modern TLS.
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Two builds from one codebase (spec Section 12.3).
    // community: fully unlocked, no Google Play libraries, ships on F-Droid and GitHub.
    // store: Cairn Summit gate via --dart-define=CAIRN_STORE=true, ships on Google Play.
    // Same applicationId so a user can move between builds without losing data.
    flavorDimensions += "distribution"
    productFlavors {
        create("community") {
            dimension = "distribution"
            buildConfigField("boolean", "STORE_BUILD", "false")
        }
        create("store") {
            dimension = "distribution"
            buildConfigField("boolean", "STORE_BUILD", "true")
        }
    }

    signingConfigs {
        create("release") {
            if (hasKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                if (storeFilePath != null) {
                    storeFile = file(storeFilePath)
                }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
