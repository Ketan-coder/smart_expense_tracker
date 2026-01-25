//package com.example.expense_tracker
//
//import android.Manifest
//import android.content.pm.PackageManager
//import android.os.Bundle
//import android.util.Log
//import android.view.WindowManager
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
//
//        // SMS Channel
//        private const val SMS_CHANNEL = "com.example.expense_tracker/sms"
//        private var smsMethodChannel: MethodChannel? = null
//
//        // Privacy/Secure Window Channel
//        private const val SECURE_CHANNEL = "com.expense_tracker/secure_window"
//        private var secureMethodChannel: MethodChannel? = null
//
//        private var isFlutterReady = false
//
//        // Permission request codes
//        private const val SMS_PERMISSION_REQUEST_CODE = 101
//        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 102
//
//        fun isChannelReady(): Boolean {
//            val ready = isFlutterReady && smsMethodChannel != null
//            Log.d(TAG, "Channel ready: $ready (isFlutterReady=$isFlutterReady, smsChannel=${smsMethodChannel != null})")
//            return ready
//        }
//
//        fun sendSmsToFlutter(data: Map<String, Any>) {
//            try {
//                Log.d(TAG, "========================================")
//                Log.d(TAG, "Sending SMS to Flutter...")
//                Log.d(TAG, "Channel: $SMS_CHANNEL")
//                Log.d(TAG, "Method: onSmsReceived")
//                Log.d(TAG, "Data: $data")
//
//                if (smsMethodChannel == null) {
//                    Log.e(TAG, "❌ SMS Method channel is null!")
//                    return
//                }
//
//                if (!isFlutterReady) {
//                    Log.e(TAG, "❌ Flutter not ready!")
//                    return
//                }
//
//                smsMethodChannel?.invokeMethod("onSmsReceived", data)
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
//
//        // ===================================================
//        // SMS CHANNEL CONFIGURATION
//        // ===================================================
//        Log.d(TAG, "Setting up SMS channel: $SMS_CHANNEL")
//
//        smsMethodChannel = MethodChannel(
//            flutterEngine.dartExecutor.binaryMessenger,
//            SMS_CHANNEL
//        )
//
//        smsMethodChannel?.setMethodCallHandler { call, result ->
//            Log.d(TAG, "SMS Channel - Method call: ${call.method}")
//
//            when (call.method) {
//                "testReceiver" -> {
//                    Log.d(TAG, "Test receiver called from Flutter")
//                    result.success("Receiver is working!")
//                }
//
//                "checkPermissions" -> {
//                    Log.d(TAG, "Check SMS permissions called")
//                    val hasReceiveSms = ContextCompat.checkSelfPermission(
//                        this,
//                        Manifest.permission.RECEIVE_SMS
//                    ) == PackageManager.PERMISSION_GRANTED
//
//                    val hasReadSms = ContextCompat.checkSelfPermission(
//                        this,
//                        Manifest.permission.READ_SMS
//                    ) == PackageManager.PERMISSION_GRANTED
//
//                    val hasPermission = hasReceiveSms && hasReadSms
//                    Log.d(TAG, "Has SMS permissions: $hasPermission (RECEIVE: $hasReceiveSms, READ: $hasReadSms)")
//                    result.success(hasPermission)
//                }
//
//                "requestPermissions" -> {
//                    Log.d(TAG, "Request SMS permissions called")
//                    ActivityCompat.requestPermissions(
//                        this,
//                        arrayOf(
//                            Manifest.permission.RECEIVE_SMS,
//                            Manifest.permission.READ_SMS
//                        ),
//                        SMS_PERMISSION_REQUEST_CODE
//                    )
//                    result.success(null)
//                }
//
//                else -> {
//                    Log.w(TAG, "SMS Channel - Unknown method: ${call.method}")
//                    result.notImplemented()
//                }
//            }
//        }
//
//        Log.d(TAG, "✅ SMS channel configured")
//
//        // ===================================================
//        // PRIVACY/SECURE WINDOW CHANNEL CONFIGURATION
//        // ===================================================
//        Log.d(TAG, "Setting up Secure Window channel: $SECURE_CHANNEL")
//
//        secureMethodChannel = MethodChannel(
//            flutterEngine.dartExecutor.binaryMessenger,
//            SECURE_CHANNEL
//        )
//
//        secureMethodChannel?.setMethodCallHandler { call, result ->
//            Log.d(TAG, "Secure Channel - Method call: ${call.method}")
//
//            when (call.method) {
//                "setSecureFlag" -> {
//                    val secure = call.argument<Boolean>("secure") ?: false
//                    Log.d(TAG, "Setting secure flag: $secure")
//
//                    try {
//                        setSecureFlag(secure)
//                        result.success(true)
//                        Log.d(TAG, "✅ Secure flag set successfully: $secure")
//                    } catch (e: Exception) {
//                        Log.e(TAG, "❌ Error setting secure flag: ${e.message}", e)
//                        result.error("SECURE_FLAG_ERROR", e.message, null)
//                    }
//                }
//
//                else -> {
//                    Log.w(TAG, "Secure Channel - Unknown method: ${call.method}")
//                    result.notImplemented()
//                }
//            }
//        }
//
//        Log.d(TAG, "✅ Secure Window channel configured")
//
//        isFlutterReady = true
//        Log.d(TAG, "✅ All Flutter channels configured successfully")
//        Log.d(TAG, "✅ Activity type: FlutterFragmentActivity (supports biometric)")
//        Log.d(TAG, "========================================")
//    }
//
//    /**
//     * Sets the FLAG_SECURE on the window to prevent screenshots and screen recording
//     * @param secure true to enable protection, false to disable
//     */
//    private fun setSecureFlag(secure: Boolean) {
//        if (secure) {
//            window.setFlags(
//                WindowManager.LayoutParams.FLAG_SECURE,
//                WindowManager.LayoutParams.FLAG_SECURE
//            )
//            Log.d(TAG, "🔒 FLAG_SECURE enabled - Screenshots and screen recording blocked")
//        } else {
//            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
//            Log.d(TAG, "🔓 FLAG_SECURE disabled - Screenshots and screen recording allowed")
//        }
//    }
//
//    override fun onRequestPermissionsResult(
//        requestCode: Int,
//        permissions: Array<out String>,
//        grantResults: IntArray
//    ) {
//        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
//        Log.d(TAG, "========================================")
//        Log.d(TAG, "onRequestPermissionsResult: requestCode=$requestCode")
//        Log.d(TAG, "Permissions: ${permissions.joinToString()}")
//        Log.d(TAG, "Results: ${grantResults.joinToString()}")
//
//        when (requestCode) {
//            SMS_PERMISSION_REQUEST_CODE -> {
//                val allGranted = grantResults.isNotEmpty() &&
//                        grantResults.all { it == PackageManager.PERMISSION_GRANTED }
//
//                Log.d(TAG, "SMS Permissions granted: $allGranted")
//
//                try {
//                    // Send the result back to Flutter via SMS channel
//                    smsMethodChannel?.invokeMethod("onPermissionResult", allGranted)
//                    Log.d(TAG, "✅ Permission result sent to Flutter")
//                } catch (e: Exception) {
//                    Log.e(TAG, "❌ Error invoking onPermissionResult: ${e.message}", e)
//                }
//            }
//
//            NOTIFICATION_PERMISSION_REQUEST_CODE -> {
//                val granted = grantResults.isNotEmpty() &&
//                        grantResults[0] == PackageManager.PERMISSION_GRANTED
//
//                Log.d(TAG, "Notification Permission granted: $granted")
//                // Handle notification permission if needed
//            }
//
//            else -> {
//                Log.w(TAG, "Unknown permission request code: $requestCode")
//            }
//        }
//
//        Log.d(TAG, "========================================")
//    }
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        Log.d(TAG, "========================================")
//        Log.d(TAG, "MainActivity onCreate - FlutterFragmentActivity")
//        Log.d(TAG, "Package: ${applicationContext.packageName}")
//        Log.d(TAG, "========================================")
//    }
//
//    override fun onResume() {
//        super.onResume()
//        isFlutterReady = true
//        Log.d(TAG, "MainActivity onResume - Channels ready")
//    }
//
//    override fun onPause() {
//        super.onPause()
//        Log.d(TAG, "MainActivity onPause - Channels still active")
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        isFlutterReady = false
//        smsMethodChannel = null
//        secureMethodChannel = null
//        Log.d(TAG, "========================================")
//        Log.d(TAG, "MainActivity onDestroy - All channels destroyed")
//        Log.d(TAG, "========================================")
//    }
//}

