import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Manages adaptive screen brightness for privacy mode
/// Temporarily dims screen when privacy is active
/// Restores original brightness when privacy is deactivated
class AdaptiveBrightnessService {
  static final AdaptiveBrightnessService _instance = AdaptiveBrightnessService._internal();
  factory AdaptiveBrightnessService() => _instance;
  AdaptiveBrightnessService._internal();

  final ScreenBrightness _screenBrightness = ScreenBrightness();

  double? _originalBrightness;
  bool _isDimmed = false;
  bool _wasUsingSystemBrightness = false;

  // Privacy mode reduces brightness by this factor
  static const double _privacyBrightnessFactor = 0.7;
  static const double _minBrightness = 0.2; // Don't go too dark

  /// Check if system brightness is being used (adaptive brightness)
  Future<bool> _isUsingSystemBrightness() async {
    try {
      // If hasChanged is false, it means system brightness is in control
      return !(await _screenBrightness.hasChanged);
    } catch (e) {
      debugPrint("❌ Error checking system brightness: $e");
      return false;
    }
  }

  /// Dim the screen for privacy mode
  Future<void> dimForPrivacy() async {
    if (_isDimmed) return;

    try {
      // Check if using system/adaptive brightness
      _wasUsingSystemBrightness = await _isUsingSystemBrightness();

      // Store original brightness
      _originalBrightness = await _screenBrightness.current;

      // Calculate dimmed brightness
      final targetBrightness = (_originalBrightness! * _privacyBrightnessFactor)
          .clamp(_minBrightness, 1.0);

      await _screenBrightness.setScreenBrightness(targetBrightness);
      _isDimmed = true;

      debugPrint("💡 Screen dimmed: ${_originalBrightness!.toStringAsFixed(2)} → ${targetBrightness.toStringAsFixed(2)}");
      debugPrint("💡 Was using system brightness: $_wasUsingSystemBrightness");
    } catch (e) {
      debugPrint("❌ Error dimming screen: $e");
    }
  }

  /// Restore original brightness
  Future<void> restoreBrightness() async {
    if (!_isDimmed) return;

    try {
      // If was using system brightness (adaptive), reset to system control
      if (_wasUsingSystemBrightness) {
        await _screenBrightness.resetScreenBrightness();
        debugPrint("💡 Screen brightness reset to system control (adaptive)");
      } else if (_originalBrightness != null) {
        // Otherwise restore the manual brightness value
        await _screenBrightness.setScreenBrightness(_originalBrightness!);
        debugPrint("💡 Screen brightness restored: ${_originalBrightness!.toStringAsFixed(2)}");
      }

      _isDimmed = false;
      _originalBrightness = null;
      _wasUsingSystemBrightness = false;
    } catch (e) {
      debugPrint("❌ Error restoring brightness: $e");
      // Fallback: try to reset to system
      try {
        await _screenBrightness.resetScreenBrightness();
      } catch (e2) {
        debugPrint("❌ Error in fallback reset: $e2");
      }
    }
  }

  /// Reset to system brightness (use when app is closed or service disabled)
  Future<void> resetToSystem() async {
    try {
      await _screenBrightness.resetScreenBrightness();
      _isDimmed = false;
      _originalBrightness = null;
      _wasUsingSystemBrightness = false;
      debugPrint("💡 Brightness reset to system default");
    } catch (e) {
      debugPrint("❌ Error resetting brightness: $e");
    }
  }

  bool get isDimmed => _isDimmed;
  bool get wasUsingSystemBrightness => _wasUsingSystemBrightness;
}