// ============================================================================
// FILE: lib/services/privacy/secure_window_manager_stub.dart
// Web stub for secure window manager
// ============================================================================
import 'package:flutter/material.dart';

class SecureWindowManager {
  static Future<void> enableProtection() async {
    debugPrint('⚠️ Screenshot protection not available on web');
  }

  static Future<void> disableProtection() async {}

  static Future<void> toggleProtection(bool enable) async {
    if (enable) {
      await enableProtection();
    } else {
      await disableProtection();
    }
  }
}