package com.example.expense_tracker

import android.Manifest
import android.app.WallpaperManager
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"

        // SMS Channel
        private const val SMS_CHANNEL = "com.example.expense_tracker/sms"
        private var smsMethodChannel: MethodChannel? = null

        // Privacy/Secure Window Channel
        private const val SECURE_CHANNEL = "com.expense_tracker/secure_window"
        private var secureMethodChannel: MethodChannel? = null

        // Wallpaper Channel
        private const val WALLPAPER_CHANNEL = "com.yourapp.wallpaper/set"
        private var wallpaperMethodChannel: MethodChannel? = null

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

        // ===================================================
        // WALLPAPER CHANNEL CONFIGURATION
        // ===================================================
        Log.d(TAG, "Setting up Wallpaper channel: $WALLPAPER_CHANNEL")

        wallpaperMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WALLPAPER_CHANNEL
        )

        wallpaperMethodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "Wallpaper Channel - Method call: ${call.method}")

            when (call.method) {
                "setWallpaper" -> {
                    val filePath = call.argument<String>("filePath")
                    val location = call.argument<String>("location")

                    Log.d(TAG, "Setting wallpaper - File: $filePath, Location: $location")

                    if (filePath != null && location != null) {
                        try {
                            val success = setWallpaper(filePath, location)
                            result.success(success)
                            Log.d(TAG, if (success) "✅ Wallpaper set successfully" else "⚠️ Failed to set wallpaper")
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Error setting wallpaper: ${e.message}", e)
                            result.error("WALLPAPER_ERROR", e.message, null)
                        }
                    } else {
                        Log.e(TAG, "❌ Invalid arguments for setWallpaper")
                        result.error("INVALID_ARGS", "File path or location is null", null)
                    }
                }

                else -> {
                    Log.w(TAG, "Wallpaper Channel - Unknown method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        Log.d(TAG, "✅ Wallpaper channel configured")

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

    /**
     * Sets wallpaper from file path to specified location
     * @param filePath Absolute path to the wallpaper image file
     * @param location "lock", "home", or "both"
     * @return true if successful, false otherwise
     */
    private fun setWallpaper(filePath: String, location: String): Boolean {
        return try {
            Log.d(TAG, "========================================")
            Log.d(TAG, "Setting wallpaper...")
            Log.d(TAG, "File: $filePath")
            Log.d(TAG, "Location: $location")
            Log.d(TAG, "Android Version: ${android.os.Build.VERSION.SDK_INT}")

            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
            val file = File(filePath)

            if (!file.exists()) {
                Log.e(TAG, "❌ Wallpaper file does not exist: $filePath")
                return false
            }

            Log.d(TAG, "📁 File exists, size: ${file.length()} bytes (${file.length() / 1024} KB)")

            val bitmap = BitmapFactory.decodeFile(filePath)
            if (bitmap == null) {
                Log.e(TAG, "❌ Failed to decode bitmap from: $filePath")
                return false
            }

            Log.d(TAG, "🖼️ Bitmap decoded: ${bitmap.width}x${bitmap.height}")

            // Set wallpaper based on location
            when (location.lowercase()) {
                "lock" -> {
                    Log.d(TAG, "🔒 Setting LOCK screen wallpaper...")
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        wallpaperManager.setBitmap(
                            bitmap,
                            null,
                            true,
                            WallpaperManager.FLAG_LOCK
                        )
                        Log.d(TAG, "✅ Lock screen wallpaper set successfully (API ${android.os.Build.VERSION.SDK_INT})")
                    } else {
                        // For older versions, set as system wallpaper
                        wallpaperManager.setBitmap(bitmap)
                        Log.d(TAG, "✅ System wallpaper set (API ${android.os.Build.VERSION.SDK_INT} - no separate lock screen)")
                    }
                }
                "home" -> {
                    Log.d(TAG, "🏠 Setting HOME screen wallpaper...")
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        wallpaperManager.setBitmap(
                            bitmap,
                            null,
                            true,
                            WallpaperManager.FLAG_SYSTEM
                        )
                        Log.d(TAG, "✅ Home screen wallpaper set successfully")
                    } else {
                        wallpaperManager.setBitmap(bitmap)
                        Log.d(TAG, "✅ System wallpaper set")
                    }
                }
                "both" -> {
                    Log.d(TAG, "🏠🔒 Setting BOTH screens wallpaper...")
                    wallpaperManager.setBitmap(bitmap)

                    // Force refresh by also setting to lock screen explicitly on API 24+
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        try {
                            wallpaperManager.setBitmap(
                                bitmap,
                                null,
                                true,
                                WallpaperManager.FLAG_LOCK
                            )
                            Log.d(TAG, "✅ Also set lock screen explicitly")
                        } catch (e: Exception) {
                            Log.w(TAG, "⚠️ Could not set lock screen: ${e.message}")
                        }
                    }

                    Log.d(TAG, "✅ Both screens wallpaper set successfully")
                }
                else -> {
                    Log.e(TAG, "❌ Unknown location: $location")
                    bitmap.recycle()
                    return false
                }
            }

            // Force wallpaper manager to refresh
            try {
                wallpaperManager.forgetLoadedWallpaper()
                Log.d(TAG, "🔄 Forced wallpaper refresh")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Could not force refresh: ${e.message}")
            }

            bitmap.recycle()
            Log.d(TAG, "✅ Wallpaper operation completed successfully")
            Log.d(TAG, "💡 TIP: Lock your device to see the change immediately")
            Log.d(TAG, "========================================")
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "❌ SECURITY EXCEPTION: Missing SET_WALLPAPER permission!", e)
            Log.e(TAG, "Check AndroidManifest.xml for: <uses-permission android:name=\"android.permission.SET_WALLPAPER\" />")
            Log.d(TAG, "========================================")
            false
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error setting wallpaper", e)
            Log.e(TAG, "Exception type: ${e.javaClass.simpleName}")
            Log.e(TAG, "Exception message: ${e.message}")
            e.printStackTrace()
            Log.d(TAG, "========================================")
            false
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
        Log.d(TAG, "MainActivity onResume - All channels ready")
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
        wallpaperMethodChannel = null
        Log.d(TAG, "========================================")
        Log.d(TAG, "MainActivity onDestroy - All channels destroyed")
        Log.d(TAG, "========================================")
    }
}