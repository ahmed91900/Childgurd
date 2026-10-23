import java.util.Base64
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}
val dartDefines = (project.findProperty("dart-defines") as? String).orEmpty()
    .split(',').filter { it.isNotBlank() }.mapNotNull {
        val value = String(Base64.getDecoder().decode(it), Charsets.UTF_8)
        val index = value.indexOf('=')
        if (index < 0) null else value.substring(0, index) to value.substring(index + 1)
    }.toMap()
val firebaseValues = dartDefines["FIREBASE_CONFIG"]?.takeIf { it.isNotBlank() }?.let {
    groovy.json.JsonSlurper().parseText(it) as Map<*, *>
}
android {
    namespace = "com.kidsafe.launcher"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    defaultConfig {
        applicationId = "com.kidsafe.launcher"
        // The video-player plugin requires API 24; preserve its supported floor.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = dartDefines["ADMOB_APP_ID"]?.takeIf { it.isNotBlank() }
            ?: "ca-app-pub-3940256099942544~3347511713"
        if (firebaseValues != null) {
            mapOf("appId" to "google_app_id", "messagingSenderId" to "gcm_defaultSenderId",
                "apiKey" to "google_api_key", "projectId" to "project_id").forEach { (key, resource) ->
                resValue("string", resource, requireNotNull(firebaseValues[key]).toString())
            }
            firebaseValues["storageBucket"]?.let { resValue("string", "google_storage_bucket", it.toString()) }
        }
    }
    // Release signing must be supplied privately before Play distribution.
    // No release build is signed with debug keys.
}
flutter { source = "../.." }
