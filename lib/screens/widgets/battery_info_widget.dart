import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Debug widget to monitor battery optimization status
/// Shows which privacy features are currently active
/// ONLY visible in debug mode
class BatteryMonitorWidget extends StatelessWidget {
  final bool shakeDetectorActive;
  final bool faceDetectionActive;
  final bool privacyModeActive;
  final bool adaptiveBrightnessActive;

  const BatteryMonitorWidget({
    super.key,
    required this.shakeDetectorActive,
    required this.faceDetectionActive,
    required this.privacyModeActive,
    required this.adaptiveBrightnessActive,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      top: 80,
      left: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_charging_full,
                    size: 16,
                    color: _calculateImpactColor(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Battery Impact: ${_calculateBatteryImpact()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusRow('Privacy Mode', privacyModeActive, Colors.blue),
              _buildStatusRow('Shake Detection', shakeDetectorActive, Colors.orange),
              _buildStatusRow('Face Detection', faceDetectionActive, Colors.red),
              _buildStatusRow('Adaptive Brightness', adaptiveBrightnessActive, Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool active, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? color : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateBatteryImpact() {
    double impact = 0.0;

    if (privacyModeActive) impact += 0.1; // Pure UI
    if (shakeDetectorActive) impact += 0.5; // Optimized sensor
    if (adaptiveBrightnessActive) impact += 0.2; // One-time change
    if (faceDetectionActive) impact += 5.0; // Camera heavy

    if (impact < 1) return 'Minimal (<1%)';
    if (impact < 2) return 'Low (${impact.toStringAsFixed(1)}%)';
    if (impact < 5) return 'Medium (${impact.toStringAsFixed(1)}%)';
    return 'High (${impact.toStringAsFixed(1)}%)';
  }

  Color _calculateImpactColor() {
    double impact = 0.0;

    if (privacyModeActive) impact += 0.1;
    if (shakeDetectorActive) impact += 0.5;
    if (adaptiveBrightnessActive) impact += 0.2;
    if (faceDetectionActive) impact += 5.0;

    if (impact < 1) return Colors.green;
    if (impact < 2) return Colors.lightGreen;
    if (impact < 5) return Colors.orange;
    return Colors.red;
  }
}

/// HOW TO USE:
///
/// Add this to your bottom_nav_bar.dart Stack (only in debug):
///
/// if (kDebugMode)
///   BatteryMonitorWidget(
///     shakeDetectorActive: _shakeDetector?.isListening ?? false,
///     faceDetectionActive: false, // or your face detection state
///     privacyModeActive: _privacyManager.isPrivacyActive,
///     adaptiveBrightnessActive: _privacyManager.adaptiveBrightnessEnabled,
///   ),