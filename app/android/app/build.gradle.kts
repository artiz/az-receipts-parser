import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for Google Play: android/key.properties (never committed), written
// by scripts/make_keystore.bat. Without it a release build is signed with the
// debug key, as before, so a plain `flutter build apk` keeps working.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}
val hasUploadKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "dev.artiz.az_budget"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.artiz.az_budget"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(26, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        // The Rust OCR library is built for arm64 only (scripts/build_android_rust.sh);
        // the onnxruntime-android AAR ships every ABI, so restrict packaging to match.
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    packaging {
        jniLibs {
            // libreceipt_ocr.so dlopen()s libonnxruntime.so by name: keep both
            // extracted on disk instead of mapped from the APK.
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // The upload key when android/key.properties exists (Google Play);
            // the debug key otherwise, so `flutter run --release` keeps working.
            signingConfig = if (hasUploadKey) signingConfigs.getByName("upload") else signingConfigs.getByName("debug")
            // R8: Google Play flags DEX code below 25 % obfuscation. The mapping
            // file (build/app/outputs/mapping/release/mapping.txt) goes to Play
            // with the bundle, so crash reports stay readable. Resources are not
            // shrunk: little to gain, and plugins may look some up by name.
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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

dependencies {
    // ONNX Runtime for Android (CPU + NNAPI). Loaded at run time by the Rust
    // side (ort `load-dynamic`); the version must be >= 1.17 (ORT API 17).
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.31.1")
    // NotificationCompat for the limit alerts (MainActivity.showNotification).
    implementation("androidx.core:core-ktx:1.15.0")
}

// Fail early when the native OCR library is missing from jniLibs.
tasks.matching { it.name.startsWith("merge") && it.name.endsWith("JniLibFolders") }.configureEach {
    doFirst {
        val lib = file("src/main/jniLibs/arm64-v8a/libreceipt_ocr.so")
        if (!lib.exists()) {
            throw GradleException(
                "libreceipt_ocr.so not found at ${'$'}{lib.path}. Run scripts/build_android_rust.sh first " +
                    "(needs the Android NDK and cargo-ndk)."
            )
        }
    }
}
