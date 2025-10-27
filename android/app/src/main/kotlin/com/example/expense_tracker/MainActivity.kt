//package com.example.expense_tracker
//import android.os.Bundle
//import android.util.Log
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//
//class MainActivity : FlutterActivity() {
//
//    companion object {
//        private const val TAG = "MainActivity"
//        private const val CHANNEL = "com.example.expense_tracker/sms"
//        private var methodChannel: MethodChannel? = null
//        private var isFlutterReady = false
//
//        fun isChannelReady(): Boolean {
//            val ready = isFlutterReady && methodChannel != null
//            Log.d(TAG, "Channel ready: $ready (isFlutterReady=$isFlutterReady, channel=${methodChannel != null})")
//            return ready
//        }
//
//        fun sendSmsToFlutter(data: Map<String, Any>) {
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
//        // Set up method call handler for Flutter -> Native calls
//        methodChannel?.setMethodCallHandler { call, result ->
//            Log.d(TAG, "Method call from Flutter: ${call.method}")
//
//            when (call.method) {
//                "testReceiver" -> {
//                    Log.d(TAG, "Test receiver called from Flutter")
//                    result.success("Receiver is working!")
//                }
//                "checkPermissions" -> {
//                    Log.d(TAG, "Check permissions called")
//                    // You can implement permission check here if needed
//                    result.success(true)
//                }
//                "requestPermissions" -> {
//                    Log.d(TAG, "Request permissions called")
//                    // You can implement permission request here if needed
//                    result.success(true)
//                }
//                else -> {
//                    Log.w(TAG, "Unknown method: ${call.method}")
//                    result.notImplemented()
//                }
//            }
//        }
//
//        isFlutterReady = true
//        Log.d(TAG, "✅ Flutter channel configured successfully")
//        Log.d(TAG, "========================================")
//    }
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        Log.d(TAG, "MainActivity onCreate")
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
//        // Keep channel ready for background SMS
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
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.example.expense_tracker/sms"
        private var methodChannel: MethodChannel? = null
        private var isFlutterReady = false

        // Add this for permission request
        private const val SMS_PERMISSION_REQUEST_CODE = 101

        fun isChannelReady(): Boolean {
            val ready = isFlutterReady && methodChannel != null
            Log.d(TAG, "Channel ready: $ready (isFlutterReady=$isFlutterReady, channel=${methodChannel != null})")
            return ready
        }

        fun sendSmsToFlutter(data: Map<String, Any>) {
            // ... (this function is fine, no changes needed)
            try {
                Log.d(TAG, "========================================")
                Log.d(TAG, "Sending to Flutter...")
                Log.d(TAG, "Channel: $CHANNEL")
                Log.d(TAG, "Method: onSmsReceived")
                Log.d(TAG, "Data: $data")

                if (methodChannel == null) {
                    Log.e(TAG, "❌ Method channel is null!")
                    return
                }

                if (!isFlutterReady) {
                    Log.e(TAG, "❌ Flutter not ready!")
                    return
                }

                methodChannel?.invokeMethod("onSmsReceived", data)
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
        Log.d(TAG, "Channel name: $CHANNEL")

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "Method call from Flutter: ${call.method}")

            when (call.method) {
                "testReceiver" -> {
                    Log.d(TAG, "Test receiver called from Flutter")
                    result.success("Receiver is working!")
                }

                // --- START PERMISSION FIX ---
                "checkPermissions" -> {
                    Log.d(TAG, "Check permissions called")
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    Log.d(TAG, "Has SMS permission: $hasPermission")
                    result.success(hasPermission)
                }
                "requestPermissions" -> {
                    Log.d(TAG, "Request permissions called")
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.RECEIVE_SMS, Manifest.permission.READ_SMS),
                        SMS_PERMISSION_REQUEST_CODE
                    )
                    // Result is sent back via onRequestPermissionsResult
                    result.success(null) // Acknowledge the call
                }
                // --- END PERMISSION FIX ---

                else -> {
                    Log.w(TAG, "Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        isFlutterReady = true
        Log.d(TAG, "✅ Flutter channel configured successfully")
        Log.d(TAG, "✅ Activity type: FlutterFragmentActivity (supports biometric)")
        Log.d(TAG, "========================================")
    }

    // --- ADD THIS ENTIRE FUNCTION ---
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        Log.d(TAG, "onRequestPermissionsResult: $requestCode")

        if (requestCode == SMS_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            Log.d(TAG, "SMS Permission granted: $granted")
            try {
                // Send the result back to Flutter
                methodChannel?.invokeMethod("onPermissionResult", granted)
            } catch (e: Exception) {
                Log.e(TAG, "Error invoking onPermissionResult", e)
            }
        }
    }
    // --- END OF NEW FUNCTION ---

    // ... (onCreate, onResume, onPause, onDestroy are fine, no changes needed)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate - FlutterFragmentActivity")
    }

    override fun onResume() {
        super.onResume()
        isFlutterReady = true
        Log.d(TAG, "MainActivity onResume - Channel ready")
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity onPause - Channel still active")
    }

    override fun onDestroy() {
        super.onDestroy()
        isFlutterReady = false
        methodChannel = null
        Log.d(TAG, "MainActivity onDestroy - Channel destroyed")
    }
}