import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';

/// Advanced Debug widget to monitor REAL battery optimization status
/// Shows actual battery usage with real-time monitoring
/// ONLY visible in debug mode
class BatteryMonitorWidget extends StatefulWidget {
  final bool shakeDetectorActive;
  final bool faceDetectionActive;
  final bool privacyModeActive;
  final bool adaptiveBrightnessActive;
  final double screenBrightness;

  const BatteryMonitorWidget({
    super.key,
    required this.shakeDetectorActive,
    required this.faceDetectionActive,
    required this.privacyModeActive,
    required this.adaptiveBrightnessActive,
    this.screenBrightness = 0.7,
  });

  @override
  State<BatteryMonitorWidget> createState() => _BatteryMonitorWidgetState();
}

class _BatteryMonitorWidgetState extends State<BatteryMonitorWidget> {
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  int _initialBatteryLevel = 100;
  int _currentBatteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  DateTime _startTime = DateTime.now();
  bool _isMonitoring = false;
  final List<BatterySnapshot> _batterySnapshots = [];
  Timer? _monitoringTimer;
  Timer? _batteryCheckTimer;
  String _deviceModel = 'Unknown';
  double _batteryCapacity = 3000; // Default mAh
  double _totalBatteryDrain = 0.0;
  int _lastBatteryLevel = 100;

  // Feature-specific tracking
  final Map<String, double> _featurePowerUsage = {
    'privacyMode': 0.0,
    'shakeDetector': 0.0,
    'faceDetection': 0.0,
    'adaptiveBrightness': 0.0,
    'screen': 0.0,
  };

  // Track when features were last active
  final Map<String, DateTime> _featureLastActive = {};
  Map<String, bool> _previousFeatureState = {};

  @override
  void initState() {
    super.initState();
    _initializeBatteryMonitoring();
    _initializeFeatureTracking();
  }

  void _initializeFeatureTracking() {
    _previousFeatureState = {
      'privacyMode': widget.privacyModeActive,
      'shakeDetector': widget.shakeDetectorActive,
      'faceDetection': widget.faceDetectionActive,
      'adaptiveBrightness': widget.adaptiveBrightnessActive,
    };
  }

  @override
  void didUpdateWidget(covariant BatteryMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect feature state changes
    if (oldWidget.privacyModeActive != widget.privacyModeActive ||
        oldWidget.shakeDetectorActive != widget.shakeDetectorActive ||
        oldWidget.faceDetectionActive != widget.faceDetectionActive ||
        oldWidget.adaptiveBrightnessActive != widget.adaptiveBrightnessActive ||
        oldWidget.screenBrightness != widget.screenBrightness) {
      _updateFeaturePowerUsage();
      _takeBatterySnapshot();
    }
  }

  Future<void> _initializeBatteryMonitoring() async {
    await _getDeviceInfo();
    await _startBatteryMonitoring();
  }

