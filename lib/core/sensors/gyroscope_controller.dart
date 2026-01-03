import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Controller for managing gyroscope input for camera control
class GyroscopeController {
  static final GyroscopeController _instance = GyroscopeController._internal();
  factory GyroscopeController() => _instance;
  GyroscopeController._internal();

  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamController<GyroscopeData>? _dataController;
  
  bool _isEnabled = false;
  bool _isSupported = true;
  bool _isCalibrated = false;
  
  double _sensitivity = 1.0;
  double _deadZone = 0.1;
  
  // Calibration values
  double _calibrationX = 0.0;
  double _calibrationY = 0.0;
  double _calibrationZ = 0.0;
  
  // Smoothing filter
  final List<GyroscopeData> _dataBuffer = [];
  static const int _bufferSize = 5;
  
  // Getters
  bool get isEnabled => _isEnabled && _isSupported && !kIsWeb;
  bool get isSupported => _isSupported && !kIsWeb;
  bool get isCalibrated => _isCalibrated;
  double get sensitivity => _sensitivity;
  double get deadZone => _deadZone;
  
  Stream<GyroscopeData> get gyroscopeStream {
    _dataController ??= StreamController<GyroscopeData>.broadcast();
    return _dataController!.stream;
  }

  /// Initialize gyroscope controller
  Future<void> initialize() async {
    if (kIsWeb) {
      _isSupported = false;
      return;
    }

    try {
      // Test if gyroscope is available
      await gyroscopeEvents.first.timeout(const Duration(seconds: 2));
      _isSupported = true;
    } catch (e) {
      _isSupported = false;
      debugPrint('Gyroscope not supported: $e');
    }
  }

  /// Enable gyroscope input
  Future<void> enable() async {
    if (!isSupported || _isEnabled) return;

    try {
      _dataController ??= StreamController<GyroscopeData>.broadcast();
      
      _gyroscopeSubscription = gyroscopeEvents.listen(
        _onGyroscopeEvent,
        onError: (error) {
          debugPrint('Gyroscope error: $error');
          _isSupported = false;
          disable();
        },
      );
      
      _isEnabled = true;
      debugPrint('Gyroscope enabled');
    } catch (e) {
      debugPrint('Failed to enable gyroscope: $e');
      _isSupported = false;
    }
  }

  /// Disable gyroscope input
  void disable() {
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    _isEnabled = false;
    _dataBuffer.clear();
    debugPrint('Gyroscope disabled');
  }

  /// Calibrate gyroscope to current position
  Future<void> calibrate() async {
    if (!isEnabled) return;

    debugPrint('Starting gyroscope calibration...');
    
    final calibrationData = <GyroscopeEvent>[];
    const calibrationDuration = Duration(seconds: 2);
    const sampleCount = 20;
    
    final completer = Completer<void>();
    late StreamSubscription<GyroscopeEvent> calibrationSubscription;
    
    calibrationSubscription = gyroscopeEvents.listen((event) {
      calibrationData.add(event);
      
      if (calibrationData.length >= sampleCount) {
        calibrationSubscription.cancel();
        completer.complete();
      }
    });
    
    // Wait for calibration data or timeout
    try {
      await completer.future.timeout(calibrationDuration);
      
      // Calculate average values for calibration
      double sumX = 0, sumY = 0, sumZ = 0;
      for (final event in calibrationData) {
        sumX += event.x;
        sumY += event.y;
        sumZ += event.z;
      }
      
      _calibrationX = sumX / calibrationData.length;
      _calibrationY = sumY / calibrationData.length;
      _calibrationZ = sumZ / calibrationData.length;
      
      _isCalibrated = true;
      debugPrint('Gyroscope calibrated: X=${_calibrationX.toStringAsFixed(3)}, '
                 'Y=${_calibrationY.toStringAsFixed(3)}, Z=${_calibrationZ.toStringAsFixed(3)}');
    } catch (e) {
      debugPrint('Gyroscope calibration failed: $e');
      calibrationSubscription.cancel();
    }
  }

  /// Set sensitivity (0.1 to 3.0)
  void setSensitivity(double sensitivity) {
    _sensitivity = sensitivity.clamp(0.1, 3.0);
  }

  /// Set dead zone (0.0 to 1.0)
  void setDeadZone(double deadZone) {
    _deadZone = deadZone.clamp(0.0, 1.0);
  }

  /// Reset calibration
  void resetCalibration() {
    _calibrationX = 0.0;
    _calibrationY = 0.0;
    _calibrationZ = 0.0;
    _isCalibrated = false;
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!_isEnabled || _dataController == null) return;

    // Apply calibration offset
    final calibratedX = event.x - _calibrationX;
    final calibratedY = event.y - _calibrationY;
    final calibratedZ = event.z - _calibrationZ;

    // Apply sensitivity
    final sensitiveX = calibratedX * _sensitivity;
    final sensitiveY = calibratedY * _sensitivity;
    final sensitiveZ = calibratedZ * _sensitivity;

    // Apply dead zone
    final filteredX = _applyDeadZone(sensitiveX);
    final filteredY = _applyDeadZone(sensitiveY);
    final filteredZ = _applyDeadZone(sensitiveZ);

    final gyroData = GyroscopeData(
      x: filteredX,
      y: filteredY,
      z: filteredZ,
      timestamp: DateTime.now(),
    );

    // Add to smoothing buffer
    _dataBuffer.add(gyroData);
    if (_dataBuffer.length > _bufferSize) {
      _dataBuffer.removeAt(0);
    }

    // Calculate smoothed values
    final smoothedData = _calculateSmoothedData();
    
    // Emit smoothed data
    _dataController!.add(smoothedData);
  }

  double _applyDeadZone(double value) {
    final absValue = value.abs();
    if (absValue < _deadZone) {
      return 0.0;
    }
    
    // Scale the value to maintain smooth transition
    final scaledValue = (absValue - _deadZone) / (1.0 - _deadZone);
    return value.isNegative ? -scaledValue : scaledValue;
  }

  GyroscopeData _calculateSmoothedData() {
    if (_dataBuffer.isEmpty) {
      return GyroscopeData(x: 0, y: 0, z: 0, timestamp: DateTime.now());
    }

    double sumX = 0, sumY = 0, sumZ = 0;
    for (final data in _dataBuffer) {
      sumX += data.x;
      sumY += data.y;
      sumZ += data.z;
    }

    return GyroscopeData(
      x: sumX / _dataBuffer.length,
      y: sumY / _dataBuffer.length,
      z: sumZ / _dataBuffer.length,
      timestamp: DateTime.now(),
    );
  }

  /// Dispose resources
  void dispose() {
    disable();
    _dataController?.close();
    _dataController = null;
  }
}

/// Gyroscope data with timestamp
class GyroscopeData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const GyroscopeData({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  /// Convert to camera rotation values
  /// Returns Offset where x = yaw (horizontal), y = pitch (vertical)
  Offset toCameraRotation() {
    // Convert gyroscope data to camera rotation
    // X-axis rotation (pitch) - up/down camera movement
    // Y-axis rotation (yaw) - left/right camera movement
    
    return Offset(
      -y, // Yaw (horizontal rotation)
      -x, // Pitch (vertical rotation)
    );
  }

  @override
  String toString() {
    return 'GyroscopeData(x: ${x.toStringAsFixed(3)}, '
           'y: ${y.toStringAsFixed(3)}, z: ${z.toStringAsFixed(3)})';
  }
}