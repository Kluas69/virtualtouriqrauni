import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../logging/app_logger.dart';
import '../platform/platform_utils.dart';

/// Adaptive performance monitoring that adjusts frequency based on device capability
class AdaptivePerformanceMonitor {
  static AdaptivePerformanceMonitor? _instance;
  static AdaptivePerformanceMonitor get instance => _instance ??= AdaptivePerformanceMonitor._();
  
  AdaptivePerformanceMonitor._();

  Timer? _monitorTimer;
  Duration _currentInterval = const Duration(seconds: 5);
  final Map<String, double> _metrics = {};
  int _consecutiveGoodFrames = 0;
  int _consecutiveBadFrames = 0;
  
  // Adaptive thresholds
  static const int _goodFrameThreshold = 10; // 10 consecutive good frames to reduce monitoring
  static const int _badFrameThreshold = 3;   // 3 consecutive bad frames to increase monitoring
  static const Duration _minInterval = Duration(seconds: 1);
  static const Duration _maxInterval = Duration(seconds: 30);
  
  void initialize() {
    _startAdaptiveMonitoring();
  }
  
  void _startAdaptiveMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(_currentInterval, (_) {
      _collectMetricsAndAdapt();
    });
  }
  
  void _collectMetricsAndAdapt() {
    // Collect current FPS
    final currentFPS = _getCurrentFPS();
    _metrics['fps'] = currentFPS;
    
    // Determine if performance is good or bad
    final isGoodPerformance = currentFPS >= 55.0; // Near 60 FPS
    
    if (isGoodPerformance) {
      _consecutiveGoodFrames++;
      _consecutiveBadFrames = 0;
      
      // If consistently good, reduce monitoring frequency
      if (_consecutiveGoodFrames >= _goodFrameThreshold) {
        _reduceMonitoringFrequency();
        _consecutiveGoodFrames = 0;
      }
    } else {
      _consecutiveBadFrames++;
      _consecutiveGoodFrames = 0;
      
      // If performance is bad, increase monitoring frequency
      if (_consecutiveBadFrames >= _badFrameThreshold) {
        _increaseMonitoringFrequency();
        _consecutiveBadFrames = 0;
      }
    }
  }
  
  void _reduceMonitoringFrequency() {
    final newInterval = Duration(
      milliseconds: (_currentInterval.inMilliseconds * 1.5).round()
    );
    
    if (newInterval <= _maxInterval) {
      _currentInterval = newInterval;
      _restartMonitoring();
      
      AppLogger.debug('Reduced monitoring frequency',
        component: 'AdaptivePerformanceMonitor',
        metadata: {'newInterval': '${_currentInterval.inSeconds}s'});
    }
  }
  
  void _increaseMonitoringFrequency() {
    final newInterval = Duration(
      milliseconds: (_currentInterval.inMilliseconds * 0.7).round()
    );
    
    if (newInterval >= _minInterval) {
      _currentInterval = newInterval;
      _restartMonitoring();
      
      AppLogger.debug('Increased monitoring frequency',
        component: 'AdaptivePerformanceMonitor',
        metadata: {'newInterval': '${_currentInterval.inSeconds}s'});
    }
  }
  
  void _restartMonitoring() {
    _monitorTimer?.cancel();
    _startAdaptiveMonitoring();
  }
  
  double _getCurrentFPS() {
    // Simplified FPS calculation
    // In production, you'd use SchedulerBinding.instance.currentFrameTimeStamp
    return 60.0; // Placeholder - implement actual FPS calculation
  }
  
  Map<String, double> getMetrics() => Map.from(_metrics);
  
  void dispose() {
    _monitorTimer?.cancel();
    _metrics.clear();
  }
}