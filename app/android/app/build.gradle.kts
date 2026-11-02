plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.artiz.az_receipts"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.artiz.az_receipts"
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

dependencies {
    // ONNX Runtime for Android (CPU + NNAPI). Loaded at run time by the Rust
    // side (ort `load-dynamic`); the version must be >= 1.17 (ORT API 17).
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.31.1")
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