  Future<void> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceModel = androidInfo.model;
        _batteryCapacity = _estimateBatteryCapacity(androidInfo.model);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceModel = iosInfo.model;
        _batteryCapacity = _estimateBatteryCapacity(iosInfo.model);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Device info error: $e');
      }
    }
  }

  double _estimateBatteryCapacity(String model) {
    final modelLower = model.toLowerCase();
    if (modelLower.contains('pro max') || modelLower.contains('ultra')) {
      return 4500; // Flagship large phones
    } else if (modelLower.contains('pro') || modelLower.contains('plus')) {
      return 3500; // Mid-large phones
    } else {
      return 3000; // Standard phones
    }
  }

  Future<void> _startBatteryMonitoring() async {
    try {
      _initialBatteryLevel = await _battery.batteryLevel;
      _currentBatteryLevel = _initialBatteryLevel;
      _lastBatteryLevel = _initialBatteryLevel;
      _batteryState = await _battery.batteryState;
      _startTime = DateTime.now();
      _isMonitoring = true;

      // Check battery every second for more accurate tracking
      _batteryCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!_isMonitoring) return;

        try {
          final newLevel = await _battery.batteryLevel;
          final newState = await _battery.batteryState;

          // Calculate actual drain since last check
          if (newLevel < _lastBatteryLevel && newState == BatteryState.discharging) {
            final drainAmount = (_lastBatteryLevel - newLevel).toDouble();
            _totalBatteryDrain += drainAmount;

            // Attribute drain to active features
            _attributeDrainToFeatures(drainAmount);
          }

          if (newLevel != _currentBatteryLevel || newState != _batteryState) {
            _currentBatteryLevel = newLevel;
            _batteryState = newState;
            _lastBatteryLevel = newLevel;

            if (mounted) {
              setState(() {});
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Battery check error: $e');
          }
        }
      });

      // Update feature power usage every 500ms for real-time updates
      _monitoringTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_isMonitoring) {
          _updateFeaturePowerUsage();

          // Take snapshot every 10 ticks (5 seconds)
          if (timer.tick % 10 == 0) {
            _takeBatterySnapshot();
          }
        }
      });

      // Initial snapshot
      _takeBatterySnapshot();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Battery monitoring error: $e');
      }
    }
  }

  void _attributeDrainToFeatures(double drainAmount) {
    // Calculate total current draw from all features
    final powerConsumption = _getCurrentPowerConsumption();
    final totalPower = powerConsumption.values.fold(0.0, (sum, val) => sum + val);

    if (totalPower == 0) return;

    // Distribute drain proportionally to power consumption
    powerConsumption.forEach((feature, power) {
      final proportion = power / totalPower;
      _featurePowerUsage[feature] = (_featurePowerUsage[feature] ?? 0.0) + (drainAmount * proportion);
    });
  }

  Map<String, double> _getCurrentPowerConsumption() {
    // Power consumption in milliamps (mA) - more realistic values
    const powerProfiles = {
      'privacyMode': 1.5,        // Minimal CPU overhead
      'shakeDetector': 6.0,      // Accelerometer polling
      'faceDetection': 180.0,    // Camera + ML processing (major consumer)
      'adaptiveBrightness': 2.5, // Light sensor
      'screen': 150.0,           // Base screen power (varies with brightness)
    };

    Map<String, double> currentPower = {};

    // Screen power scales with brightness (50-200mA range)
    currentPower['screen'] = 50 + (widget.screenBrightness * 150);

    // Feature-specific consumption (only if active)
    if (widget.privacyModeActive) {
      currentPower['privacyMode'] = powerProfiles['privacyMode']!;
    }
    if (widget.shakeDetectorActive) {
      currentPower['shakeDetector'] = powerProfiles['shakeDetector']!;
    }
    if (widget.faceDetectionActive) {
      currentPower['faceDetection'] = powerProfiles['faceDetection']!;
    }
    if (widget.adaptiveBrightnessActive) {
      currentPower['adaptiveBrightness'] = powerProfiles['adaptiveBrightness']!;
    }

    return currentPower;
  }

  void _updateFeaturePowerUsage() {
    if (!mounted) return;
    setState(() {});
  }

  void _takeBatterySnapshot() {
    final snapshot = BatterySnapshot(
      timestamp: DateTime.now(),
      batteryLevel: _currentBatteryLevel,
      features: {
        'privacyMode': widget.privacyModeActive,
        'shakeDetector': widget.shakeDetectorActive,
        'faceDetection': widget.faceDetectionActive,
        'adaptiveBrightness': widget.adaptiveBrightnessActive,
      },
      screenBrightness: widget.screenBrightness,
      powerUsage: Map.from(_featurePowerUsage),
    );

    _batterySnapshots.add(snapshot);

    // Keep only last 120 snapshots (10 minutes of data)
    if (_batterySnapshots.length > 120) {
      _batterySnapshots.removeAt(0);
    }
  }

  double _calculateRealBatteryDrainPerHour() {
    if (_batteryState != BatteryState.discharging) return 0.0;

    final duration = DateTime.now().difference(_startTime);
    final hours = duration.inSeconds / 3600.0;

    if (hours > 0 && _totalBatteryDrain > 0) {
      return (_totalBatteryDrain / hours).clamp(0.0, 100.0);
    }

    return 0.0;
  }

  double _calculateEstimatedDrainPerHour() {
    final powerConsumption = _getCurrentPowerConsumption();
    final totalCurrentDraw = powerConsumption.values.fold(0.0, (sum, val) => sum + val);

    // Convert mA to percentage per hour
    // Formula: (current_mA / battery_capacity_mAh) * 100% * 1 hour
    final percentagePerHour = (totalCurrentDraw / _batteryCapacity) * 100;
    return percentagePerHour.clamp(0.0, 100.0);
  }

  String _getHighestBatteryConsumer() {
    final powerConsumption = _getCurrentPowerConsumption();
    if (powerConsumption.isEmpty) return 'None';

    final sorted = powerConsumption.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) return 'None';

    final highest = sorted.first;
    return _formatFeatureName(highest.key);
  }

  String _formatFeatureName(String key) {
    switch (key) {
      case 'privacyMode':
        return 'Privacy Mode';
      case 'shakeDetector':
        return 'Shake Detector';
      case 'faceDetection':
        return 'Face Detection';
      case 'adaptiveBrightness':
        return 'Adaptive Brightness';
      case 'screen':
        return 'Screen';
      default:
        return key;
    }
  }

  String _getBatteryHealthStatus() {
    final duration = DateTime.now().difference(_startTime);
    if (duration.inSeconds < 30) return 'Calibrating...';

    if (_batteryState != BatteryState.discharging) {
      return 'Charging';
    }

    final realDrain = _calculateRealBatteryDrainPerHour();
    if (realDrain == 0) return 'Minimal Drain';

    final estimatedDrain = _calculateEstimatedDrainPerHour();
    final difference = (estimatedDrain - realDrain).abs();

    if (difference < 0.5) return 'Accurate';
    if (difference < 1.5) return 'Close';
    return 'Estimate';
  }

  String _getBatteryStateText() {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.unknown:
      default:
        return 'Unknown';
    }
  }

  Color _getBatteryStateColor() {
    switch (_batteryState) {
      case BatteryState.charging:
        return Colors.green;
      case BatteryState.discharging:
        return Colors.orange;
      case BatteryState.full:
        return Colors.blue;
      case BatteryState.unknown:
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    _batteryCheckTimer?.cancel();
    _isMonitoring = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final realDrain = _calculateRealBatteryDrainPerHour();
    final estimatedDrain = _calculateEstimatedDrainPerHour();
    final activeDrain = _batteryState == BatteryState.discharging && realDrain > 0
        ? realDrain
        : estimatedDrain;
    final duration = DateTime.now().difference(_startTime);
    final highestConsumer = _getHighestBatteryConsumer();

    return Positioned(
      top: 80,
      left: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha:0.9),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with battery icon and status
              Row(
                children: [
                  Icon(
                    _batteryState == BatteryState.charging
                        ? Icons.battery_charging_full
                        : Icons.battery_std,
                    size: 20,
                    color: _calculateImpactColor(activeDrain),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Battery Monitor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '$_currentBatteryLevel% • ',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getBatteryStateColor().withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _getBatteryStateColor()),
                              ),
                              child: Text(
                                _getBatteryStateText(),
                                style: TextStyle(
                                  color: _getBatteryStateColor(),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildBatteryHealthIndicator(),
                ],
              ),

              const SizedBox(height: 12),

              // Highest consumer alert
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha:0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Highest Consumer: $highestConsumer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Drain indicators
              if (_batteryState == BatteryState.discharging && realDrain > 0)
                _buildDrainIndicator('Real Drain', realDrain, true),
              _buildDrainIndicator(
                _batteryState == BatteryState.discharging && realDrain > 0
                    ? 'Estimated Drain'
                    : 'Current Drain Rate',
                estimatedDrain,
                false,
              ),

              if (_batteryState != BatteryState.discharging)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Device charging - showing power estimates',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Feature status with real-time power draw
              _buildFeatureStatus(),

              const SizedBox(height: 8),

              // Statistics
              _buildStatistics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryHealthIndicator() {
    final healthStatus = _getBatteryHealthStatus();
    Color healthColor;

    switch (healthStatus) {
      case 'Accurate':
        healthColor = Colors.green;
      case 'Close':
        healthColor = Colors.orange;
      case 'Minimal Drain':
        healthColor = Colors.blue;
      case 'Calibrating...':
        healthColor = Colors.grey;
      case 'Charging':
        healthColor = Colors.green;
      default:
        healthColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: healthColor),
      ),
      child: Text(
        healthStatus,
        style: TextStyle(
          color: healthColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrainIndicator(String label, double drain, bool isReal) {
    final showDrain = drain > 0.01;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isReal ? Icons.analytics : Icons.engineering,
            size: 14,
            color: isReal ? Colors.blue : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            showDrain ? '${drain.toStringAsFixed(2)}%/h' : '<0.01%/h',
            style: TextStyle(
              color: isReal ? Colors.blue : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureStatus() {
    final powerConsumption = _getCurrentPowerConsumption();
    final totalPower = powerConsumption.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Features (Real-time):',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatusRow(
          'Screen',
          true,
          _calculateImpactColor(powerConsumption['screen'] ?? 0),
          powerConsumption['screen'] ?? 0,
          totalPower,
        ),
        _buildStatusRow(
          'Face Detection',
          widget.faceDetectionActive,
          Colors.red,
          powerConsumption['faceDetection'] ?? 0,
          totalPower,
        ),
        _buildStatusRow(
          'Shake Detection',
          widget.shakeDetectorActive,
          Colors.orange,
          powerConsumption['shakeDetector'] ?? 0,
          totalPower,
        ),
        _buildStatusRow(
          'Adaptive Brightness',
          widget.adaptiveBrightnessActive,
          Colors.green,
          powerConsumption['adaptiveBrightness'] ?? 0,
          totalPower,
        ),
        _buildStatusRow(
          'Privacy Mode',
          widget.privacyModeActive,
          Colors.blue,
          powerConsumption['privacyMode'] ?? 0,
          totalPower,
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool active, Color color, double powerDraw, double totalPower) {
    final percentage = totalPower > 0 ? (powerDraw / totalPower * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? color : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '${powerDraw.toStringAsFixed(1)} mA',
                style: TextStyle(
                  color: active ? color : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  color: active ? Colors.white70 : Colors.grey,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          if (active && powerDraw > 0)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 2),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.withValues(alpha:0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final duration = DateTime.now().difference(_startTime);
    final snapshotsCount = _batterySnapshots.length;
    final totalPower = _getCurrentPowerConsumption().values.fold(0.0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('${duration.inMinutes}m', 'Monitoring'),
              _buildStatItem(snapshotsCount.toString(), 'Samples'),
              _buildStatItem('${_totalBatteryDrain.toStringAsFixed(1)}%', 'Total Drain'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Current Draw: ${totalPower.toStringAsFixed(1)} mA',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _calculateImpactColor(double powerDraw) {
    // Color based on actual power draw in mA
    if (powerDraw < 50) return Colors.green;
    if (powerDraw < 100) return Colors.lightGreen;
    if (powerDraw < 150) return Colors.orange;
    if (powerDraw < 200) return Colors.deepOrange;
    return Colors.red;
  }
}

class BatterySnapshot {
  final DateTime timestamp;
  final int batteryLevel;
  final Map<String, bool> features;
  final double screenBrightness;
  final Map<String, double> powerUsage;

  BatterySnapshot({
    required this.timestamp,
    required this.batteryLevel,
    required this.features,
    required this.screenBrightness,
    required this.powerUsage,
  });
}