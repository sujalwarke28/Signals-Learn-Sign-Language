plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.signals.signals"
    compileSdk = flutter.compileSdkVersion
    // AGP needs the NDK for release builds regardless of whether any Dart
    // dependency compiles native code -- it strips debug symbols from the
    // Flutter engine's bundled .so files. Budget ~2.8 GB of disk for it on a
    // first build; it is cached in the SDK afterwards.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.signals.signals"
        // firebase_auth requires API 23+; Flutter's default floor is lower.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signed with the debug keystore. That is enough to install the APK
            // by hand for a demo; it is not enough for the Play Store, which
            // needs a real upload key. See docs/07-android-apk.md.
            signingConfig = signingConfigs.getByName("debug")
            // R8 strips unused classes and resources. Firebase and Flutter both
            // ship consumer ProGuard rules, so this needs no hand-written config
            // beyond proguard-rules.pro (which only guards reflective entry
            // points R8 cannot see).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
