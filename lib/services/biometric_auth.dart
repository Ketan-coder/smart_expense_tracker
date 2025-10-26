import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricAuthResult {
  success,
  failure,
  cancelled,
  notAvailable,
  notEnrolled,
  error,
}

class BiometricAuthResponse {
  final BiometricAuthResult result;
  final String? message;

  BiometricAuthResponse(this.result, [this.message]);

  bool get isSuccess => result == BiometricAuthResult.success;
  bool get isCancelled => result == BiometricAuthResult.cancelled;
  bool get isFailure => result == BiometricAuthResult.failure;
}

class BiometricAuth {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if device supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      debugPrint("🔐 Can check biometrics: $canCheck");
      debugPrint("🔐 Device supported: $isDeviceSupported");
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint("❌ Error checking biometrics: $e");
      return false;
    }
  }

  /// Checks if any biometric is enrolled (e.g. fingerprint added)
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> biometrics = await _auth.getAvailableBiometrics();
      debugPrint("🔐 Available biometrics: $biometrics");
      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint("❌ Error getting enrolled biometrics: $e");
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint("❌ Error getting biometric types: $e");
      return [];
    }
  }

  /// Tries to authenticate the user using biometrics
  /// Returns BiometricAuthResponse with detailed result
  Future<BiometricAuthResponse> biometricAuthenticate({
    String reason = 'Authenticate to access',
    bool biometricOnly = false,
  }) async {
    debugPrint("🔐 ========================================");
    debugPrint("🔐 Starting biometric authentication...");
    debugPrint("🔐 Reason: $reason");
    debugPrint("🔐 Biometric only: $biometricOnly");

    try {
      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint("❌ Biometric not available on device");
        return BiometricAuthResponse(
          BiometricAuthResult.notAvailable,
          "Biometric authentication is not available on this device",
        );
      }

      // Check if biometric is enrolled
      final hasEnrolled = await hasEnrolledBiometrics();
      if (!hasEnrolled) {
        debugPrint("❌ No biometrics enrolled");
        return BiometricAuthResponse(
          BiometricAuthResult.notEnrolled,
          "No biometrics enrolled. Please add fingerprint or face ID in device settings",
        );
      }

      debugPrint("🔐 Attempting authentication...");
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true, // Keep auth dialog if app goes to background
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (authenticated) {
        debugPrint(" Authentication successful");
        return BiometricAuthResponse(
          BiometricAuthResult.success,
          "Authentication successful",
        );
      } else {
        debugPrint("❌ Authentication failed");
        return BiometricAuthResponse(
          BiometricAuthResult.failure,
          "Authentication failed",
        );
      }
    } on PlatformException catch (e) {
      debugPrint("❌ PlatformException: ${e.code} - ${e.message}");

      // Handle different cancellation codes
      final cancelCodes = [
        'NotAvailable',
        'NotEnrolled',
        'LockedOut',
        'PermanentlyLockedOut',
        'UserCancel',
        'user_cancelled',
        'UserCanceled',
        'userCanceled',
        'AuthenticationCanceled',
        'authentication_canceled',
        'onDialogDismissed',
        'SystemCancel',
        'system_cancel',
      ];

      final errorCode = e.code.toLowerCase();

      if (cancelCodes.any((code) => errorCode.contains(code.toLowerCase()))) {
        debugPrint("⚠️ User cancelled authentication");
        return BiometricAuthResponse(
          BiometricAuthResult.cancelled,
          "Authentication cancelled",
        );
      }

      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
        case 'PasscodeNotSet':
          return BiometricAuthResponse(
            BiometricAuthResult.notAvailable,
            "Biometric authentication not available. ${e.message ?? ''}",
          );

        case 'NotEnrolled':
          return BiometricAuthResponse(
            BiometricAuthResult.notEnrolled,
            "No biometrics enrolled. Please set up fingerprint or face ID.",
          );

        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return BiometricAuthResponse(
            BiometricAuthResult.error,
            "Too many attempts. Please try again later.",
          );

        case 'no_fragment_activity':
          debugPrint("❌ CRITICAL: MainActivity must extend FlutterFragmentActivity!");
          debugPrint("❌ Change: class MainActivity : FlutterActivity() → FlutterFragmentActivity()");
          return BiometricAuthResponse(
            BiometricAuthResult.error,
            "App configuration error. Please contact developer.",
          );

        default:
          return BiometricAuthResponse(
            BiometricAuthResult.error,
            "Authentication error: ${e.message ?? 'Unknown error'}",
          );
      }
    } catch (e) {
      debugPrint("❌ Unexpected error: $e");
      return BiometricAuthResponse(
        BiometricAuthResult.error,
        "Unexpected error during authentication",
      );
    } finally {
      debugPrint("🔐 ========================================");
    }
  }

  /// Quick authenticate - returns true/false only (for backward compatibility)
  Future<bool> authenticateQuick({String reason = 'Authenticate to access'}) async {
    final response = await biometricAuthenticate(reason: reason);
    return response.isSuccess;
  }

  /// Get biometric type string for display
  Future<String> getBiometricTypeString() async {
    try {
      final biometrics = await getAvailableBiometrics();

      if (biometrics.isEmpty) {
        return "None";
      }

      if (biometrics.contains(BiometricType.face)) {
        return "Face ID";
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return "Fingerprint";
      } else if (biometrics.contains(BiometricType.iris)) {
        return "Iris";
      } else if (biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak)) {
        return "Biometric";
      }

      return "Biometric";
    } catch (e) {
      debugPrint("Error getting biometric type: $e");
      return "Unknown";
    }
  }
}