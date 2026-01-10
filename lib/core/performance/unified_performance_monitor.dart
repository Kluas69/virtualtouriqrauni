import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../logging/app_logger.dart';
import '../animation/animation_config.dart';
import '../platform/platform_utils.dart';

// Conditional web imports
import 'dart:html' as html show window, document, LinkElement, ScriptElement, PerformanceObserver;

/// Unified performance monitoring system that consolidates all performance tracking
/// Combines functionality from PerformanceMonitor, AdaptivePerformanceMonitor, and WebPerformanceOptimizer
class UnifiedPerformanceMonitor {
  static final UnifiedPerformanceMonitor _instance = UnifiedPerformanceMonitor._internal();
  factory UnifiedPerformanceMonitor() => _instance;
  UnifiedPerformanceMonitor._internal();

  static const String _logComponent = 'UnifiedPerformanceMonitor';

  // Core monitoring state
  Timer? _memoryTimer;
  Timer? _fpsTimer;
  Timer? _adaptiveTimer;
  int _frameCount = 0;
  DateTime _lastFpsCheck = DateTime.now();
  double _currentFps = 60.0;
  
  // Memory tracking
  int _lastMemoryUsage = 0;
  List<int> _memoryHistory = [];
  
  // Enhanced performance tracking
  List<double> _fpsHistory = [];
  bool _isPerformanceOptimized = true;
  int _droppedFrames = 0;
  double _averageFps = 60.0;
  
  // Adaptive monitoring
  Duration _currentInterval = const Duration(seconds: 5);
  final Map<String, double> _metrics = {};
  int _consecutiveGoodFrames = 0;
  int _consecutiveBadFrames = 0;
  
  // Performance callbacks
  final List<Function(double)> _fpsCallbacks = [];
  final List<Function(PerformanceStatus)> _statusCallbacks = [];
  
  // Performance thresholds
  static const int _memoryWarningThreshold = 100 * 1024 * 1024; // 100MB
  static const int _memoryCriticalThreshold = 200 * 1024 * 1024; // 200MB
  static const double _fpsWarningThreshold = 45.0;
  static const double _fpsCriticalThreshold = 30.0;
  
  // Adaptive thresholds
  static const int _goodFrameThreshold = 10;
  static const int _badFrameThreshold = 3;
  static const Duration _minInterval = Duration(seconds: 1);
  static const Duration _maxInterval = Duration(seconds: 30);
  
  // Web optimization state
  bool _webOptimizationsInitialized = false;

  /// Initialize the unified performance monitoring system
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing unified performance monitoring system', component: _logComponent);
      
      if (kDebugMode) {
        _startMemoryMonitoring();
        _startFpsMonitoring();
        _startAdaptiveMonitoring();
      }
      
      // Initialize web-specific optimizations if on web platform
      if (kIsWeb) {
        await _initializeWebOptimizations();
      }
      
