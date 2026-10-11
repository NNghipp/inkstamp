import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = rootProject.file("key.properties")
val releaseSigning = Properties().apply {
    if (signingPropertiesFile.isFile) signingPropertiesFile.inputStream().use { load(it) }
}
val hasReleaseSigning = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !releaseSigning.getProperty(it).isNullOrBlank() }

gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("Release", ignoreCase = true) }) {
        check(hasReleaseSigning) {
            "Release signing is not configured. Provide ignored android/key.properties; debug signing is forbidden."
        }
        val keyFile = rootProject.file(releaseSigning.getProperty("storeFile"))
        check(keyFile.isFile && keyFile.name != "debug.keystore" &&
            releaseSigning.getProperty("keyAlias") != "androiddebugkey") {
            "A non-debug release signing key is required."
        }
        val definitions = (project.findProperty("dart-defines") as? String).orEmpty()
            .split(',').filter { it.isNotBlank() }.associate {
                val decoded = String(Base64.getDecoder().decode(it))
                decoded.substringBefore('=') to decoded.substringAfter('=', "")
            }
        check(definitions["APP_ENV"] == "prod" &&
            definitions["FIREBASE_PROJECT_ID"]?.let { it.isNotBlank() && it != "inkstamp-dev" } == true &&
            definitions["MEDIA_GATEWAY_BASE_URL"]?.startsWith("https://") == true &&
            definitions["FUNCTIONS_REGION"]?.isNotBlank() == true &&
            definitions["ENABLE_DEV_TEST_AUTH"] != "true" &&
            definitions["BACKEND_MODE"] != "functions_emulator" &&
            definitions["DEMO_MODE"] != "true") {
            "Release requires explicit isolated PROD configuration; DEV flags are forbidden."
        }
        val firebaseConfig = file("google-services.json")
        check(firebaseConfig.isFile) { "Production Firebase Android registration required." }
        val config = groovy.json.JsonSlurper().parse(firebaseConfig) as Map<*, *>
        val firebaseProject = config["project_info"] as? Map<*, *>
        check(firebaseProject?.get("project_id") == definitions["FIREBASE_PROJECT_ID"]) {
            "google-services.json does not match the production Firebase project."
        }
    }
}

android {
    namespace = "com.inkstamp.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.inkstamp.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("production") {
                storeFile = rootProject.file(releaseSigning.getProperty("storeFile"))
                storePassword = releaseSigning.getProperty("storePassword")
                keyAlias = releaseSigning.getProperty("keyAlias")
                keyPassword = releaseSigning.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("production")
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
