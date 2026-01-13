import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Performance metrics
  double _currentFPS = 60.0;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  final List<double> _fpsHistory = [];
  final Map<String, DateTime> _loadTimes = {};
  final Map<String, Duration> _screenLoadDurations = {};
  
  // Memory tracking
  int _lastMemoryUsage = 0;
  final List<int> _memoryHistory = [];
  
  // Performance thresholds
  static const double _targetFPS = 60.0;
  static const double _lowFPSThreshold = 45.0;
  static const int _maxMemoryMB = 200; // 200MB threshold
  static const Duration _maxLoadTime = Duration(seconds: 2);

  // Getters
  double get currentFPS => _currentFPS;
  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);
  int get currentMemoryUsage => _lastMemoryUsage;
  List<int> get memoryHistory => List.unmodifiable(_memoryHistory);
  Map<String, Duration> get screenLoadDurations => Map.unmodifiable(_screenLoadDurations);

  /// Initialize performance monitoring
  void initialize() {
    if (kDebugMode) {
      _startFPSMonitoring();
      _startMemoryMonitoring();
    }
  }

  /// Start monitoring frame rate
  void _startFPSMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _frameCount++;
      final now = DateTime.now();
      final timeDiff = now.difference(_lastFrameTime).inMilliseconds;
      
      if (timeDiff >= 1000) { // Calculate FPS every second
        _currentFPS = (_frameCount * 1000) / timeDiff;
        _fpsHistory.add(_currentFPS);
        
        // Keep only last 60 seconds of data
        if (_fpsHistory.length > 60) {
          _fpsHistory.removeAt(0);
        }
        
        _frameCount = 0;
        _lastFrameTime = now;
        
        // Log performance warnings
        if (_currentFPS < _lowFPSThreshold) {
          debugPrint('⚠️ Low FPS detected: ${_currentFPS.toStringAsFixed(1)}');
        }
      }
    });
  }

  /// Start monitoring memory usage
  void _startMemoryMonitoring() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateMemoryUsage();
    });
  }

  void _updateMemoryUsage() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Estimate memory usage (simplified)
      final estimatedMemory = (_fpsHistory.length * 10) + 
                             (_memoryHistory.length * 5) + 
                             (_loadTimes.length * 2);
      
      _lastMemoryUsage = estimatedMemory;
      _memoryHistory.add(_lastMemoryUsage);
      
      // Keep only last 100 readings
      if (_memoryHistory.length > 100) {
        _memoryHistory.removeAt(0);
      }
      
      // Log memory warnings
      if (_lastMemoryUsage > _maxMemoryMB) {
        debugPrint('⚠️ High memory usage: ${_lastMemoryUsage}MB');
      }
    }
  }

  /// Record screen load start time
  void recordLoadStart(String screenName) {
    _loadTimes[screenName] = DateTime.now();
  }

  /// Record screen load completion and calculate duration
  void recordLoadComplete(String screenName) {
    final startTime = _loadTimes[screenName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _screenLoadDurations[screenName] = duration;
      _loadTimes.remove(screenName);
      
      if (kDebugMode) {
        debugPrint('📊 $screenName loaded in ${duration.inMilliseconds}ms');
        
        if (duration > _maxLoadTime) {
          debugPrint('⚠️ Slow load time for $screenName: ${duration.inMilliseconds}ms');
        }
      }
    }
  }

  /// Get performance recommendations
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    
    // FPS recommendations
    final avgFPS = _fpsHistory.isNotEmpty 
        ? _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length
        : 60.0;
    
    if (avgFPS < _lowFPSThreshold) {
      recommendations.add('Consider reducing animation complexity or image sizes');
      recommendations.add('Enable performance mode for lower-end devices');
    }
    
    // Memory recommendations
    if (_lastMemoryUsage > _maxMemoryMB) {
      recommendations.add('Consider implementing image caching optimization');
      recommendations.add('Review memory usage in image loading');
    }
    
    // Load time recommendations
    final slowScreens = _screenLoadDurations.entries
        .where((entry) => entry.value > _maxLoadTime)
        .map((entry) => entry.key)
        .toList();
    
    if (slowScreens.isNotEmpty) {
      recommendations.add('Optimize loading for: ${slowScreens.join(', ')}');
      recommendations.add('Consider lazy loading for heavy content');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance is optimal! 🎉');
    }
    
    return recommendations;
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final avgFPS = _fpsHistory.isNotEmpty 
        ? _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length
        : 60.0;
    
    final avgLoadTime = _screenLoadDurations.values.isNotEmpty
        ? _screenLoadDurations.values
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b) / _screenLoadDurations.length
        : 0.0;
    
    return {
      'currentFPS': _currentFPS,
      'averageFPS': avgFPS,
      'memoryUsage': _lastMemoryUsage,
      'averageLoadTime': avgLoadTime,
      'totalScreensLoaded': _screenLoadDurations.length,
      'performanceScore': _calculatePerformanceScore(avgFPS, avgLoadTime),
    };
  }

  double _calculatePerformanceScore(double avgFPS, double avgLoadTime) {
    // Score out of 100
    double fpsScore = (avgFPS / _targetFPS * 50).clamp(0, 50);
    double loadTimeScore = avgLoadTime > 0 
        ? ((2000 - avgLoadTime) / 2000 * 50).clamp(0, 50)
        : 50;
    
    return (fpsScore + loadTimeScore).clamp(0, 100);
  }

  /// Reset all performance data
  void reset() {
    _fpsHistory.clear();
    _memoryHistory.clear();
    _loadTimes.clear();
    _screenLoadDurations.clear();
    _frameCount = 0;
    _lastFrameTime = DateTime.now();
  }
}

/// Mixin for widgets to easily track performance
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  late String _screenName;

  @override
  void initState() {
    super.initState();
    _screenName = widget.runtimeType.toString();
    _monitor.recordLoadStart(_screenName);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Record load complete after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monitor.recordLoadComplete(_screenName);
    });
  }

  /// Get performance recommendations for this screen
  List<String> getRecommendations() {
    return _monitor.getPerformanceRecommendations();
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return _monitor.getPerformanceSummary();
  }
}