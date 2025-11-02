//package com.example.expense_tracker
//
//import android.Manifest
//import android.content.pm.PackageManager
//import android.os.Bundle
//import android.util.Log
//import androidx.core.app.ActivityCompat
//import androidx.core.content.ContextCompat
//import io.flutter.embedding.android.FlutterFragmentActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//
//class MainActivity : FlutterFragmentActivity() {
//
//    companion object {
//        private const val TAG = "MainActivity"
//        private const val CHANNEL = "com.example.expense_tracker/sms"
//        private var methodChannel: MethodChannel? = null
//        private var isFlutterReady = false
//
//        // Add this for permission request
//        private const val SMS_PERMISSION_REQUEST_CODE = 101
//
//        fun isChannelReady(): Boolean {
//            val ready = isFlutterReady && methodChannel != null
//            Log.d(TAG, "Channel ready: $ready (isFlutterReady=$isFlutterReady, channel=${methodChannel != null})")
//            return ready
//        }
//
//        fun sendSmsToFlutter(data: Map<String, Any>) {
//            // ... (this function is fine, no changes needed)
//            try {
//                Log.d(TAG, "========================================")
//                Log.d(TAG, "Sending to Flutter...")
//                Log.d(TAG, "Channel: $CHANNEL")
//                Log.d(TAG, "Method: onSmsReceived")
//                Log.d(TAG, "Data: $data")
//
//                if (methodChannel == null) {
//                    Log.e(TAG, "❌ Method channel is null!")
//                    return
//                }
//
//                if (!isFlutterReady) {
//                    Log.e(TAG, "❌ Flutter not ready!")
//                    return
//                }
//
//                methodChannel?.invokeMethod("onSmsReceived", data)
//                Log.d(TAG, "✅ Successfully invoked Flutter method")
//                Log.d(TAG, "========================================")
//
//            } catch (e: Exception) {
//                Log.e(TAG, "❌ Error sending SMS to Flutter: ${e.message}", e)
//                Log.e(TAG, "Stack trace:", e)
//            }
//        }
//    }
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        Log.d(TAG, "========================================")
//        Log.d(TAG, "Configuring Flutter engine...")
//        Log.d(TAG, "Channel name: $CHANNEL")
//
//        methodChannel = MethodChannel(
//            flutterEngine.dartExecutor.binaryMessenger,
//            CHANNEL
//        )
//
//        methodChannel?.setMethodCallHandler { call, result ->
//            Log.d(TAG, "Method call from Flutter: ${call.method}")
//
//            when (call.method) {
//                "testReceiver" -> {
//                    Log.d(TAG, "Test receiver called from Flutter")
//                    result.success("Receiver is working!")
//                }
//
//                // --- START PERMISSION FIX ---
//                "checkPermissions" -> {
//                    Log.d(TAG, "Check permissions called")
//                    val hasPermission = ContextCompat.checkSelfPermission(
//                        this,
//                        Manifest.permission.RECEIVE_SMS
//                    ) == PackageManager.PERMISSION_GRANTED
//                    Log.d(TAG, "Has SMS permission: $hasPermission")
//                    result.success(hasPermission)
//                }
//                "requestPermissions" -> {
//                    Log.d(TAG, "Request permissions called")
//                    ActivityCompat.requestPermissions(
//                        this,
//                        arrayOf(Manifest.permission.RECEIVE_SMS, Manifest.permission.READ_SMS),
//                        SMS_PERMISSION_REQUEST_CODE
//                    )
//                    // Result is sent back via onRequestPermissionsResult
//                    result.success(null) // Acknowledge the call
//                }
//                // --- END PERMISSION FIX ---
//
//                else -> {
//                    Log.w(TAG, "Unknown method: ${call.method}")
//                    result.notImplemented()
//                }
//            }
//        }
//
//        isFlutterReady = true
//        Log.d(TAG, "✅ Flutter channel configured successfully")
//        Log.d(TAG, "✅ Activity type: FlutterFragmentActivity (supports biometric)")
//        Log.d(TAG, "========================================")
//    }
//
//    // --- ADD THIS ENTIRE FUNCTION ---
//    override fun onRequestPermissionsResult(
//        requestCode: Int,
//        permissions: Array<out String>,
//        grantResults: IntArray
//    ) {
//        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
//        Log.d(TAG, "onRequestPermissionsResult: $requestCode")
//
//        if (requestCode == SMS_PERMISSION_REQUEST_CODE) {
//            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
//            Log.d(TAG, "SMS Permission granted: $granted")
//            try {
//                // Send the result back to Flutter
//                methodChannel?.invokeMethod("onPermissionResult", granted)
//            } catch (e: Exception) {
//                Log.e(TAG, "Error invoking onPermissionResult", e)
//            }
//        }
//    }
//    // --- END OF NEW FUNCTION ---
//
//    // ... (onCreate, onResume, onPause, onDestroy are fine, no changes needed)
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        Log.d(TAG, "MainActivity onCreate - FlutterFragmentActivity")
//    }
//
//    override fun onResume() {
//        super.onResume()
//        isFlutterReady = true
//        Log.d(TAG, "MainActivity onResume - Channel ready")
//    }
//
//    override fun onPause() {
//        super.onPause()
//        Log.d(TAG, "MainActivity onPause - Channel still active")
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        isFlutterReady = false
//        methodChannel = null
//        Log.d(TAG, "MainActivity onDestroy - Channel destroyed")
//    }
//}

