//plugins {
//    id("com.android.application")
//    id("com.google.gms.google-services")
//    id("kotlin-android")
//    id("dev.flutter.flutter-gradle-plugin")
//}
//
//android {
//    namespace = "com.example.top_up_shops"
//    compileSdk = flutter.compileSdkVersion
//    ndkVersion = flutter.ndkVersion
//
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_17
//        targetCompatibility = JavaVersion.VERSION_17
//    }
//
//    kotlinOptions {
//        jvmTarget = "17"
//    }
//
//    defaultConfig {
//        applicationId = "com.example.top_up_shops"
//        minSdk =  flutter.minSdkVersion // برای USSD حداقل باید 21 باشد
//        targetSdk = flutter.targetSdkVersion
//        versionCode = flutter.versionCode
//        versionName = flutter.versionName
//    }
//
//    // اصلاح بخش منابع برای فایل‌های KTS
//    sourceSets {
//        getByName("main") {
//            res.srcDirs("src/main/res")
//        }
//    }
//
//    buildTypes {
//        release {
//            signingConfig = signingConfigs.getByName("debug")
//            // در KTS نام‌ها کمی متفاوت هستند
//            isShrinkResources = false
//            isMinifyEnabled = false
//        }
//    }
//
//    // اصلاح بخش لیت برای فایل‌های KTS
//    lint {
//        checkReleaseBuilds = false
//        abortOnError = false
//    }
//}
//
//flutter {
//    source = "../.."
//}
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.top_up_shops"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.top_up_shops"
        // پکیج های USSD حتما به نسخه 21 نیاز دارند
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    sourceSets {
        getByName("main") {
            res.srcDirs("src/main/res")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // این بخش برای نادیده گرفتن خطاهای پکیج ussd_advanced_flutter حیاتی است
    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += listOf("MissingTranslation", "TypographyFractions")
    }

    // جلوگیری از تداخل منابع پکیج با پروژه اصلی
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}