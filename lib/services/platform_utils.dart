import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Universal platform detection utility
/// Provides consistent platform checks across the entire app
class PlatformUtils {
  // Private constructor to prevent instantiation
  PlatformUtils._();

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop => !kIsWeb && (isWindows || isMacOS || isLinux);

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Get the current platform name as a string
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
}

/// Feature availability checker
/// Determines which features are supported on the current platform
class FeatureAvailability {
  // Private constructor
  FeatureAvailability._();

  /// SMS parsing is only available on Android
  static bool get smsParsingSupported => PlatformUtils.isAndroid;

  /// Biometric authentication is available on mobile platforms
  static bool get biometricSupported => PlatformUtils.isMobile;

  /// Notifications are available on mobile and desktop
  static bool get notificationsSupported => !PlatformUtils.isWeb;

  /// Privacy features (shake detection, face detection) are mobile-only
  static bool get privacyFeaturesSupported => PlatformUtils.isMobile;

  /// Screenshot protection is available on mobile
  static bool get screenshotProtectionSupported => PlatformUtils.isMobile;

  /// Dynamic colors are available on Android 12+ and iOS
  static bool get dynamicColorsSupported => PlatformUtils.isMobile;

  /// Background tasks (workmanager) are available on mobile
  static bool get backgroundTasksSupported => PlatformUtils.isMobile;

  /// File system access
  static bool get fileSystemSupported => !PlatformUtils.isWeb;

  /// Camera access for face detection
  static bool get cameraSupported => PlatformUtils.isMobile;

  /// Accelerometer/gyroscope for shake detection
  static bool get sensorSupported => PlatformUtils.isMobile;

  /// Check if a specific feature is supported
  static bool isFeatureSupported(AppFeature feature) {
    switch (feature) {
      case AppFeature.smsParsing:
        return smsParsingSupported;
      case AppFeature.biometric:
        return biometricSupported;
      case AppFeature.notifications:
        return notificationsSupported;
      case AppFeature.privacyMode:
        return privacyFeaturesSupported;
      case AppFeature.screenshotProtection:
        return screenshotProtectionSupported;
      case AppFeature.dynamicColors:
        return dynamicColorsSupported;
      case AppFeature.backgroundTasks:
        return backgroundTasksSupported;
      case AppFeature.shakeDetection:
        return sensorSupported;
      case AppFeature.faceDetection:
        return cameraSupported;
    }
  }

  /// Get user-friendly message for unsupported features
  static String getUnsupportedMessage(AppFeature feature) {
    final platformName = PlatformUtils.platformName;

    switch (feature) {
      case AppFeature.smsParsing:
        return 'SMS parsing is only available on Android devices';
      case AppFeature.biometric:
        return 'Biometric authentication is only available on mobile devices';
      case AppFeature.notifications:
        return 'Notifications are not supported on $platformName';
      case AppFeature.privacyMode:
        return 'Privacy features are only available on mobile devices';
      case AppFeature.screenshotProtection:
        return 'Screenshot protection is only available on mobile devices';
      case AppFeature.dynamicColors:
        return 'Dynamic colors are only available on mobile devices';
      case AppFeature.backgroundTasks:
        return 'Background tasks are only available on mobile devices';
      case AppFeature.shakeDetection:
        return 'Shake detection requires device sensors (mobile only)';
      case AppFeature.faceDetection:
        return 'Face detection requires camera access (mobile only)';
    }
  }
}

/// Enum for app features
enum AppFeature {
  smsParsing,
  biometric,
  notifications,
  privacyMode,
  screenshotProtection,
  dynamicColors,
  backgroundTasks,
  shakeDetection,
  faceDetection,
}

/// Platform-specific configuration
class PlatformConfig {
  // Private constructor
  PlatformConfig._();

  /// Get the default currency based on platform/location
  static String get defaultCurrency {
    if (PlatformUtils.isWeb) return 'USD';
    // On mobile, you could use device locale to determine currency
    return 'INR'; // Default to INR for this app
  }

  /// Get the default language based on platform/location
  static String get defaultLanguage {
    if (PlatformUtils.isWeb) return 'English';
    // On mobile, you could use device locale to determine language
    return 'English';
  }

  /// Check if platform supports file downloads
  static bool get supportsFileDownloads => !PlatformUtils.isWeb;

  /// Check if platform supports share functionality
  static bool get supportsShare => PlatformUtils.isMobile;

  /// Check if platform supports system theme detection
  static bool get supportsSystemTheme => true; // All platforms support this

  /// Check if platform supports haptic feedback
  static bool get supportsHapticFeedback => PlatformUtils.isMobile;
}