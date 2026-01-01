// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import '../logging/app_logger.dart';
// import '../platform/platform_utils.dart';

// /// Performance monitoring system for tracking app performance
// /// 
// /// This system monitors frame rates, memory usage, and other performance
// /// metrics to help identify and resolve performance issues.
// class PerformanceMonitor {
//   static final PerformanceMonitor _instance = PerformanceMonitor._internal();
//   factory PerformanceMonitor() => _instance;
//   PerformanceMonitor._internal();
  
//   final List<Duration> _frameTimes = [];
//   final Map<String, Stopwatch> _operations = {};
//   final Map<String, List<Duration>> _operationHistory = {};
  
//   Timer? _monitoringTimer;
//   bool _isMonitoring = false;
//   int _frameCount = 0;
//   double _averageFPS = 60.0;
  
//   // Performance thresholds
//   static const Duration _slowFrameThreshold = Duration(milliseconds: 16); // 60 FPS
//   static const Duration _jankFrameThreshold = Duration(milliseconds: 32); // 30 FPS
//   static const int _maxFrameHistory = 120; // 2 seconds at 60 FPS
  
//   /// Start performance monitoring
//   void startMonitoring() {
//     if (_isMonitoring) return;
    
//     try {
//       _isMonitoring = true;
      
//       // Monitor frame performance
//       SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
      
//       // Start periodic reporting
//       _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (_) {
//         _reportPerformanceMetrics();
//       });
      
//       AppLogger.info('Performance monitoring started',
//         component: 'PerformanceMonitor');
//     } catch (e) {
//       AppLogger.error('Failed to start performance monitoring',
//         component: 'PerformanceMonitor',
//         error: e);
//     }
//   }
  
//   /// Stop performance monitoring
//   void stopMonitoring() {
//     if (!_isMonitoring) return;
    
//     try {
//       _isMonitoring = false;
      
//       SchedulerBinding.instance.removePersistentFrameCallback(_onFrame);
//       _monitoringTimer?.cancel();
//       _monitoringTimer = null;
      
//       AppLogger.info('Performance monitoring stopped',
//         component: 'PerformanceMonitor');
//     } catch (e) {
//       AppLogger.error('Failed to stop performance monitoring',
//         component: 'PerformanceMonitor',
//         error: e);
//     }
//   }
  
//   /// Start timing an operation
//   void startOperation(String operationName) {
//     try {
//       final stopwatch = Stopwatch()..start();
//       _operations[operationName] = stopwatch;
      
//       AppLogger.debug('Started timing operation',
//         component: 'PerformanceMonitor',
//         metadata: {'operation': operationName});
//     } catch (e) {
//       AppLogger.warning('Failed to start operation timing',
//         component: 'PerformanceMonitor',
//         error: e,
//         metadata: {'operation': operationName});
//     }
//   }
  
//   /// End timing an operation
//   Duration? endOperation(String operationName) {
//     try {
//       final stopwatch = _operations.remove(operationName);
//       if (stopwatch == null) {
//         AppLogger.warning('Operation not found for timing',
//           component: 'PerformanceMonitor',
//           metadata: {'operation': operationName});
//         return null;
//       }
      
//       stopwatch.stop();
//       final duration = stopwatch.elapsed;
      
//       // Store in history
//       _operationHistory.putIfAbsent(operationName, () => <Duration>[]);
//       final history = _operationHistory[operationName]!;
//       history.add(duration);
      
//       // Keep only recent history
//       if (history.length > 100) {
//         history.removeAt(0);
//       }
      
//       // Log slow operations
//       if (duration.inMilliseconds > 100) {
//         AppLogger.warning('Slow operation detected',
//           component: 'PerformanceMonitor',
//           metadata: {
//             'operation': operationName,
//             'duration': duration.inMilliseconds,
//           });
//       } else {
//         AppLogger.debug('Operation completed',
//           component: 'PerformanceMonitor',
//           metadata: {
//             'operation': operationName,
//             'duration': duration.inMilliseconds,
//           });
//       }
      
