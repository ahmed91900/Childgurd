package com.kidsafe.launcher

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/** Phase 1 status-only service: no content collection, gestures, or app blocking.
 * Enforcement and its explicit disclosure belong to a later, device-tested phase.
 */
class KidSafeAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit
    override fun onInterrupt() = Unit
}
