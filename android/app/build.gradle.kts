plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Manifest'te package kullanmıyoruz (AGP 8+)
    namespace = "com.interbank.mobil_asistan"
    compileSdk = flutter.compileSdkVersion

    // (Opsiyonel) NDK sabitlemek istersen:
    // ndkVersion = "27.0.12077973"

    defaultConfig {
        // Play Store paket kimliği
        applicationId = "com.interbank.mobil_asistan"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Java 17 önerilen
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // isMinifyEnabled = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
        debug { }
    }
}

flutter {
    source = "../.."
}