      AppLogger.info('Unified performance monitoring initialized successfully', component: _logComponent);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize unified performance monitoring',
        component: _logComponent,
        error: e,
        stackTrace: stackTrace);
    }
  }

  /// Start monitoring performance metrics
  void startMonitoring() {
    if (kDebugMode) {
      AppLogger.info('Starting enhanced performance monitoring', component: _logComponent);
      
      _startMemoryMonitoring();
      _startFpsMonitoring();
      _startAdaptiveMonitoring();
    }
  }

  /// Stop all performance monitoring
  void stopMonitoring() {
    _memoryTimer?.cancel();
    _fpsTimer?.cancel();
    _adaptiveTimer?.cancel();
    AppLogger.info('Stopped performance monitoring', component: _logComponent);
  }

  /// Start memory usage monitoring
  void _startMemoryMonitoring() {
    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkMemoryUsage();
    });
  }

  /// Start FPS monitoring
  void _startFpsMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateFps();
    });
  }

  /// Start adaptive monitoring that adjusts frequency based on performance
  void _startAdaptiveMonitoring() {
    _adaptiveTimer = Timer.periodic(_currentInterval, (_) {
      _collectMetricsAndAdapt();
    });
  }

  /// Frame callback for FPS calculation
  void _onFrame(Duration timestamp) {
    _frameCount++;
  }

  /// Calculate current FPS and update metrics
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

  /// Collect metrics and adapt monitoring frequency
  void _collectMetricsAndAdapt() {
    _metrics['fps'] = _currentFps;
    
    // Determine if performance is good or bad
    final isGoodPerformance = _currentFps >= 55.0; // Near 60 FPS
    
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

  /// Reduce monitoring frequency when performance is consistently good
  void _reduceMonitoringFrequency() {
    final newInterval = Duration(
      milliseconds: (_currentInterval.inMilliseconds * 1.5).round()
    );
    
    if (newInterval <= _maxInterval) {
      _currentInterval = newInterval;
      _restartAdaptiveMonitoring();
      
      AppLogger.debug('Reduced monitoring frequency',
        component: _logComponent,
        metadata: {'newInterval': '${_currentInterval.inSeconds}s'});
    }
  }

  /// Increase monitoring frequency when performance is poor
  void _increaseMonitoringFrequency() {
    final newInterval = Duration(
      milliseconds: (_currentInterval.inMilliseconds * 0.7).round()
    );
    
    if (newInterval >= _minInterval) {
      _currentInterval = newInterval;
      _restartAdaptiveMonitoring();
      
      AppLogger.debug('Increased monitoring frequency',
        component: _logComponent,
        metadata: {'newInterval': '${_currentInterval.inSeconds}s'});
    }
  }

  /// Restart adaptive monitoring with new interval
  void _restartAdaptiveMonitoring() {
    _adaptiveTimer?.cancel();
    _adaptiveTimer = Timer.periodic(_currentInterval, (_) {
      _collectMetricsAndAdapt();
    });
  }

  /// Check memory usage and log warnings
  void _checkMemoryUsage() {
    if (Platform.isAndroid || Platform.isIOS) {
      _simulateMemoryCheck();
    }
  }

  /// Simulate memory usage tracking (replace with actual implementation)
  void _simulateMemoryCheck() {
    final currentMemory = _lastMemoryUsage + (DateTime.now().millisecondsSinceEpoch % 1000);
    _lastMemoryUsage = currentMemory;
    _memoryHistory.add(currentMemory);
    
    // Keep only last 20 readings
    if (_memoryHistory.length > 20) {
      _memoryHistory.removeAt(0);
    }
    
    if (currentMemory > _memoryCriticalThreshold) {
      AppLogger.warning('Critical memory usage detected', 
        component: _logComponent,
        metadata: {'memoryUsage': currentMemory});
    } else if (currentMemory > _memoryWarningThreshold) {
      AppLogger.info('High memory usage detected', 
        component: _logComponent,
        metadata: {'memoryUsage': currentMemory});
    }
  }

  /// Check FPS performance and update optimization status
  void _checkFpsPerformance() {
    final previousStatus = performanceStatus;
    
    if (_currentFps < _fpsCriticalThreshold) {
      AppLogger.warning('Critical FPS drop detected', 
        component: _logComponent,
        metadata: {'fps': _currentFps, 'averageFps': _averageFps});
      _isPerformanceOptimized = false;
    } else if (_currentFps < _fpsWarningThreshold) {
      AppLogger.info('FPS performance warning', 
        component: _logComponent,
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

  /// Notify FPS callbacks
  void _notifyFpsCallbacks() {
    for (final callback in _fpsCallbacks) {
      try {
        callback(_currentFps);
      } catch (e) {
        AppLogger.error('Error in FPS callback', 
          component: _logComponent, error: e);
      }
    }
  }

  /// Notify status callbacks
  void _notifyStatusCallbacks() {
    for (final callback in _statusCallbacks) {
      try {
        callback(performanceStatus);
      } catch (e) {
        AppLogger.error('Error in status callback', 
          component: _logComponent, error: e);
      }
    }
  }

  /// Initialize web-specific performance optimizations
  Future<void> _initializeWebOptimizations() async {
    if (_webOptimizationsInitialized || !kIsWeb) return;
    
    try {
      AppLogger.info('Initializing web performance optimizations', component: _logComponent);
      
      _addResourceHints();
      _configureServiceWorker();
      _setupLazyImageLoading();
      _setupPerformanceObservers();
      _addCodeSplittingHints();
      
      _webOptimizationsInitialized = true;
      AppLogger.info('Web performance optimizations initialized', component: _logComponent);
    } catch (e) {
      AppLogger.error('Failed to initialize web performance optimizations',
        component: _logComponent, error: e);
    }
  }

  /// Add resource hints for faster loading (web-specific)
  void _addResourceHints() {
    if (!kIsWeb) return;
    
    try {
      final head = html.document.head;
      if (head == null) return;
      
      // Preload critical assets
      final criticalAssets = [
        'assets/models/classroom.glb',
        'assets/app_data.json',
      ];
      
      for (final asset in criticalAssets) {
        final link = html.LinkElement()
          ..rel = 'preload'
          ..href = asset
          ..setAttribute('as', 'fetch')
          ..setAttribute('crossorigin', 'anonymous');
        head.append(link);
      }
      
      // DNS prefetch for external resources
      final externalDomains = [
        'fonts.googleapis.com',
        'fonts.gstatic.com',
      ];
      
      for (final domain in externalDomains) {
        final link = html.LinkElement()
          ..rel = 'dns-prefetch'
          ..href = 'https://$domain';
        head.append(link);
      }
      
      AppLogger.debug('Added resource hints', component: _logComponent);
    } catch (e) {
      AppLogger.warning('Failed to add resource hints', component: _logComponent, error: e);
    }
  }

  /// Configure service worker for caching (web-specific)
  void _configureServiceWorker() {
    if (!kIsWeb) return;
    
    try {
      if (html.window.navigator.serviceWorker == null) return;
      
      html.window.navigator.serviceWorker!.register('/flutter_service_worker.js')
        .then((registration) {
          AppLogger.info('Service worker registered successfully', component: _logComponent);
        })
        .catchError((error) {
          AppLogger.warning('Service worker registration failed', 
            component: _logComponent, error: error);
        });
    } catch (e) {
      AppLogger.warning('Failed to configure service worker', component: _logComponent, error: e);
    }
  }

  /// Setup lazy loading for images (web-specific)
  void _setupLazyImageLoading() {
    if (!kIsWeb) return;
    
    try {
      final script = html.ScriptElement()
        ..text = '''
          if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries, observer) => {
              entries.forEach(entry => {
                if (entry.isIntersecting) {
                  const img = entry.target;
                  if (img.dataset.src) {
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    observer.unobserve(img);
                  }
                }
              });
            }, {
              rootMargin: '50px 0px',
              threshold: 0.01
            });
            
            document.querySelectorAll('img[data-src]').forEach(img => {
              imageObserver.observe(img);
            });
          }
        ''';
      
      html.document.head?.append(script);
    } catch (e) {
      AppLogger.warning('Failed to setup lazy image loading', component: _logComponent, error: e);
    }
  }

  /// Setup performance observers for Core Web Vitals (web-specific)
  void _setupPerformanceObservers() {
    if (!kIsWeb) return;
    
    try {
      final script = html.ScriptElement()
        ..text = '''
          if ('PerformanceObserver' in window) {
            const observer = new PerformanceObserver((list) => {
              for (const entry of list.getEntries()) {
                if (entry.entryType === 'largest-contentful-paint') {
                  console.log('LCP:', entry.startTime);
                } else if (entry.entryType === 'first-input') {
                  console.log('FID:', entry.processingStart - entry.startTime);
                } else if (entry.entryType === 'layout-shift') {
                  if (!entry.hadRecentInput) {
                    console.log('CLS:', entry.value);
                  }
                }
              }
            });
            
            try {
              observer.observe({entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift']});
            } catch (e) {
              console.warn('Performance observer not supported:', e);
            }
          }
        ''';
      
      html.document.head?.append(script);
    } catch (e) {
      AppLogger.warning('Failed to setup performance observers', component: _logComponent, error: e);
    }
  }

  /// Add code splitting hints (web-specific)
  void _addCodeSplittingHints() {
    if (!kIsWeb) return;
    
    try {
      final head = html.document.head;
      if (head == null) return;
      
      final moduleHints = [
        '/assets/packages/flutter/assets/FontManifest.json',
      ];
      
      for (final module in moduleHints) {
        final link = html.LinkElement()
          ..rel = 'modulepreload'
          ..href = module;
        head.append(link);
      }
    } catch (e) {
      AppLogger.warning('Failed to add code splitting hints', component: _logComponent, error: e);
    }
  }

  // Public API methods

  /// Add FPS callback
  void addFpsCallback(Function(double) callback) {
    _fpsCallbacks.add(callback);
  }

  /// Remove FPS callback
  void removeFpsCallback(Function(double) callback) {
    _fpsCallbacks.remove(callback);
  }

  /// Add status callback
  void addStatusCallback(Function(PerformanceStatus) callback) {
    _statusCallbacks.add(callback);
  }

  /// Remove status callback
  void removeStatusCallback(Function(PerformanceStatus) callback) {
    _statusCallbacks.remove(callback);
  }

  /// Get performance optimization suggestion
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

  /// Check if animations should be reduced
  bool shouldReduceAnimations() {
    return _currentFps < AnimationConfig.minFPS;
  }

  /// Check if shapes should be reduced
  bool shouldReduceShapes() {
    return _averageFps < AnimationConfig.targetFPS * 0.7;
  }

  /// Check if effects should be disabled
  bool shouldDisableEffects() {
    return _currentFps < _fpsCriticalThreshold;
  }

  /// Reset performance tracking
  void resetTracking() {
    _fpsHistory.clear();
    _droppedFrames = 0;
    _averageFps = 60.0;
    _consecutiveGoodFrames = 0;
    _consecutiveBadFrames = 0;
    AppLogger.info('Performance tracking reset', component: _logComponent);
  }

  /// Get current metrics
  Map<String, double> getMetrics() => Map.from(_metrics);

  /// Preload critical resources (web-specific)
  void preloadCriticalResources(List<String> resources) {
    if (!kIsWeb) return;
    
    try {
      final head = html.document.head;
      if (head == null) return;
      
      for (final resource in resources) {
        final link = html.LinkElement()
          ..rel = 'preload'
          ..href = resource
          ..setAttribute('as', _getResourceType(resource));
        head.append(link);
      }
      
      AppLogger.debug('Preloaded critical resources',
        component: _logComponent,
        metadata: {'count': resources.length});
    } catch (e) {
      AppLogger.warning('Failed to preload critical resources', 
        component: _logComponent, error: e);
    }
  }

  String _getResourceType(String url) {
    if (url.endsWith('.js')) return 'script';
    if (url.endsWith('.css')) return 'style';
    if (url.endsWith('.woff2') || url.endsWith('.woff')) return 'font';
    if (url.contains('image') || url.endsWith('.jpg') || url.endsWith('.png')) return 'image';
    return 'fetch';
  }

  /// Dispose of all resources
  void dispose() {
    stopMonitoring();
    _fpsCallbacks.clear();
    _statusCallbacks.clear();
    _metrics.clear();
    _fpsHistory.clear();
    _memoryHistory.clear();
    AppLogger.info('Unified performance monitor disposed', component: _logComponent);
  }

  // Getters for current performance metrics
  double get currentFps => _currentFps;
  double get averageFps => _averageFps;
  int get currentMemoryUsage => _lastMemoryUsage;
  List<int> get memoryHistory => List.unmodifiable(_memoryHistory);
  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);
  bool get isPerformanceOptimized => _isPerformanceOptimized;
  int get droppedFrames => _droppedFrames;
  
  /// Get current performance status
  PerformanceStatus get performanceStatus {
    if (_currentFps < _fpsCriticalThreshold || _lastMemoryUsage > _memoryCriticalThreshold) {
      return PerformanceStatus.critical;
    } else if (_currentFps < _fpsWarningThreshold || _lastMemoryUsage > _memoryWarningThreshold) {
      return PerformanceStatus.warning;
    }
    return PerformanceStatus.good;
  }
}

/// Performance status enumeration
enum PerformanceStatus {
  good,
  warning,
  critical,
}

/// Performance optimization suggestions
enum PerformanceOptimization {
  none,
  optimizeShapes,
  reduceEffects,
  reduceAnimations,
}