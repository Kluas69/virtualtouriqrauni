import 'dart:async';
import 'dart:html' as html;
import '../logging/app_logger.dart';
import '../platform/platform_utils.dart';

/// Device capability information for performance optimization
class DeviceCapabilities {
  final bool isMobile;
  final bool isTablet;
  final bool isLowEnd;
  final double memoryGB;
  final int cores;
  final String platform;
  final String browser;
  final bool supportsWebGL2;
  final bool supportsTouch;
  final double pixelRatio;
  
  const DeviceCapabilities({
    required this.isMobile,
    required this.isTablet,
    required this.isLowEnd,
    required this.memoryGB,
    required this.cores,
    required this.platform,
    required this.browser,
    required this.supportsWebGL2,
    required this.supportsTouch,
    required this.pixelRatio,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'isMobile': isMobile,
      'isTablet': isTablet,
      'isLowEnd': isLowEnd,
      'memoryGB': memoryGB,
      'cores': cores,
      'platform': platform,
      'browser': browser,
      'supportsWebGL2': supportsWebGL2,
      'supportsTouch': supportsTouch,
      'pixelRatio': pixelRatio,
    };
  }
}

/// Performance preset configurations for different device types
enum PerformancePreset {
  low('Low', 0.5, 30, 1024),
  medium('Medium', 0.75, 45, 2048),
  high('High', 1.0, 60, 4096),
  ultra('Ultra', 1.2, 60, 8192);
  
  const PerformancePreset(this.displayName, this.renderScale, this.targetFPS, this.maxTextureSize);
  
  final String displayName;
  final double renderScale;
  final int targetFPS;
  final int maxTextureSize;
}

/// Touch event throttling configuration
class TouchThrottleConfig {
  final int intervalMs;
  final bool useRequestAnimationFrame;
  final double sensitivity;
  final bool enableGestures;
  
  const TouchThrottleConfig({
    this.intervalMs = 16, // 60fps (16ms intervals)
    this.useRequestAnimationFrame = true,
    this.sensitivity = 1.0,
    this.enableGestures = true,
  });
}

/// Mobile performance optimizer for WebGL applications
/// Implements touch event throttling, device-specific optimizations, and adaptive quality scaling
class MobilePerformanceOptimizer {
  static const String _logComponent = 'MobilePerformanceOptimizer';
  
  /// Touch throttling configuration
  late final TouchThrottleConfig _touchConfig;
  
  /// Device capabilities
  late final DeviceCapabilities _deviceCapabilities;
  
  /// Current performance preset
  PerformancePreset _currentPreset = PerformancePreset.high;
  
  /// Touch event throttling state
  final Map<String, int> _lastTouchEventTime = {};
  final Map<String, Timer?> _touchThrottleTimers = {};
  
  /// Performance monitoring
  final List<double> _fpsHistory = [];
  final List<double> _memoryHistory = [];
  double _currentFPS = 60.0;
  double _currentMemoryMB = 0.0;
  
  /// Adaptive quality scaling
  bool _adaptiveQualityEnabled = true;
  int _performanceDropCount = 0;
  static const int _performanceDropThreshold = 3;
  
  /// Initialize mobile performance optimizer
  MobilePerformanceOptimizer({
    TouchThrottleConfig? touchConfig,
    DeviceCapabilities? deviceCapabilities,
  }) {
    _touchConfig = touchConfig ?? const TouchThrottleConfig();
    _deviceCapabilities = deviceCapabilities ?? _detectDeviceCapabilities();
    
    // Set initial performance preset based on device capabilities
    _currentPreset = _determineOptimalPreset();
    
    AppLogger.info('Mobile performance optimizer initialized',
      component: _logComponent,
      metadata: {
        'preset': _currentPreset.displayName,
        'device': _deviceCapabilities.toMap(),
        'touchInterval': _touchConfig.intervalMs,
      });
  }
  
