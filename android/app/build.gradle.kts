plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.my_app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.my_app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // BẮT BUỘC: bật desugaring (đúng cú pháp KTS)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Kotlin stdlib (tuỳ vào BOM của bạn; 1.9.25 hiện ổn)
    implementation(kotlin("stdlib", "1.9.25"))

    // BẮT BUỘC: thư viện desugar >= 2.1.4 (plugin yêu cầu)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // (tuỳ chọn) AndroidX cơ bản
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
}
