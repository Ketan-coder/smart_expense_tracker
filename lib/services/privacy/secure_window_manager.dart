import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages screenshot and screen recording protection using platform channels
/// Android: FLAG_SECURE
/// iOS: Custom detection with overlay warning
class SecureWindowManager {
  static const MethodChannel _channel = MethodChannel('com.expense_tracker/secure_window');

  static bool _isSecured = false;
  static bool get isSecured => _isSecured;

  /// Enable screenshot/screen recording protection
  static Future<bool> enableProtection() async {
    try {
      if (kIsWeb) {
        debugPrint("🔒 Screenshot protection not available on web");
        return false;
      }

      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('setSecureFlag', {'secure': true});
        _isSecured = result == true;
        debugPrint("🔒 Android FLAG_SECURE enabled: $_isSecured");
        return _isSecured;
      } else if (Platform.isIOS) {
        // iOS doesn't support FLAG_SECURE equivalent
        // We'll handle this with overlay detection in the UI layer
        _isSecured = true;
        debugPrint("🔒 iOS screenshot protection: UI overlay mode");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ Error enabling screenshot protection: $e");
      return false;
    }
  }

  /// Disable screenshot/screen recording protection
  static Future<bool> disableProtection() async {
    try {
      if (kIsWeb || !Platform.isAndroid) {
        _isSecured = false;
        return true;
      }

      final result = await _channel.invokeMethod('setSecureFlag', {'secure': false});
      _isSecured = false;
      debugPrint("🔓 Screenshot protection disabled");
      return result == true;
    } catch (e) {
      debugPrint("❌ Error disabling screenshot protection: $e");
      return false;
    }
  }

  /// Toggle protection on/off
  static Future<bool> toggleProtection(bool enable) async {
    return enable ? await enableProtection() : await disableProtection();
  }
}