//       return duration;
//     } catch (e) {
//       AppLogger.error('Failed to end operation timing',
//         component: 'PerformanceMonitor',
//         error: e,
//         metadata: {'operation': operationName});
//       return null;
//     }
//   }
  
//   /// Time an async operation
//   Future<T> timeAsyncOperation<T>(
//     String operationName,
//     Future<T> Function() operation,
//   ) async {
//     startOperation(operationName);
//     try {
//       final result = await operation();
//       endOperation(operationName);
//       return result;
//     } catch (e) {
//       endOperation(operationName);
//       rethrow;
//     }
//   }
  
//   /// Time a synchronous operation
//   T timeOperation<T>(
//     String operationName,
//     T Function() operation,
//   ) {
//     startOperation(operationName);
//     try {
//       final result = operation();
//       endOperation(operationName);
//       return result;
//     } catch (e) {
//       endOperation(operationName);
//       rethrow;
//     }
//   }
  
//   /// Get current performance metrics
//   Map<String, dynamic> getMetrics() {
//     final metrics = <String, dynamic>{
//       'isMonitoring': _isMonitoring,
//       'frameCount': _frameCount,
//       'averageFPS': _averageFPS,
//       'activeOperations': _operations.length,
//       'platform': PlatformUtils.isMobile ? 'mobile' : 'desktop',
//     };
    
//     // Add frame performance metrics
//     if (_frameTimes.isNotEmpty) {
//       final sortedFrameTimes = List<Duration>.from(_frameTimes)..sort();
//       metrics.addAll({
//         'frameMetrics': {
//           'count': _frameTimes.length,
//           'averageMs': _frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / _frameTimes.length / 1000,
//           'p50Ms': sortedFrameTimes[sortedFrameTimes.length ~/ 2].inMicroseconds / 1000,
//           'p90Ms': sortedFrameTimes[(sortedFrameTimes.length * 0.9).floor()].inMicroseconds / 1000,
//           'p99Ms': sortedFrameTimes[(sortedFrameTimes.length * 0.99).floor()].inMicroseconds / 1000,
//           'slowFrames': _frameTimes.where((d) => d > _slowFrameThreshold).length,
//           'jankFrames': _frameTimes.where((d) => d > _jankFrameThreshold).length,
//         },
//       });
//     }
    
//     // Add operation metrics
//     if (_operationHistory.isNotEmpty) {
//       final operationMetrics = <String, Map<String, dynamic>>{};
      
//       _operationHistory.forEach((name, durations) {
//         if (durations.isNotEmpty) {
//           final sortedDurations = List<Duration>.from(durations)..sort();
//           operationMetrics[name] = {
//             'count': durations.length,
//             'averageMs': durations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / durations.length / 1000,
//             'p50Ms': sortedDurations[sortedDurations.length ~/ 2].inMicroseconds / 1000,
//             'p90Ms': sortedDurations[(sortedDurations.length * 0.9).floor()].inMicroseconds / 1000,
//             'maxMs': sortedDurations.last.inMicroseconds / 1000,
//           };
//         }
//       });
      
//       metrics['operations'] = operationMetrics;
//     }
    
//     return metrics;
//   }
  
//   /// Handle frame callback for performance monitoring
//   void _onFrame(Duration timestamp) {
//     try {
//       _frameCount++;
      
//       // Calculate frame time (simplified)
//       if (_frameTimes.isNotEmpty) {
//         final lastFrameTime = _frameTimes.last;
//         final currentFrameTime = Duration(microseconds: timestamp.inMicroseconds);
//         final frameDuration = currentFrameTime - lastFrameTime;
        
//         _frameTimes.add(frameDuration);
        
//         // Keep only recent frame history
//         if (_frameTimes.length > _maxFrameHistory) {
//           _frameTimes.removeAt(0);
//         }
        
//         // Update average FPS
//         if (_frameTimes.length >= 10) {
//           final recentFrames = _frameTimes.sublist(_frameTimes.length - 10);
//           final averageFrameTime = recentFrames
//               .map((d) => d.inMicroseconds)
//               .reduce((a, b) => a + b) / recentFrames.length;
          
