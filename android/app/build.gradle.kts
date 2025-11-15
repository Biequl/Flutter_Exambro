plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_exambro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }
    lint {
        disable.add("Deprecation")
        checkReleaseBuilds = false
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.beetechmedia.flutterexambro"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 2
        versionName = "2.1"
        ndk {
            abiFilters.clear()
        }
    }
    signingConfigs {
        create("release") {
            storeFile = file(project.findProperty("MY_KEYSTORE") as String)
            storePassword = project.findProperty("MY_KEYSTORE_PASSWORD") as String
            keyAlias = project.findProperty("MY_KEY_ALIAS") as String
            keyPassword = project.findProperty("MY_KEY_PASSWORD") as String
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Supaya split per arsitektur jalan
    // splits {
    //     abi {
    //         isEnable = true
    //         reset()
    //         include("armeabi-v7a", "arm64-v8a", "x86_64")
    //         isUniversalApk = true
    //     }
    // }
}
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.22")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:-unchecked")
}
flutter {
    source = "../.."
}
