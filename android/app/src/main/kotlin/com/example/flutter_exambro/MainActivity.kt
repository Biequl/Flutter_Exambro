package com.example.flutter_exambro

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Build.VERSION_CODES
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.flutter_exambro.MyDeviceAdminReceiver

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kioskModeLocked"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponentName: ComponentName

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        // Anda perlu buat DeviceAdminReceiver class yang bernama MyDeviceAdminReceiver
        adminComponentName = MyDeviceAdminReceiver.getComponentName(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKioskMode" -> {
                    if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
                        devicePolicyManager.setLockTaskPackages(adminComponentName, arrayOf(packageName))
                        startLockTask()
                    }
                    result.success(null)
                }
                "stopKioskMode" -> {
                    if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
                        stopLockTask()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