  /// Detect device capabilities
  DeviceCapabilities _detectDeviceCapabilities() {
    try {
      // Detect mobile/tablet
      final userAgent = html.window.navigator.userAgent;
      final isMobile = RegExp(r'Mobile|Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini').hasMatch(userAgent);
      final isTablet = RegExp(r'iPad|Android.*Tablet|Kindle|Silk').hasMatch(userAgent);
      
      // Detect browser
      String browser = 'Unknown';
      if (userAgent.contains('Chrome')) browser = 'Chrome';
      else if (userAgent.contains('Firefox')) browser = 'Firefox';
      else if (userAgent.contains('Safari')) browser = 'Safari';
      else if (userAgent.contains('Edge')) browser = 'Edge';
      
      // Detect platform
      String platform = 'Unknown';
      if (userAgent.contains('Windows')) platform = 'Windows';
      else if (userAgent.contains('Mac')) platform = 'macOS';
      else if (userAgent.contains('Linux')) platform = 'Linux';
      else if (userAgent.contains('Android')) platform = 'Android';
      else if (userAgent.contains('iOS')) platform = 'iOS';
      
      // Estimate memory (rough approximation)
      double memoryGB = 4.0; // Default assumption
      if (html.window.navigator.deviceMemory != null) {
        memoryGB = html.window.navigator.deviceMemory!.toDouble();
      } else {
        // Rough estimation based on device type
        if (isMobile) {
          memoryGB = isTablet ? 3.0 : 2.0;
        } else {
          memoryGB = 8.0;
        }
      }
      
      // Estimate cores
      int cores = html.window.navigator.hardwareConcurrency ?? 4;
      
      // Check WebGL2 support
      final canvas = html.CanvasElement();
      final webgl2Context = canvas.getContext('webgl2');
      final supportsWebGL2 = webgl2Context != null;
      
      // Check touch support
      final supportsTouch = html.window.navigator.maxTouchPoints != null && 
                           html.window.navigator.maxTouchPoints! > 0;
      
      // Get pixel ratio
      final pixelRatio = (html.window.devicePixelRatio ?? 1.0).toDouble();
      
      // Determine if low-end device
      final isLowEnd = (isMobile && memoryGB < 3.0) || 
                       cores < 4 || 
                       !supportsWebGL2;
      
      return DeviceCapabilities(
        isMobile: isMobile,
        isTablet: isTablet,
        isLowEnd: isLowEnd,
        memoryGB: memoryGB,
        cores: cores,
        platform: platform,
        browser: browser,
        supportsWebGL2: supportsWebGL2,
        supportsTouch: supportsTouch,
        pixelRatio: pixelRatio,
      );
      
    } catch (e) {
      AppLogger.error('Failed to detect device capabilities: $e',
        component: _logComponent,
        error: e);
      
      // Return safe defaults
      return const DeviceCapabilities(
        isMobile: false,
        isTablet: false,
        isLowEnd: false,
        memoryGB: 4.0,
        cores: 4,
        platform: 'Unknown',
        browser: 'Unknown',
        supportsWebGL2: false,
        supportsTouch: false,
        pixelRatio: 1.0,
      );
    }
  }
  
  /// Determine optimal performance preset based on device capabilities
  PerformancePreset _determineOptimalPreset() {
    if (_deviceCapabilities.isLowEnd) {
      return PerformancePreset.low;
    } else if (_deviceCapabilities.isMobile) {
      return _deviceCapabilities.memoryGB >= 4.0 ? PerformancePreset.medium : PerformancePreset.low;
    } else {
      return _deviceCapabilities.memoryGB >= 8.0 ? PerformancePreset.high : PerformancePreset.medium;
    }
  }
  
  /// Create throttled touch event handler
  /// Reduces touch event frequency from 240fps to 60fps for better performance
  Function throttleTouchEvents(Function eventHandler, [int? customInterval]) {
    final interval = customInterval ?? _touchConfig.intervalMs;
    
    return (dynamic event) {
      final eventType = event.runtimeType.toString();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastTime = _lastTouchEventTime[eventType] ?? 0;
      
      if (now - lastTime >= interval) {
        _lastTouchEventTime[eventType] = now;
        
        if (_touchConfig.useRequestAnimationFrame) {
          // Use requestAnimationFrame for smooth visual updates
          html.window.requestAnimationFrame((num time) {
            try {
              eventHandler(event);
            } catch (e) {
              AppLogger.error('Error in throttled touch handler: $e',
                component: _logComponent,
                error: e);
            }
          });
        } else {
          // Direct execution
          try {
            eventHandler(event);
          } catch (e) {
            AppLogger.error('Error in throttled touch handler: $e',
              component: _logComponent,
              error: e);
          }
        }
      }
    };
  }
  
