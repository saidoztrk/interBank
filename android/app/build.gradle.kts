plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.interbank"
    compileSdk = flutter.compileSdkVersion

    // connectivity_plus uyarısını çözmek için NDK sürümünü sabitle
    ndkVersion = "27.0.12077973"

    defaultConfig {
        // TODO: Kendi benzersiz Application ID'nizi girin.
        applicationId = "com.example.interbank"

        // Flutter yapı ayarları
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            // Şimdilik debug imzasıyla imzala ki `flutter run --release` çalışsın
            signingConfig = signingConfigs.getByName("debug")
            // Eğer shrink/proguard kullanacaksan aç:
            // isMinifyEnabled = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
        debug {
            // Gerekirse debug ayarları
        }
    }
}

flutter {
    source = "../.."
}
