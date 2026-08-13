import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Configuración de firma. Vive fuera del repositorio: `key.properties` está en
// .gitignore y `key.properties.example` documenta su forma. Si el archivo no
// existe —que es el caso de cualquiera que clone y compile— el build de release
// sigue funcionando sin firmar con la clave de subida, en vez de fallar con un
// error que no dice nada.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasSigningConfig = keystorePropertiesFile.exists()
if (hasSigningConfig) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "lat.araguaney.araguaney_app"
    // flutter_secure_storage 11 exige compilar contra el SDK 37 de Android.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "lat.araguaney.araguaney_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Los dos salen de `version:` en pubspec.yaml: el número antes del `+`
        // es el nombre y el de después es el código. Ver docs/release/versioning.md.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasSigningConfig) {
            create("upload") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sin material de firma se compila igual, sin firmar. Es lo que
            // permite que un fork haga `flutter build appbundle` para revisar
            // el resultado sin pedirle a nadie una clave.
            signingConfig = if (hasSigningConfig) {
                signingConfigs.getByName("upload")
            } else {
                null
            }

            // El shrinker de código y el de recursos van juntos: quitar clases
            // sin quitar los recursos que solo ellas usaban deja peso muerto en
            // el bundle.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
