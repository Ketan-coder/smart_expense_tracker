// ============================================================================
// FILE: lib/services/privacy/privacy_manager_stub.dart
// Web stub for privacy manager
// ============================================================================
import 'package:flutter/material.dart';

class PrivacyManager extends ChangeNotifier {
  bool get isPrivacyActive => false;
  bool get privacyModeEnabled => false;
  bool get screenshotProtectionEnabled => false;
  bool get shakeToPrivacyEnabled => false;
  bool get adaptiveBrightnessEnabled => false;
  bool get faceDetectionEnabled => false;

  Future<void> initialize() async {
    debugPrint('⚠️ Privacy features not available on web');
  }

  Future<void> setPrivacyMode(bool enabled) async {}
  Future<void> setScreenshotProtection(bool enabled) async {}
  Future<void> setShakeToPrivacy(bool enabled) async {}
  Future<void> setAdaptiveBrightness(bool enabled) async {}
  Future<void> setFaceDetection(bool enabled) async {}

  void togglePrivacyActive() {}
  void activatePrivacy({String? reason}) {}
  void deactivatePrivacy() {}
}