//           _averageFPS = 1000000 / averageFrameTime; // Convert to FPS
//         }
//       } else {
//         _frameTimes.add(Duration(microseconds: timestamp.inMicroseconds));
//       }
//     } catch (e) {
//       AppLogger.warning('Frame callback error',
//         component: 'PerformanceMonitor',
//         error: e);
//     }
//   }
  
//   /// Report performance metrics periodically
//   void _reportPerformanceMetrics() {
//     try {
//       final metrics = getMetrics();
      
//       // Log performance summary
//       AppLogger.info('Performance metrics',
//         component: 'PerformanceMonitor',
//         metadata: metrics);
      
//       // Check for performance issues
//       _checkPerformanceIssues(metrics);
//     } catch (e) {
//       AppLogger.error('Failed to report performance metrics',
//         component: 'PerformanceMonitor',
//         error: e);
//     }
//   }
  
//   /// Check for performance issues and log warnings
//   void _checkPerformanceIssues(Map<String, dynamic> metrics) {
//     try {
//       // Check FPS
//       final averageFPS = metrics['averageFPS'] as double?;
//       if (averageFPS != null && averageFPS < 30) {
//         AppLogger.warning('Low FPS detected',
//           component: 'PerformanceMonitor',
//           metadata: {'averageFPS': averageFPS});
//       }
      
//       // Check frame metrics
//       final frameMetrics = metrics['frameMetrics'] as Map<String, dynamic>?;
//       if (frameMetrics != null) {
//         final jankFrames = frameMetrics['jankFrames'] as int?;
//         final totalFrames = frameMetrics['count'] as int?;
        
//         if (jankFrames != null && totalFrames != null && totalFrames > 0) {
//           final jankPercentage = (jankFrames / totalFrames) * 100;
//           if (jankPercentage > 5) {
//             AppLogger.warning('High jank rate detected',
//               component: 'PerformanceMonitor',
//               metadata: {
//                 'jankPercentage': jankPercentage,
//                 'jankFrames': jankFrames,
//                 'totalFrames': totalFrames,
//               });
//           }
//         }
//       }
      
//       // Check slow operations
//       final operations = metrics['operations'] as Map<String, dynamic>?;
//       if (operations != null) {
//         operations.forEach((name, opMetrics) {
//           final averageMs = opMetrics['averageMs'] as double?;
//           if (averageMs != null && averageMs > 100) {
//             AppLogger.warning('Slow operation detected',
//               component: 'PerformanceMonitor',
//               metadata: {
//                 'operation': name,
//                 'averageMs': averageMs,
//               });
//           }
//         });
//       }
//     } catch (e) {
//       AppLogger.error('Failed to check performance issues',
//         component: 'PerformanceMonitor',
//         error: e);
//     }
//   }
  
//   /// Clear all performance data
//   void clearMetrics() {
//     _frameTimes.clear();
//     _operations.clear();
//     _operationHistory.clear();
//     _frameCount = 0;
//     _averageFPS = 60.0;
    
//     AppLogger.info('Performance metrics cleared',
//       component: 'PerformanceMonitor');
//   }
  
//   /// Dispose of resources
//   void dispose() {
//     stopMonitoring();
//     clearMetrics();
    
//     AppLogger.info('Performance monitor disposed',
//       component: 'PerformanceMonitor');
//   }
// }

// /// Mixin for widgets that need performance monitoring
// mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
//   final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
//   /// Time a build operation
//   Widget timeWidgetBuild(String operationName, Widget Function() builder) {
//     return _performanceMonitor.timeOperation(operationName, builder);
//   }
  
//   /// Time an async operation
//   Future<R> timeAsync<R>(String operationName, Future<R> Function() operation) {
//     return _performanceMonitor.timeAsyncOperation(operationName, operation);
//   }
  
//   /// Start timing an operation
//   void startTiming(String operationName) {
//     _performanceMonitor.startOperation(operationName);
//   }
  
//   /// End timing an operation
//   Duration? endTiming(String operationName) {
//     return _performanceMonitor.endOperation(operationName);
//   }
// }