import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects device shake and face-down orientation for privacy activation
/// Battery-efficient: only active when app is in foreground
class ShakeDetector {
  // Shake detection parameters
  static const double _shakeThreshold = 2.7; // g-force threshold
  static const int _shakeCooldownMs = 1000; // Prevent rapid triggers

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  bool _isListening = false;

  // Callbacks
  Function()? onShakeDetected;
  Function()? onFaceDownDetected;

  /// Start listening for shake and orientation changes
  void startListening({
    Function()? onShake,
    Function()? onFaceDown,
  }) {
    if (_isListening) return;

    onShakeDetected = onShake;
    onFaceDownDetected = onFaceDown;

    _accelerometerSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
      onError: (error) {
        debugPrint("❌ Accelerometer error: $error");
      },
    );

    _isListening = true;
    debugPrint("📳 Shake detector started");
  }

  /// Stop listening (battery optimization)
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isListening = false;
    debugPrint("📳 Shake detector stopped");
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Calculate g-force magnitude
    final double gX = event.x / 9.81;
    final double gY = event.y / 9.81;
    final double gZ = event.z / 9.81;

    final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    // Detect shake
    if (gForce > _shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds > _shakeCooldownMs) {
        _lastShakeTime = now;
        debugPrint("📳 SHAKE DETECTED! (gForce: ${gForce.toStringAsFixed(2)})");
        onShakeDetected?.call();
      }
    }

    // Detect face-down orientation
    // When phone is flat and facing down, Z-axis is negative and strong
    if (gZ < -0.9 && gX.abs() < 0.3 && gY.abs() < 0.3) {
      debugPrint("📱 Face-down detected");
      onFaceDownDetected?.call();
    }
  }

  bool get isListening => _isListening;

  void dispose() {
    stopListening();
  }
}