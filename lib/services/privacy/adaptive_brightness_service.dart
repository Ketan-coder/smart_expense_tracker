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

  // Privacy mode reduces brightness by this factor
  static const double _privacyBrightnessFactor = 0.7;
  static const double _minBrightness = 0.2; // Don't go too dark

  /// Dim the screen for privacy mode
  Future<void> dimForPrivacy() async {
    if (_isDimmed) return;

    try {
      // Store original brightness
      _originalBrightness = await _screenBrightness.current;

      // Calculate dimmed brightness
      final targetBrightness = (_originalBrightness! * _privacyBrightnessFactor)
          .clamp(_minBrightness, 1.0);

      await _screenBrightness.setScreenBrightness(targetBrightness);
      _isDimmed = true;

      debugPrint("💡 Screen dimmed: ${_originalBrightness!.toStringAsFixed(2)} → ${targetBrightness.toStringAsFixed(2)}");
    } catch (e) {
      debugPrint("❌ Error dimming screen: $e");
    }
  }

  /// Restore original brightness
  Future<void> restoreBrightness() async {
    if (!_isDimmed || _originalBrightness == null) return;

    try {
      await _screenBrightness.setScreenBrightness(_originalBrightness!);
      _isDimmed = false;

      debugPrint("💡 Screen brightness restored: ${_originalBrightness!.toStringAsFixed(2)}");
      _originalBrightness = null;
    } catch (e) {
      debugPrint("❌ Error restoring brightness: $e");
    }
  }

  /// Reset to system brightness
  Future<void> resetToSystem() async {
    try {
      await _screenBrightness.resetScreenBrightness();
      _isDimmed = false;
      _originalBrightness = null;
      debugPrint("💡 Brightness reset to system default");
    } catch (e) {
      debugPrint("❌ Error resetting brightness: $e");
    }
  }

  bool get isDimmed => _isDimmed;
}