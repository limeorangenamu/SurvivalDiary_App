import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use(localProperties::load)
}

fun localCredential(name: String): String? =
    System.getenv(name)
        ?: localProperties.getProperty(name)
        ?: project.findProperty(name)?.toString()

android {
    namespace = "com.survivaldiary.project_survival_diary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.survivaldiary.project_survival_diary"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter_secure_storage 10 requires Android API 23 or newer.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // OAuth credentials are supplied through the local environment/CI.
        // Do not commit them to gradle.properties or source control.
        val kakaoNativeAppKey = localCredential("KAKAO_NATIVE_APP_KEY") ?: "not-configured"
        val naverLoginClientId = localCredential("NAVER_LOGIN_CLIENT_ID") ?: "not-configured"
        val naverLoginClientSecret =
            localCredential("NAVER_LOGIN_CLIENT_SECRET") ?: "not-configured"

        manifestPlaceholders["kakaoRedirectScheme"] = "kakao$kakaoNativeAppKey"
        resValue(
            "string",
            "naver_login_client_id",
            naverLoginClientId,
        )
        resValue(
            "string",
            "naver_login_client_secret",
            naverLoginClientSecret,
        )
        resValue("string", "naver_login_client_name", "생존일기")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
