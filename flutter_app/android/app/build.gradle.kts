plugins {
    // Permite preparar el proyecto como una aplicación de Android.
    id("com.android.application")

    // Conecta las herramientas de Flutter con la compilación de Android.
    // Se coloca después del plugin de Android.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Nombre interno que utiliza el código de Android.
    // Se conserva para mantener la configuración del proyecto.
    namespace = "com.example.spooky_mobile"

    // Utiliza la versión del SDK de Android indicada por Flutter.
    compileSdk = flutter.compileSdkVersion

    // Utiliza la versión de las herramientas nativas indicada por Flutter.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Permite compilar el código Java utilizando la versión 17.
        sourceCompatibility = JavaVersion.VERSION_17

        // Genera el código de Java para esa misma versión.
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identifica la aplicación instalada en Android.
        // No es el nombre que aparece debajo del icono.
        // Cambiarlo haría que Android la identificara como otra aplicación.
        applicationId = "com.example.spooky_mobile"

        // La aplicación requiere Android 8.0 o una versión posterior.
        minSdk = 26

        // Define la versión de Android para la que se prepara la app,
        // utilizando el valor que proporciona Flutter.
        targetSdk = flutter.targetSdkVersion

        // Número interno que Android utiliza para distinguir actualizaciones.
        // Flutter lo obtiene de la configuración de versión de pubspec.yaml.
        versionCode = flutter.versionCode

        // Versión que se puede mostrar al usuario, por ejemplo 1.0.0.
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Por ahora, la versión release utiliza la firma de pruebas.
            // Permite probarla, pero queda pendiente configurar
            // una firma propia para su publicación.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        // Mantiene la misma versión de destino para Kotlin y Java.
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    // Indica dónde está la raíz del proyecto Flutter
    // tomando como referencia esta carpeta de Android.
    source = "../.."
}