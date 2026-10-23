package com.kidsafe.launcher

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.provider.Settings
import android.os.SystemClock
import android.os.Build
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver

/** Best-effort package-level Home redirect, with explicit parent disclosure.
 * Never reads screen content. System and emergency surfaces are left to Android.
 */
class KidSafeAccessibilityService : AccessibilityService() {
    private var lastRedirect = 0L
    private val screenOff = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            getSharedPreferences("KidSafePolicy", Context.MODE_PRIVATE).edit().putBoolean("blocked", true).commit()
        }
    }
    override fun onServiceConnected() {
        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(screenOff, filter, Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(screenOff, filter)
    }
    override fun onDestroy() {
        try { unregisterReceiver(screenOff) } catch (_: IllegalArgumentException) { }
        super.onDestroy()
    }
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val blocked = getSharedPreferences("KidSafePolicy", Context.MODE_PRIVATE).getBoolean("blocked", true)
        if (!blocked) return
        val target = event.packageName?.toString() ?: return
        val keyboard = Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
            ?.substringBefore('/')
        if (target == packageName || target == keyboard || target == "android" || target == "com.android.systemui") return
        val now = SystemClock.elapsedRealtime()
        if (now - lastRedirect < 700) return
        lastRedirect = now
        performGlobalAction(GLOBAL_ACTION_HOME)
    }
    override fun onInterrupt() = Unit
}