  /// Apply device-specific performance optimizations
  Map<String, dynamic> getPerformanceSettings() {
    final settings = <String, dynamic>{
      'preset': _currentPreset.displayName,
      'renderScale': _currentPreset.renderScale,
      'targetFPS': _currentPreset.targetFPS,
      'maxTextureSize': _currentPreset.maxTextureSize,
      'touchThrottleInterval': _touchConfig.intervalMs,
      'useRequestAnimationFrame': _touchConfig.useRequestAnimationFrame,
      'sensitivity': _touchConfig.sensitivity,
      'enableGestures': _touchConfig.enableGestures,
    };
    
    // Mobile-specific optimizations
    if (_deviceCapabilities.isMobile) {
      settings.addAll({
        'enableShadows': false,
        'enablePostProcessing': !_deviceCapabilities.isLowEnd,
        'enableAntialiasing': !_deviceCapabilities.isLowEnd,
        'enableLOD': true,
        'cullingDistance': _deviceCapabilities.isLowEnd ? 50.0 : 100.0,
        'pixelRatio': _deviceCapabilities.isLowEnd ? 1.0 : _deviceCapabilities.pixelRatio,
      });
    }
    
    // Browser-specific optimizations
    if (_deviceCapabilities.browser == 'Safari') {
      settings.addAll({
        'enableWebGL2': false, // Safari WebGL2 issues
        'precision': 'mediump',
        'enableFloatTextures': false,
      });
    }
    
    return settings;
  }
  
  /// Update performance metrics and trigger adaptive quality scaling
  void updatePerformanceMetrics(double fps, double memoryMB) {
    _currentFPS = fps;
    _currentMemoryMB = memoryMB;
    
    // Add to history (keep last 60 samples)
    _fpsHistory.add(fps);
    _memoryHistory.add(memoryMB);
    
    if (_fpsHistory.length > 60) {
      _fpsHistory.removeAt(0);
    }
    if (_memoryHistory.length > 60) {
      _memoryHistory.removeAt(0);
    }
    
    // Check for performance issues
    if (_adaptiveQualityEnabled) {
      _checkPerformanceAndAdjust();
    }
  }
  
  /// Check performance and automatically adjust quality if needed
  void _checkPerformanceAndAdjust() {
    if (_fpsHistory.length < 10) return; // Need enough samples
    
    final averageFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    final targetFPS = _currentPreset.targetFPS.toDouble();
    
    // Check if performance is consistently below target
    if (averageFPS < targetFPS * 0.8) { // 80% of target FPS
      _performanceDropCount++;
      
      if (_performanceDropCount >= _performanceDropThreshold) {
        _reduceQuality();
        _performanceDropCount = 0;
      }
    } else if (averageFPS > targetFPS * 0.95) { // 95% of target FPS
      _performanceDropCount = 0;
      
      // Consider increasing quality if performance is good
      if (_currentPreset != PerformancePreset.ultra && 
          averageFPS > targetFPS && 
          _currentMemoryMB < 400) { // Memory usage is reasonable
        _increaseQuality();
      }
    }
  }
  
  /// Reduce quality preset for better performance
  void _reduceQuality() {
    final currentIndex = PerformancePreset.values.indexOf(_currentPreset);
    if (currentIndex > 0) {
      _currentPreset = PerformancePreset.values[currentIndex - 1];
      
      AppLogger.info('Performance quality reduced to: ${_currentPreset.displayName}',
        component: _logComponent,
        metadata: {
          'averageFPS': _fpsHistory.isNotEmpty ? _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length : 0,
          'targetFPS': _currentPreset.targetFPS,
          'memoryMB': _currentMemoryMB,
        });
    }
  }
  
