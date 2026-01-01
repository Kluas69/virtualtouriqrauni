import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import '../logging/app_logger.dart';
import '../platform/platform_utils.dart';

/// Memory management service for mobile optimization
/// 
/// This service provides memory-efficient operations, caching strategies,
/// and automatic cleanup to prevent memory leaks and improve performance
/// on mobile devices. Enhanced for 3D model and WebGL resource management.
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, StreamSubscription> _subscriptions = {};
  final Set<String> _activeWebGLContexts = {};
  
  // Memory thresholds for mobile devices
  static const int _maxCacheSize = 50; // Maximum cached items
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const int _maxModelCacheSize = 50 * 1024 * 1024; // 50MB for 3D models
  
  Timer? _cleanupTimer;
  Timer? _webglMonitorTimer;
  bool _isInitialized = false;
  int _webglMemoryUsage = 0;
  
  /// Initialize memory manager with periodic cleanup
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Start periodic cleanup every 5 minutes
      _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        _performCleanup();
      });
      
      // Start WebGL memory monitoring every 30 seconds on mobile
      if (PlatformUtils.isMobile) {
        _webglMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          _monitorWebGLMemory();
        });
        _setupMemoryPressureListener();
      }
      
      _isInitialized = true;
      AppLogger.info('Memory manager initialized',
        component: 'MemoryManager',
        metadata: {
          'platform': PlatformUtils.isMobile ? 'mobile' : 'desktop',
          'maxCacheSize': _maxCacheSize,
          'cacheExpiry': _cacheExpiry.inMinutes,
          'webglMonitoring': PlatformUtils.isMobile,
        });
    } catch (e) {
      AppLogger.error('Failed to initialize memory manager',
        component: 'MemoryManager',
        error: e);
    }
  }
  
  /// Cache data with automatic expiry and size management
  void cache<T>(String key, T data, {Duration? customExpiry}) {
    try {
      // Check cache size and clean if necessary
      if (_cache.length >= _maxCacheSize) {
        _evictOldestEntries();
      }
      
      _cache[key] = data;
      _cacheTimestamps[key] = DateTime.now();
      
      AppLogger.debug('Cached data',
        component: 'MemoryManager',
        metadata: {
          'key': key,
          'cacheSize': _cache.length,
          'dataType': T.toString(),
        });
    } catch (e) {
      AppLogger.warning('Failed to cache data',
        component: 'MemoryManager',
        error: e,
        metadata: {'key': key});
    }
  }
  
  /// Retrieve cached data with expiry check
  T? getCached<T>(String key) {
    try {
      final timestamp = _cacheTimestamps[key];
      if (timestamp == null) return null;
      
      // Check if expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        removeCached(key);
        return null;
      }
      
      final data = _cache[key];
      if (data is T) {
        AppLogger.debug('Cache hit',
          component: 'MemoryManager',
          metadata: {'key': key, 'dataType': T.toString()});
        return data;
      }
      
      return null;
    } catch (e) {
      AppLogger.warning('Failed to retrieve cached data',
        component: 'MemoryManager',
        error: e,
        metadata: {'key': key});
      return null;
    }
  }
  
  /// Remove specific cached item
  void removeCached(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    
    AppLogger.debug('Removed cached item',
      component: 'MemoryManager',
      metadata: {'key': key});
  }
  
  /// Clear all cached data
  void clearCache() {
    final cacheSize = _cache.length;
    _cache.clear();
    _cacheTimestamps.clear();
    
    AppLogger.info('Cleared all cache',
      component: 'MemoryManager',
      metadata: {'clearedItems': cacheSize});
  }
  
  /// Register a WebGL context for monitoring
  void registerWebGLContext(String contextId) {
    _activeWebGLContexts.add(contextId);
    AppLogger.debug('Registered WebGL context',
      component: 'MemoryManager',
      metadata: {'contextId': contextId, 'totalContexts': _activeWebGLContexts.length});
  }
  
  /// Unregister a WebGL context
  void unregisterWebGLContext(String contextId) {
    _activeWebGLContexts.remove(contextId);
    AppLogger.debug('Unregistered WebGL context',
      component: 'MemoryManager',
      metadata: {'contextId': contextId, 'totalContexts': _activeWebGLContexts.length});
  }
  
  /// Monitor WebGL memory usage
  void _monitorWebGLMemory() {
    if (_activeWebGLContexts.isEmpty) return;
    
    try {
      // Estimate WebGL memory usage based on active contexts
      _webglMemoryUsage = _activeWebGLContexts.length * 20 * 1024 * 1024; // Estimate 20MB per context
      
      if (_webglMemoryUsage > _maxModelCacheSize) {
        AppLogger.warning('High WebGL memory usage detected',
          component: 'MemoryManager',
          metadata: {
            'estimatedUsage': _webglMemoryUsage,
            'maxAllowed': _maxModelCacheSize,
            'activeContexts': _activeWebGLContexts.length,
          });
        
        // Trigger aggressive cleanup
        _performAggressiveCleanup();
      }
    } catch (e) {
      AppLogger.warning('WebGL memory monitoring failed',
        component: 'MemoryManager',
        error: e);
    }
  }
  
  /// Perform aggressive cleanup for memory pressure
  void _performAggressiveCleanup() {
    // Clear all non-essential cache
    final nonEssentialKeys = _cache.keys
        .where((key) => !key.startsWith('essential_'))
        .toList();
    
    for (final key in nonEssentialKeys) {
      removeCached(key);
    }
    
    // Cancel non-essential subscriptions
    final nonEssentialSubs = _subscriptions.keys
        .where((key) => !key.startsWith('essential_'))
        .toList();
    
    for (final key in nonEssentialSubs) {
      unregisterSubscription(key);
    }
    
    AppLogger.info('Performed aggressive memory cleanup',
      component: 'MemoryManager',
      metadata: {
        'clearedCacheItems': nonEssentialKeys.length,
        'cancelledSubscriptions': nonEssentialSubs.length,
      });
  }
  
  /// Register a subscription for automatic cleanup
  void registerSubscription(String key, StreamSubscription subscription) {
    // Cancel existing subscription if any
    _subscriptions[key]?.cancel();
    _subscriptions[key] = subscription;
    
    AppLogger.debug('Registered subscription',
      component: 'MemoryManager',
      metadata: {'key': key});
  }
  
  /// Unregister and cancel a subscription
  void unregisterSubscription(String key) {
    final subscription = _subscriptions.remove(key);
    subscription?.cancel();
    
    AppLogger.debug('Unregistered subscription',
      component: 'MemoryManager',
      metadata: {'key': key});
  }
  
  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'cacheSize': _cache.length,
      'maxCacheSize': _maxCacheSize,
      'subscriptions': _subscriptions.length,
      'cacheExpiry': _cacheExpiry.inMinutes,
      'isInitialized': _isInitialized,
      'webglContexts': _activeWebGLContexts.length,
      'estimatedWebGLMemory': _webglMemoryUsage,
      'maxModelCacheSize': _maxModelCacheSize,
    };
  }
  
  /// Perform cleanup of expired items and memory optimization
  void _performCleanup() {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      // Find expired items
      _cacheTimestamps.forEach((key, timestamp) {
        if (now.difference(timestamp) > _cacheExpiry) {
          expiredKeys.add(key);
        }
      });
      
      // Remove expired items
      for (final key in expiredKeys) {
        removeCached(key);
      }
      
      // Force garbage collection on mobile if cache is large
      if (PlatformUtils.isMobile && _cache.length > _maxCacheSize * 0.8) {
        _evictOldestEntries();
      }
      
      if (expiredKeys.isNotEmpty) {
        AppLogger.info('Performed memory cleanup',
          component: 'MemoryManager',
          metadata: {
            'expiredItems': expiredKeys.length,
            'remainingItems': _cache.length,
          });
      }
    } catch (e) {
      AppLogger.error('Memory cleanup failed',
        component: 'MemoryManager',
        error: e);
    }
  }
  
  /// Evict oldest cache entries when limit is reached
  void _evictOldestEntries() {
    final entries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final toRemove = entries.take(_maxCacheSize ~/ 4).map((e) => e.key).toList();
    
    for (final key in toRemove) {
      removeCached(key);
    }
    
    AppLogger.debug('Evicted oldest cache entries',
      component: 'MemoryManager',
      metadata: {'evictedCount': toRemove.length});
  }
  
  /// Setup memory pressure listener for mobile platforms
  void _setupMemoryPressureListener() {
    try {
      // Listen for memory pressure warnings
      SystemChannels.system.setMessageHandler((message) async {
        try {
          if (message != null && message is Map && message['type'] == 'memoryPressure') {
            AppLogger.warning('Memory pressure detected, performing cleanup',
              component: 'MemoryManager');
            
            // Aggressive cleanup on memory pressure
            _performAggressiveCleanup();
            
            // Clear WebGL contexts if memory pressure is severe
            if (_webglMemoryUsage > _maxModelCacheSize * 0.8) {
              AppLogger.warning('Severe memory pressure, clearing WebGL contexts',
                component: 'MemoryManager');
              _activeWebGLContexts.clear();
            }
          }
        } catch (e) {
          AppLogger.warning('Error handling memory pressure message',
            component: 'MemoryManager',
            error: e);
        }
        return null;
      });
    } catch (e) {
      AppLogger.warning('Failed to setup memory pressure listener',
        component: 'MemoryManager',
        error: e);
    }
  }
  
  /// Dispose of all resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    _webglMonitorTimer?.cancel();
    _webglMonitorTimer = null;
    
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Clear WebGL contexts
    _activeWebGLContexts.clear();
    _webglMemoryUsage = 0;
    
    clearCache();
    _isInitialized = false;
    
    AppLogger.info('Memory manager disposed',
      component: 'MemoryManager');
  }
}

/// Memory-efficient image cache configuration
class ImageCacheConfig {
  static const int _maxImageCacheSize = 100 * 1024 * 1024; // 100MB for images
  
  static void configure() {
    if (PlatformUtils.isMobile) {
      // Optimize for mobile devices
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = _maxImageCacheSize;
    } else {
      // More generous limits for desktop
      PaintingBinding.instance.imageCache.maximumSize = 200;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;
    }
    
    AppLogger.info('Image cache configured',
      component: 'ImageCacheConfig',
      metadata: {
        'maxSize': PaintingBinding.instance.imageCache.maximumSize,
        'maxSizeBytes': PaintingBinding.instance.imageCache.maximumSizeBytes,
        'platform': PlatformUtils.isMobile ? 'mobile' : 'desktop',
      });
  }
}