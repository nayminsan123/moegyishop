import java.util.Properties
import java.io.FileInputStream

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()

println("--- Start Signing Config Debug ---")
println("Looking for key.properties at: " + keyPropertiesFile.absolutePath)
println("key.properties exists: " + keyPropertiesFile.exists())

if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
    println("Successfully loaded key.properties")
    val storeFilePath = keyProperties.getProperty("storeFile")
    println("storeFile property from file: '" + storeFilePath + "'")
    if (storeFilePath != null) {
        val storeFile = rootProject.file(storeFilePath)
        println("Resolved storeFile path: " + storeFile.absolutePath)
        println("Resolved storeFile exists: " + storeFile.exists())
    }
} else {
    println("key.properties not found!")
}
println("--- End Signing Config Debug ---")

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.moegyi.shop"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storePassword = keyProperties.getProperty("storePassword")
                val storeFilePath = keyProperties.getProperty("storeFile")
                if (storeFilePath != null) {
                    storeFile = rootProject.file(storeFilePath)
                }
            }
        }
    }

    defaultConfig {
        applicationId = "com.moegyi.shop"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
