plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.karma.daylog"
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
        applicationId = "com.karma.daylog"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol E2E. 러너를 바꾸지 않으면 patrol test 가 Dart 테스트를 찾지 못한다.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        // 테스트마다 앱 데이터를 지운다. 이전 테스트의 Supabase 세션이
        // 다음 테스트로 새는 걸 막아준다.
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    // clearPackageData 는 orchestrator 가 있어야 동작한다.
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // 빌드가 멈추면 1.6.1 로 올린다.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}

flutter {
    source = "../.."
}
