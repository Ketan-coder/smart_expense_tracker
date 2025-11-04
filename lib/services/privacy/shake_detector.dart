import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects device shake and face-down orientation for privacy activation
/// OPTIMIZED: Reduced sampling rate, debouncing, and smart activation
class ShakeDetector {
  // Shake detection parameters
  static const double _shakeThreshold = 3.0; // Increased to reduce false positives
  static const int _shakeCooldownMs = 2000; // Increased cooldown to 2 seconds
  static const int _samplingRateMs = 200; // Sample every 200ms instead of continuous

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  DateTime? _lastSampleTime;
  bool _isListening = false;

  // Callbacks
  Function()? onShakeDetected;
  Function()? onFaceDownDetected;

  // Face-down debouncing
  bool _wasFaceDown = false;
  DateTime? _faceDownStartTime;
  static const int _faceDownThresholdMs = 500; // Must be face-down for 500ms

  /// Start listening for shake and orientation changes
  void startListening({
    Function()? onShake,
    Function()? onFaceDown,
  }) {
    if (_isListening) return;

    onShakeDetected = onShake;
    onFaceDownDetected = onFaceDown;

    // Use sampling to reduce battery drain
    _accelerometerSubscription = accelerometerEventStream().listen(
      _handleAccelerometerEvent,
      onError: (error) {
        debugPrint("❌ Accelerometer error: $error");
      },
      cancelOnError: false,
    );

    _isListening = true;
    debugPrint("📳 Shake detector started (optimized mode)");
  }

  /// Stop listening (battery optimization)
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isListening = false;
    _lastShakeTime = null;
    _lastSampleTime = null;
    _wasFaceDown = false;
    _faceDownStartTime = null;
    debugPrint("📳 Shake detector stopped");
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final now = DateTime.now();

    // Throttle sampling to reduce battery usage
    if (_lastSampleTime != null &&
        now.difference(_lastSampleTime!).inMilliseconds < _samplingRateMs) {
      return;
    }
    _lastSampleTime = now;

    // Calculate g-force magnitude
    final double gX = event.x / 9.81;
    final double gY = event.y / 9.81;
    final double gZ = event.z / 9.81;

    final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    // Detect shake (only if cooldown has passed)
    if (gForce > _shakeThreshold) {
      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds > _shakeCooldownMs) {
        _lastShakeTime = now;
        debugPrint("📳 SHAKE DETECTED! (gForce: ${gForce.toStringAsFixed(2)})");
        onShakeDetected?.call();
      }
    }

    // Detect face-down orientation with debouncing
    // When phone is flat and facing down, Z-axis is negative and strong
    final isFaceDown = gZ < -0.85 && gX.abs() < 0.4 && gY.abs() < 0.4;

    if (isFaceDown && !_wasFaceDown) {
      // Just went face-down
      _faceDownStartTime = now;
      _wasFaceDown = true;
    } else if (isFaceDown && _wasFaceDown && _faceDownStartTime != null) {
      // Still face-down, check if threshold met
      if (now.difference(_faceDownStartTime!).inMilliseconds > _faceDownThresholdMs) {
        debugPrint("📱 Face-down confirmed (held for ${_faceDownThresholdMs}ms)");
        onFaceDownDetected?.call();
        _faceDownStartTime = null; // Prevent multiple triggers
      }
    } else if (!isFaceDown && _wasFaceDown) {
      // No longer face-down
      _wasFaceDown = false;
      _faceDownStartTime = null;
    }
  }

  bool get isListening => _isListening;

  void dispose() {
    stopListening();
  }
}