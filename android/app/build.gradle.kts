plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hoodly.hoodly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hoodly.hoodly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources {
            // Prevent processDebugJavaRes from locking the com/hoodly output directory
            // on Windows by excluding Kotlin metadata files that AGP writes per-package.
            excludes += listOf(
                "**/*.kotlin_module",
                "**/*.kotlin_builtins",
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1"
            )
            pickFirsts += listOf(
                "**/*.proto",
                "**/*.bin"
            )
        }
    }
}

flutter {
    source = "../.."
}

// WINDOWS FILE-LOCK WORKAROUND:
// On Windows, Gradle's stale-output cleanup (RemoveStaleOutputsStep) tries to delete
// the processDebugJavaRes output directory before writing new outputs. This fails when
// Windows Defender or another process holds a handle on com/hoodly inside that directory.
// doNotTrackState prevents Gradle from recording/comparing task output history,
// which disables the stale-output deletion step entirely for these tasks.
afterEvaluate {
    tasks.matching { it.name.endsWith("JavaRes") }.configureEach {
        doNotTrackState("Windows file locking workaround: skip stale output cleanup for JavaRes tasks")
    }
}
