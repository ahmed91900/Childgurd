package com.kidsafe.launcher

import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.core.net.toUri
import android.speech.tts.TextToSpeech
import java.util.Locale
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    // Parent authorization is intentionally ephemeral; process death locks it.
    private var kidMode = true
    private var externalSession = false
    private var speech: TextToSpeech? = null
    private var speechReady = false
    companion object {
        // Serialize vault IO across Activity/engine recreation within a process.
        private val vaultExecutor = Executors.newSingleThreadExecutor()
    }
    private val uiHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        speech = TextToSpeech(applicationContext) { status -> speechReady = status == TextToSpeech.SUCCESS }
    }

    override fun onPause() {
        kidMode = true
        speech?.stop()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (externalSession) {
            externalSession = false
            getSharedPreferences("KidSafePolicy", Context.MODE_PRIVATE).edit().putBoolean("blocked", true).commit()
        }
    }

    override fun onDestroy() {
        speech?.stop()
        speech?.shutdown()
        super.onDestroy()
    }

    private fun policy(blocked: Boolean) {
        getSharedPreferences("KidSafePolicy", Context.MODE_PRIVATE).edit().putBoolean("blocked", blocked).commit()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val vault by lazy { SecurePinVault(applicationContext) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kidsafe.launcher/vault")
            .setMethodCallHandler { call, result ->
                if (call.method != "read" && call.method != "write") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                vaultExecutor.execute {
                    try {
                        val value = if (call.method == "read") vault.read() else {
                            vault.write(call.arguments as String)
                            null
                        }
                        uiHandler.post { result.success(value) }
                    } catch (e: Exception) {
                        uiHandler.post { result.error("SECURE_STORAGE_FAILED", "Secure storage unavailable", null) }
                    }
                }
            }
        val familyVault by lazy { SecurePinVault(applicationContext, true) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kidsafe.launcher/family")
            .setMethodCallHandler { call, result ->
                if (call.method != "read" && call.method != "write") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                vaultExecutor.execute {
                    try {
                        val value = if (call.method == "read") familyVault.read() else {
                            familyVault.write(call.arguments as String)
                            null
                        }
                        uiHandler.post { result.success(value) }
                    } catch (e: Exception) {
                        uiHandler.post { result.error("FAMILY_STORAGE_FAILED", "Storage unavailable", null) }
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kidsafe.launcher/device")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "status" -> result.success(permissionStatus())
                        "getLanguage" -> result.success(getSharedPreferences("KidSafePolicy", Context.MODE_PRIVATE).getString("language", ""))
                        "setLanguage" -> {
                            val value = call.arguments as String
                            check(value in listOf("en", "bn", "ar"))
                            getSharedPreferences("KidSafePolicy", Context.MODE_PRIVATE).edit().putString("language", value).commit()
                            result.success(null)
                        }
                        "setKidMode" -> {
                            kidMode = call.arguments as? Boolean ?: true
                            if (!externalSession || !kidMode) policy(kidMode)
                            if (kidMode) speech?.stop()
                            result.success(null)
                        }
                        "request" -> {
                            // Internal channel; Flutter requires parent setup/auth.
                            externalSession = true
                            policy(false)
                            requestPermission(call.arguments as String)
                            result.success(null)
                        }
                        "beginParentExternal" -> {
                            check(!kidMode) { "Parent authorization required" }
                            externalSession = true
                            policy(false)
                            result.success(null)
                        }
                        "stopSpeech" -> { speech?.stop(); result.success(null) }
                        "speak" -> {
                            val args = call.arguments as Map<*, *>
                            val text = (args["text"] as String).take(2000)
                            val language = args["language"] as String
                            val engine = speech
                            val voice = if (speechReady) engine?.voices?.firstOrNull {
                                it.locale.language == Locale.forLanguageTag(language).language && !it.isNetworkConnectionRequired
                            } else null
                            if (voice == null || engine == null) result.success(false) else {
                                engine.voice = voice
                                engine.setSpeechRate(0.8f)
                                result.success(engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "kidsafe-lesson") == TextToSpeech.SUCCESS)
                            }
                        }
                        "apps" -> {
                            check(!kidMode) { "Parent authorization required" }
                            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                            val apps = packageManager.queryIntentActivities(intent, 0)
                                .filter { it.activityInfo.packageName != packageName }
                                .distinctBy { it.activityInfo.packageName }
                                .map { mapOf("label" to it.loadLabel(packageManager).toString(),
                                    "package" to it.activityInfo.packageName) }
                                .sortedBy { it["label"]?.lowercase() }
                            result.success(apps)
                        }
                        "open" -> {
                            check(!kidMode) { "Parent authorization required" }
                            val target = call.arguments as String
                            val intent = packageManager.getLaunchIntentForPackage(target)
                                ?: error("App is unavailable")
                            externalSession = true
                            policy(false)
                            startActivity(intent)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    // Do not emit PINs, arguments, or exception text into logs.
                    result.error("DEVICE_OPERATION_FAILED", "Android could not complete this operation", null)
                }
            }
    }

    private fun permissionStatus(): Map<String, Boolean> {
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val home = packageManager.resolveActivity(homeIntent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY)
        val admin = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val service = ComponentName(this, KidSafeAccessibilityService::class.java)
        val enabled = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            .orEmpty().split(':').mapNotNull { ComponentName.unflattenFromString(it) }
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val usage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mapOf(
            "home" to (home?.activityInfo?.packageName == packageName),
            "admin" to admin.isAdminActive(ComponentName(this, KidSafeAdminReceiver::class.java)),
            "accessibility" to (service in enabled &&
                Settings.Secure.getInt(contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED, 0) == 1),
            "overlay" to Settings.canDrawOverlays(this),
            "usage" to (usage == AppOpsManager.MODE_ALLOWED)
        )
    }

    private fun requestPermission(name: String) {
        val packageUri = "package:$packageName".toUri()
        val intent = when (name) {
            "speech" -> Intent("com.android.settings.TTS_SETTINGS")
            "home" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val roles = getSystemService(RoleManager::class.java)
                    if (roles.isRoleAvailable(RoleManager.ROLE_HOME) && !roles.isRoleHeld(RoleManager.ROLE_HOME)) {
                        roles.createRequestRoleIntent(RoleManager.ROLE_HOME)
                    } else Intent(Settings.ACTION_HOME_SETTINGS)
                } else Intent(Settings.ACTION_HOME_SETTINGS)
            }
            "admin" -> Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).putExtra(
                DevicePolicyManager.EXTRA_DEVICE_ADMIN, ComponentName(this, KidSafeAdminReceiver::class.java))
            "accessibility" -> Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            "overlay" -> Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, packageUri)
            "usage" -> Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS, packageUri)
            else -> error("Unknown permission")
        }
        startActivity(intent)
    }
}
