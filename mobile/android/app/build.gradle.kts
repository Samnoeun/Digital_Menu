plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ✅ Correct namespace (this replaces `package` in AndroidManifest.xml)
    namespace = "com.example.mobile"

    // ✅ Compile SDK version (comes from Flutter automatically)
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        // ✅ Application ID (unique package name)
        applicationId = "com.example.mobile"

        // ✅ Minimum and Target SDK from Flutter
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // ✅ App versioning
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Java & Kotlin compatibility
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // ✅ Release build configuration
    buildTypes {
        release {
            // TODO: Add your own signing config before publishing
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    // ✅ Path to Flutter project root
    source = "../.."
}
