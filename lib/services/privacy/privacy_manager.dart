import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central privacy state management for the expense tracker
/// Provides reactive privacy controls with persistence
class PrivacyManager extends ChangeNotifier {
  static final PrivacyManager _instance = PrivacyManager._internal();
  factory PrivacyManager() => _instance;
  PrivacyManager._internal();

  // Privacy states
  bool _privacyModeEnabled = true;
  bool _screenshotProtectionEnabled = true;
  bool _shakeToPrivacyEnabled = true;
  bool _faceDetectionEnabled = false;
  bool _adaptiveBrightnessEnabled = true;
  bool _isPrivacyActive = false; // Current runtime state

  // Getters
  bool get privacyModeEnabled => _privacyModeEnabled;
  bool get screenshotProtectionEnabled => _screenshotProtectionEnabled;
  bool get shakeToPrivacyEnabled => _shakeToPrivacyEnabled;
  bool get faceDetectionEnabled => _faceDetectionEnabled;
  bool get adaptiveBrightnessEnabled => _adaptiveBrightnessEnabled;
  bool get isPrivacyActive => _isPrivacyActive;

  // SharedPreferences keys
  static const String _keyPrivacyMode = 'privacy_mode_enabled';
  static const String _keyScreenshotProtection = 'screenshot_protection_enabled';
  static const String _keyShakeToPrivacy = 'shake_to_privacy_enabled';
  static const String _keyFaceDetection = 'face_detection_enabled';
  static const String _keyAdaptiveBrightness = 'adaptive_brightness_enabled';

  /// Initialize privacy settings from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _privacyModeEnabled = prefs.getBool(_keyPrivacyMode) ?? true;
    _screenshotProtectionEnabled = prefs.getBool(_keyScreenshotProtection) ?? true;
    _shakeToPrivacyEnabled = prefs.getBool(_keyShakeToPrivacy) ?? true;
    _faceDetectionEnabled = prefs.getBool(_keyFaceDetection) ?? false;
    _adaptiveBrightnessEnabled = prefs.getBool(_keyAdaptiveBrightness) ?? true;

    // Start with privacy active if enabled
    _isPrivacyActive = _privacyModeEnabled;

    debugPrint("🔒 Privacy Manager Initialized:");
    debugPrint("   Privacy Mode: $_privacyModeEnabled");
    debugPrint("   Screenshot Protection: $_screenshotProtectionEnabled");
    debugPrint("   Shake to Privacy: $_shakeToPrivacyEnabled");
    debugPrint("   Face Detection: $_faceDetectionEnabled");
    debugPrint("   Adaptive Brightness: $_adaptiveBrightnessEnabled");

    notifyListeners();
  }

  /// Toggle privacy mode on/off (main switch)
  Future<void> setPrivacyMode(bool enabled) async {
    _privacyModeEnabled = enabled;
    _isPrivacyActive = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivacyMode, enabled);

    debugPrint("🔒 Privacy Mode ${enabled ? 'ENABLED' : 'DISABLED'}");
    notifyListeners();
  }

  /// Toggle screenshot protection
  Future<void> setScreenshotProtection(bool enabled) async {
    _screenshotProtectionEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyScreenshotProtection, enabled);

    debugPrint("📸 Screenshot Protection ${enabled ? 'ENABLED' : 'DISABLED'}");
    notifyListeners();
  }

  /// Toggle shake to activate privacy
  Future<void> setShakeToPrivacy(bool enabled) async {
    _shakeToPrivacyEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShakeToPrivacy, enabled);

    debugPrint("📳 Shake to Privacy ${enabled ? 'ENABLED' : 'DISABLED'}");
    notifyListeners();
  }

  /// Toggle face detection
  Future<void> setFaceDetection(bool enabled) async {
    _faceDetectionEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFaceDetection, enabled);

    debugPrint("👁️ Face Detection ${enabled ? 'ENABLED' : 'DISABLED'}");
    notifyListeners();
  }

  /// Toggle adaptive brightness
  Future<void> setAdaptiveBrightness(bool enabled) async {
    _adaptiveBrightnessEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdaptiveBrightness, enabled);

    debugPrint("💡 Adaptive Brightness ${enabled ? 'ENABLED' : 'DISABLED'}");
    notifyListeners();
  }

  /// Temporarily activate privacy (e.g., from shake or face detection)
  void activatePrivacy({String? reason}) {
    if (!_privacyModeEnabled) return;

    _isPrivacyActive = true;
    debugPrint("🔒 Privacy ACTIVATED${reason != null ? ' - $reason' : ''}");
    notifyListeners();
  }

  /// Deactivate privacy (manual toggle)
  void deactivatePrivacy({String? reason}) {
    _isPrivacyActive = false;
    debugPrint("🔓 Privacy DEACTIVATED${reason != null ? ' - $reason' : ''}");
    notifyListeners();
  }

  /// Quick toggle for UI buttons
  void togglePrivacyActive() {
    if (_isPrivacyActive) {
      deactivatePrivacy(reason: "Manual toggle");
    } else {
      activatePrivacy(reason: "Manual toggle");
    }
  }

  /// Check if sensitive data should be hidden
  bool shouldHideSensitiveData() {
    return _privacyModeEnabled && _isPrivacyActive;
  }

  /// Reset all privacy settings to defaults
  Future<void> resetToDefaults() async {
    _privacyModeEnabled = true;
    _screenshotProtectionEnabled = true;
    _shakeToPrivacyEnabled = true;
    _faceDetectionEnabled = false;
    _adaptiveBrightnessEnabled = true;
    _isPrivacyActive = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivacyMode, true);
    await prefs.setBool(_keyScreenshotProtection, true);
    await prefs.setBool(_keyShakeToPrivacy, true);
    await prefs.setBool(_keyFaceDetection, false);
    await prefs.setBool(_keyAdaptiveBrightness, true);

    debugPrint("🔒 Privacy settings reset to defaults");
    notifyListeners();
  }
}