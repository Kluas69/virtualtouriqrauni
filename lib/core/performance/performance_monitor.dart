import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../logging/app_logger.dart';
import '../animation/animation_config.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  Timer? _memoryTimer;
  Timer? _fpsTimer;
  int _frameCount = 0;
  DateTime _lastFpsCheck = DateTime.now();
  double _currentFps = 60.0;
  
  // Memory tracking
  int _lastMemoryUsage = 0;
  List<int> _memoryHistory = [];
  
  // Enhanced performance tracking for futuristic UI
  List<double> _fpsHistory = [];
  bool _isPerformanceOptimized = true;
  int _droppedFrames = 0;
  double _averageFps = 60.0;
  
  // Performance callbacks for UI components
  final List<Function(double)> _fpsCallbacks = [];
  final List<Function(PerformanceStatus)> _statusCallbacks = [];
  
  // Performance thresholds
  static const int _memoryWarningThreshold = 100 * 1024 * 1024; // 100MB
  static const int _memoryCriticalThreshold = 200 * 1024 * 1024; // 200MB
  static const double _fpsWarningThreshold = 45.0;
  static const double _fpsCriticalThreshold = 30.0;

  void startMonitoring() {
    if (kDebugMode) {
      AppLogger.info('Starting enhanced performance monitoring', component: 'PerformanceMonitor');
      
      _startMemoryMonitoring();
      _startFpsMonitoring();
    }
  }

  void stopMonitoring() {
    _memoryTimer?.cancel();
    _fpsTimer?.cancel();
    AppLogger.info('Stopped performance monitoring', component: 'PerformanceMonitor');
  }

  void _startMemoryMonitoring() {
    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkMemoryUsage();
    });
  }

  void _startFpsMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateFps();
    });
  }

  void _onFrame(Duration timestamp) {
    _frameCount++;
  }

  void _calculateFps() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsCheck).inMilliseconds;
    
    if (elapsed >= 1000) {
      _currentFps = (_frameCount * 1000.0) / elapsed;
      _frameCount = 0;
      _lastFpsCheck = now;
      
      // Track FPS history
      _fpsHistory.add(_currentFps);
      if (_fpsHistory.length > 60) { // Keep last 60 seconds
        _fpsHistory.removeAt(0);
      }
      
      // Calculate average FPS
      _averageFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      
      // Track dropped frames
      if (_currentFps < AnimationConfig.targetFPS * 0.9) {
        _droppedFrames++;
      }
      
      _checkFpsPerformance();
      _notifyFpsCallbacks();
    }
  }

  void _checkMemoryUsage() {
    // Note: Actual memory usage tracking would require platform-specific implementation
    // This is a simplified version for demonstration
    
    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile platforms, we'd use platform channels to get actual memory usage
      // For now, we'll simulate memory tracking
      _simulateMemoryCheck();
    }
  }

  void _simulateMemoryCheck() {
    // Simulate memory usage (in a real app, this would be actual memory readings)
    final currentMemory = _lastMemoryUsage + (DateTime.now().millisecondsSinceEpoch % 1000);
    _lastMemoryUsage = currentMemory;
    _memoryHistory.add(currentMemory);
    
    // Keep only last 20 readings
    if (_memoryHistory.length > 20) {
      _memoryHistory.removeAt(0);
    }
    
    if (currentMemory > _memoryCriticalThreshold) {
      AppLogger.warning('Critical memory usage detected', 
        component: 'PerformanceMonitor',
        metadata: {'memoryUsage': currentMemory});
    } else if (currentMemory > _memoryWarningThreshold) {
      AppLogger.info('High memory usage detected', 
        component: 'PerformanceMonitor',
        metadata: {'memoryUsage': currentMemory});
    }
  }

  void _checkFpsPerformance() {
    final previousStatus = performanceStatus;
    
    if (_currentFps < _fpsCriticalThreshold) {
      AppLogger.warning('Critical FPS drop detected', 
        component: 'PerformanceMonitor',
        metadata: {'fps': _currentFps, 'averageFps': _averageFps});
      _isPerformanceOptimized = false;
    } else if (_currentFps < _fpsWarningThreshold) {
      AppLogger.info('FPS performance warning', 
        component: 'PerformanceMonitor',
        metadata: {'fps': _currentFps, 'averageFps': _averageFps});
      _isPerformanceOptimized = false;
    } else {
      _isPerformanceOptimized = true;
    }
    
    // Notify status callbacks if status changed
    if (previousStatus != performanceStatus) {
      _notifyStatusCallbacks();
    }
  }

  void _notifyFpsCallbacks() {
    for (final callback in _fpsCallbacks) {
      try {
        callback(_currentFps);
      } catch (e) {
        AppLogger.error('Error in FPS callback', 
          component: 'PerformanceMonitor', error: e);
      }
    }
  }

  void _notifyStatusCallbacks() {
    for (final callback in _statusCallbacks) {
      try {
        callback(performanceStatus);
      } catch (e) {
        AppLogger.error('Error in status callback', 
          component: 'PerformanceMonitor', error: e);
      }
    }
  }

  // Enhanced API for futuristic UI components
  void addFpsCallback(Function(double) callback) {
    _fpsCallbacks.add(callback);
  }

  void removeFpsCallback(Function(double) callback) {
    _fpsCallbacks.remove(callback);
  }

  void addStatusCallback(Function(PerformanceStatus) callback) {
    _statusCallbacks.add(callback);
  }

  void removeStatusCallback(Function(PerformanceStatus) callback) {
    _statusCallbacks.remove(callback);
  }

  // Performance optimization suggestions
  PerformanceOptimization getOptimizationSuggestion() {
    if (_currentFps < AnimationConfig.minFPS) {
      return PerformanceOptimization.reduceAnimations;
    } else if (_averageFps < AnimationConfig.targetFPS * 0.8) {
      return PerformanceOptimization.reduceEffects;
    } else if (_droppedFrames > 10) {
      return PerformanceOptimization.optimizeShapes;
    }
    return PerformanceOptimization.none;
  }

  // Auto-optimization based on performance
  bool shouldReduceAnimations() {
    return _currentFps < AnimationConfig.minFPS;
  }

  bool shouldReduceShapes() {
    return _averageFps < AnimationConfig.targetFPS * 0.7;
  }

  bool shouldDisableEffects() {
    return _currentFps < _fpsCriticalThreshold;
  }

  // Getters for current performance metrics
  double get currentFps => _currentFps;
  double get averageFps => _averageFps;
  int get currentMemoryUsage => _lastMemoryUsage;
  List<int> get memoryHistory => List.unmodifiable(_memoryHistory);
  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);
  bool get isPerformanceOptimized => _isPerformanceOptimized;
  int get droppedFrames => _droppedFrames;
  
  // Performance status
  PerformanceStatus get performanceStatus {
    if (_currentFps < _fpsCriticalThreshold || _lastMemoryUsage > _memoryCriticalThreshold) {
      return PerformanceStatus.critical;
    } else if (_currentFps < _fpsWarningThreshold || _lastMemoryUsage > _memoryWarningThreshold) {
      return PerformanceStatus.warning;
    }
    return PerformanceStatus.good;
  }

  // Reset performance tracking
  void resetTracking() {
    _fpsHistory.clear();
    _droppedFrames = 0;
    _averageFps = 60.0;
    AppLogger.info('Performance tracking reset', component: 'PerformanceMonitor');
  }
}

enum PerformanceStatus {
  good,
  warning,
  critical,
}

enum PerformanceOptimization {
  none,
  optimizeShapes,
  reduceEffects,
  reduceAnimations,
}