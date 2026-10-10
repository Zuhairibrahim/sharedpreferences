import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 🔥 قراءة إعدادات مفتاح التوقيع من ملف key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.zuhair.sharedpreferencess.apps"

    // 🔥 تحديث الـ Compile SDK إجباريًا إلى إصدار 35 تلبية لطلب قوقل
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // 🔥 تجهيز إعدادات التوقيع برمجياً لنسخة الـ Release
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String? ?: "upload-keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.zuhair.sharedpreferencess.apps"
        minSdk = flutter.minSdkVersion

        // 🔥 تحديث الـ Target SDK إجباريًا إلى إصدار 35 عشان يقبله المتجر
        targetSdk = 36

        // 🔥 رفع رقم النسخة إلى 5 (الرقم 4 مستخدم سابقاً)
        versionCode = 5
        versionName = "1.0.4"
    }

    buildTypes {
        release {
            // 🔥 ربط التوقيع الرسمي الـ Release بدلاً من الـ debug القديم
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.play:integrity:1.5.0")
    implementation("com.google.gms:google-services:4.3.15")
    implementation("com.google.android.gms:play-services-auth:20.6.0")
    implementation("androidx.appcompat:appcompat:1.4.0")
}