package com.example.expense_tracker

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"

        // SMS Channel
        private const val SMS_CHANNEL = "com.example.expense_tracker/sms"
        private var smsMethodChannel: MethodChannel? = null

        // Privacy/Secure Window Channel
        private const val SECURE_CHANNEL = "com.expense_tracker/secure_window"
        private var secureMethodChannel: MethodChannel? = null

        private var isFlutterReady = false

        // Permission request codes
        private const val SMS_PERMISSION_REQUEST_CODE = 101
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 102

        fun isChannelReady(): Boolean {
            val ready = isFlutterReady && smsMethodChannel != null
            Log.d(TAG, "Channel ready: $ready (isFlutterReady=$isFlutterReady, smsChannel=${smsMethodChannel != null})")
            return ready
        }

        fun sendSmsToFlutter(data: Map<String, Any>) {
            try {
                Log.d(TAG, "========================================")
                Log.d(TAG, "Sending SMS to Flutter...")
                Log.d(TAG, "Channel: $SMS_CHANNEL")
                Log.d(TAG, "Method: onSmsReceived")
                Log.d(TAG, "Data: $data")

                if (smsMethodChannel == null) {
                    Log.e(TAG, "❌ SMS Method channel is null!")
                    return
                }

                if (!isFlutterReady) {
                    Log.e(TAG, "❌ Flutter not ready!")
                    return
                }

                smsMethodChannel?.invokeMethod("onSmsReceived", data)
                Log.d(TAG, "✅ Successfully invoked Flutter method")
                Log.d(TAG, "========================================")

            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending SMS to Flutter: ${e.message}", e)
                Log.e(TAG, "Stack trace:", e)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d(TAG, "========================================")
        Log.d(TAG, "Configuring Flutter engine...")

        // ===================================================
        // SMS CHANNEL CONFIGURATION
        // ===================================================
        Log.d(TAG, "Setting up SMS channel: $SMS_CHANNEL")

        smsMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SMS_CHANNEL
        )

        smsMethodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "SMS Channel - Method call: ${call.method}")

            when (call.method) {
                "testReceiver" -> {
                    Log.d(TAG, "Test receiver called from Flutter")
                    result.success("Receiver is working!")
                }

                "checkPermissions" -> {
                    Log.d(TAG, "Check SMS permissions called")
                    val hasReceiveSms = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    val hasReadSms = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.READ_SMS
                    ) == PackageManager.PERMISSION_GRANTED

                    val hasPermission = hasReceiveSms && hasReadSms
                    Log.d(TAG, "Has SMS permissions: $hasPermission (RECEIVE: $hasReceiveSms, READ: $hasReadSms)")
                    result.success(hasPermission)
                }

                "requestPermissions" -> {
                    Log.d(TAG, "Request SMS permissions called")
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(
                            Manifest.permission.RECEIVE_SMS,
                            Manifest.permission.READ_SMS
                        ),
                        SMS_PERMISSION_REQUEST_CODE
                    )
                    result.success(null)
                }

                else -> {
                    Log.w(TAG, "SMS Channel - Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        Log.d(TAG, "✅ SMS channel configured")

        // ===================================================
        // PRIVACY/SECURE WINDOW CHANNEL CONFIGURATION
        // ===================================================
        Log.d(TAG, "Setting up Secure Window channel: $SECURE_CHANNEL")

        secureMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURE_CHANNEL
        )

        secureMethodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "Secure Channel - Method call: ${call.method}")

            when (call.method) {
                "setSecureFlag" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    Log.d(TAG, "Setting secure flag: $secure")

                    try {
                        setSecureFlag(secure)
                        result.success(true)
                        Log.d(TAG, "✅ Secure flag set successfully: $secure")
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error setting secure flag: ${e.message}", e)
                        result.error("SECURE_FLAG_ERROR", e.message, null)
                    }
                }

                else -> {
                    Log.w(TAG, "Secure Channel - Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        Log.d(TAG, "✅ Secure Window channel configured")

        isFlutterReady = true
        Log.d(TAG, "✅ All Flutter channels configured successfully")
        Log.d(TAG, "✅ Activity type: FlutterFragmentActivity (supports biometric)")
        Log.d(TAG, "========================================")
    }

    /**
     * Sets the FLAG_SECURE on the window to prevent screenshots and screen recording
     * @param secure true to enable protection, false to disable
     */
    private fun setSecureFlag(secure: Boolean) {
        if (secure) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
            Log.d(TAG, "🔒 FLAG_SECURE enabled - Screenshots and screen recording blocked")
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            Log.d(TAG, "🔓 FLAG_SECURE disabled - Screenshots and screen recording allowed")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        Log.d(TAG, "========================================")
        Log.d(TAG, "onRequestPermissionsResult: requestCode=$requestCode")
        Log.d(TAG, "Permissions: ${permissions.joinToString()}")
        Log.d(TAG, "Results: ${grantResults.joinToString()}")

        when (requestCode) {
            SMS_PERMISSION_REQUEST_CODE -> {
                val allGranted = grantResults.isNotEmpty() &&
                        grantResults.all { it == PackageManager.PERMISSION_GRANTED }

                Log.d(TAG, "SMS Permissions granted: $allGranted")

                try {
                    // Send the result back to Flutter via SMS channel
                    smsMethodChannel?.invokeMethod("onPermissionResult", allGranted)
                    Log.d(TAG, "✅ Permission result sent to Flutter")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error invoking onPermissionResult: ${e.message}", e)
                }
            }

            NOTIFICATION_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED

                Log.d(TAG, "Notification Permission granted: $granted")
                // Handle notification permission if needed
            }

            else -> {
                Log.w(TAG, "Unknown permission request code: $requestCode")
            }
        }

        Log.d(TAG, "========================================")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "========================================")
        Log.d(TAG, "MainActivity onCreate - FlutterFragmentActivity")
        Log.d(TAG, "Package: ${applicationContext.packageName}")
        Log.d(TAG, "========================================")
    }

    override fun onResume() {
        super.onResume()
        isFlutterReady = true
        Log.d(TAG, "MainActivity onResume - Channels ready")
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity onPause - Channels still active")
    }

    override fun onDestroy() {
        super.onDestroy()
        isFlutterReady = false
        smsMethodChannel = null
        secureMethodChannel = null
        Log.d(TAG, "========================================")
        Log.d(TAG, "MainActivity onDestroy - All channels destroyed")
        Log.d(TAG, "========================================")
    }
}