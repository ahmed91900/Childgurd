package com.kidsafe.launcher

import android.app.admin.DeviceAdminReceiver

// No lock/wipe/password policies are requested. Android owns deactivation.
class KidSafeAdminReceiver : DeviceAdminReceiver()
