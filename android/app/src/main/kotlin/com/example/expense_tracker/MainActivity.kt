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

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// CRITICAL: Must extend FlutterFragmentActivity (not FlutterActivity) for biometric authentication
class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.example.expense_tracker/sms"
        private var methodChannel: MethodChannel? = null
        private var isFlutterReady = false

        fun isChannelReady(): Boolean {
            val ready = isFlutterReady && methodChannel != null
            Log.d(TAG, "Channel ready: $ready (isFlutterReady=$isFlutterReady, channel=${methodChannel != null})")
            return ready
        }

        fun sendSmsToFlutter(data: Map<String, Any>) {
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

        // Set up method call handler for Flutter -> Native calls
        methodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "Method call from Flutter: ${call.method}")

            when (call.method) {
                "testReceiver" -> {
                    Log.d(TAG, "Test receiver called from Flutter")
                    result.success("Receiver is working!")
                }
                "checkPermissions" -> {
                    Log.d(TAG, "Check permissions called")
                    result.success(true)
                }
                "requestPermissions" -> {
                    Log.d(TAG, "Request permissions called")
                    result.success(true)
                }
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