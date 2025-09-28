import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if device supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint("Error checking biometrics: $e");
      return false;
    }
  }

  /// Tries to authenticate the user using biometrics
  /// Returns:
  /// - `true` if authenticated
  /// - `false` if failed
  /// Throws Exception if user cancels the prompt
  Future<bool> biometricAuthenticate({
    String reason = 'Authenticate to access',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code.toLowerCase().contains("cancel")) {
        // User cancelled biometric prompt
        debugPrint("In Exception");
        debugPrint(e.code);
        throw Exception("CANCELLED_BY_USER");
      } else if (e.code == 'UserCanceled' ||
          e.code == 'user_cancelled' ||
          e.code == 'userCanceled' ||
          e.code == 'onDialogDismissed') {
        // All possible cancel codes
        debugPrint(e.code);
        throw Exception("Biometric authentication was cancelled by the user.");
      } else {
        debugPrint("Biometric PlatformException: $e");
        return false;
      }
    } catch (e) {
      debugPrint("Biometric authentication error: $e");
      return false;
    }
  }

  /// Checks if any biometric is enrolled (e.g. fingerdebugPrint added)
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> biometrics =
      await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint("Error getting enrolled biometrics: $e");
      return false;
    }
  }
}