  /// Increase quality preset if performance allows
  void _increaseQuality() {
    final currentIndex = PerformancePreset.values.indexOf(_currentPreset);
    if (currentIndex < PerformancePreset.values.length - 1) {
      _currentPreset = PerformancePreset.values[currentIndex + 1];
      
      AppLogger.info('Performance quality increased to: ${_currentPreset.displayName}',
        component: _logComponent,
        metadata: {
          'averageFPS': _fpsHistory.isNotEmpty ? _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length : 0,
          'targetFPS': _currentPreset.targetFPS,
          'memoryMB': _currentMemoryMB,
        });
    }
  }
  
  /// Set performance preset manually
  void setPerformancePreset(PerformancePreset preset) {
    _currentPreset = preset;
    _performanceDropCount = 0; // Reset counter
    
    AppLogger.info('Performance preset set to: ${preset.displayName}',
      component: _logComponent);
  }
  
  /// Set quality level (compatibility method for WebGL service)
  void setQualityLevel(dynamic qualityLevel) {
    // Convert quality level to performance preset
    PerformancePreset preset;
    if (qualityLevel.toString().toLowerCase().contains('low')) {
      preset = PerformancePreset.low;
    } else if (qualityLevel.toString().toLowerCase().contains('medium')) {
      preset = PerformancePreset.medium;
    } else if (qualityLevel.toString().toLowerCase().contains('high')) {
      preset = PerformancePreset.high;
    } else {
      preset = PerformancePreset.medium; // Default to medium
    }
    
    setPerformancePreset(preset);
  }
  
  /// Enable or disable adaptive quality scaling
  void setAdaptiveQualityEnabled(bool enabled) {
    _adaptiveQualityEnabled = enabled;
    
    AppLogger.info('Adaptive quality scaling ${enabled ? 'enabled' : 'disabled'}',
      component: _logComponent);
  }
  
  /// Get device-specific scaling factors for touch sensitivity
  Map<String, double> getTouchScalingFactors() {
    final factors = <String, double>{
      'sensitivity': _touchConfig.sensitivity,
      'deadzone': 0.1,
      'acceleration': 1.0,
    };
    
    // Adjust for device type
    if (_deviceCapabilities.isMobile) {
      if (_deviceCapabilities.isTablet) {
        factors['sensitivity'] = factors['sensitivity']! * 0.8; // Tablets need less sensitivity
        factors['deadzone'] = 0.15;
      } else {
        factors['sensitivity'] = factors['sensitivity']! * 1.2; // Phones need more sensitivity
        factors['deadzone'] = 0.05;
      }
    }
    
    // Adjust for pixel ratio
    if (_deviceCapabilities.pixelRatio > 2.0) {
      factors['sensitivity'] = factors['sensitivity']! * 0.9; // High DPI screens
    }
    
    return factors;
  }
  
  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'currentFPS': _currentFPS,
      'averageFPS': _fpsHistory.isNotEmpty ? _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length : 0,
      'minFPS': _fpsHistory.isNotEmpty ? _fpsHistory.reduce((a, b) => a < b ? a : b) : 0,
      'maxFPS': _fpsHistory.isNotEmpty ? _fpsHistory.reduce((a, b) => a > b ? a : b) : 0,
      'currentMemoryMB': _currentMemoryMB,
      'averageMemoryMB': _memoryHistory.isNotEmpty ? _memoryHistory.reduce((a, b) => a + b) / _memoryHistory.length : 0,
      'currentPreset': _currentPreset.displayName,
      'adaptiveQualityEnabled': _adaptiveQualityEnabled,
      'performanceDropCount': _performanceDropCount,
      'deviceCapabilities': _deviceCapabilities.toMap(),
    };
  }
  
  /// Get current device capabilities
  DeviceCapabilities get deviceCapabilities => _deviceCapabilities;
  
  /// Get current performance preset
  PerformancePreset get currentPreset => _currentPreset;
  
  /// Get touch throttle configuration
  TouchThrottleConfig get touchConfig => _touchConfig;
  
  /// Dispose of resources
  void dispose() {
    // Cancel any active timers
    for (final timer in _touchThrottleTimers.values) {
      timer?.cancel();
    }
    _touchThrottleTimers.clear();
    
    // Clear history
    _fpsHistory.clear();
    _memoryHistory.clear();
    _lastTouchEventTime.clear();
    
    AppLogger.info('Mobile performance optimizer disposed', component: _logComponent);
  }
}