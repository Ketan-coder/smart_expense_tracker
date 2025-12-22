// ============================================================================
// FILE: lib/services/biometric_auth_stub.dart
// Web stub for biometric authentication
// ============================================================================
import 'package:flutter/material.dart';

class BiometricAuth {
  Future<bool> isBiometricAvailable() async {
    return false;
  }

  Future<bool> hasEnrolledBiometrics() async {
    return false;
  }

  Future<String> getBiometricTypeString() async {
    return 'Not Available';
  }

  Future<BiometricAuthResponse> biometricAuthenticate({
    required String reason,
  }) async {
    return BiometricAuthResponse(
      result: AuthResult.notAvailable,
      message: 'Biometric authentication not available on web',
    );
  }
}

class BiometricAuthResponse {
  final AuthResult result;
  final String? message;

  BiometricAuthResponse({
    required this.result,
    this.message,
  });

  bool get isSuccess => result == AuthResult.success;
  bool get isCancelled => result == AuthResult.cancelled;
}

enum AuthResult {
  success,
  cancelled,
  failed,
  notAvailable,
}