plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.encontros"

    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
	kotlin {
		compilerOptions {
			jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
		}
	}

    defaultConfig {
        applicationId = "com.example.encontros"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    buildFeatures {
        viewBinding = false
    }
    dependenciesInfo {
        includeInApk = false
    }
    buildToolsVersion = "36.0.0"
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.activity:activity:1.8.2")
        force("androidx.activity:activity-ktx:1.8.2")
    }
}

flutter {
    source = "../.."
}