// MainActivity.kt - Fixed version with proper syntax
package com.example.expense_tracker

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {
    private val SMS_PERMISSION_REQUEST = 1001

    companion object {
        private const val CHANNEL = "sms_channel"
        private var smsChannel: MethodChannel? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun isChannelReady(): Boolean {
            val ready = smsChannel != null
            Log.d("MainActivity", "Channel ready: $ready")
            return ready
        }

        fun sendSmsToFlutter(data: Map<String, Any>) {
            mainHandler.post {
                try {
                    Log.d("MainActivity", "Sending to Flutter: $data")
                    smsChannel?.invokeMethod("onSmsReceived", data)
                    Log.d("MainActivity", "Successfully invoked Flutter method")
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error invoking Flutter method: ${e.message}", e)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d("MainActivity", "Configuring Flutter engine...")

        smsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        smsChannel?.setMethodCallHandler { call, result ->
            Log.d("MainActivity", "Method call received: ${call.method}")

            when (call.method) {
                "requestPermissions" -> {
                    Log.d("MainActivity", "Requesting SMS permissions...")
                    requestSmsPermissions(result)
                }
                "checkPermissions" -> {
                    val hasPermissions = checkSmsPermissions()
                    Log.d("MainActivity", "Checking permissions: $hasPermissions")
                    result.success(hasPermissions)
                }
                "testReceiver" -> {
                    Log.d("MainActivity", "Testing receiver registration...")
                    result.success("Receiver should be registered")
                }
                else -> {
                    Log.w("MainActivity", "Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        Log.d("MainActivity", "Flutter engine configured successfully")
    }

    private fun checkSmsPermissions(): Boolean {
        val permissions = arrayOf(
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.READ_SMS,
            Manifest.permission.READ_PHONE_STATE
        )

        val results = permissions.map { permission ->
            val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
            Log.d("MainActivity", "$permission: $granted")
            granted
        }

        return results.all { it }
    }

    private fun requestSmsPermissions(result: Result) {
        if (checkSmsPermissions()) {
            Log.d("MainActivity", "All permissions already granted")
            result.success(true)
            return
        }

        val permissions = arrayOf(
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.READ_SMS,
            Manifest.permission.READ_PHONE_STATE
        )

        Log.d("MainActivity", "Requesting permissions: ${permissions.joinToString()}")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ActivityCompat.requestPermissions(this, permissions, SMS_PERMISSION_REQUEST)
            // Don't call result.success here - wait for onRequestPermissionsResult
        } else {
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        Log.d("MainActivity", "Permission result - Request code: $requestCode")

        if (requestCode == SMS_PERMISSION_REQUEST) {
            val results = permissions.zip(grantResults.toTypedArray()) { permission, result ->
                val granted = result == PackageManager.PERMISSION_GRANTED
                Log.d("MainActivity", "$permission: $granted")
                granted
            }

            val allGranted = results.all { it }
            Log.d("MainActivity", "All permissions granted: $allGranted")

            smsChannel?.invokeMethod("onPermissionResult", allGranted)
        }
    }
}