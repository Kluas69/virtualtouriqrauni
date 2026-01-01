import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../logging/app_logger.dart';
import '../memory/memory_manager.dart';
import '../platform/platform_utils.dart';

/// Professional 3D-specific memory manager extending the base memory manager
/// 
/// This manager provides advanced memory management for 3D models, textures,
/// geometries, materials, and WebGL resources with object pooling, LRU caching,
/// and mobile-optimized memory budgets.
class MemoryManager3D {
  static final MemoryManager3D _instance = MemoryManager3D._internal();
  factory MemoryManager3D() => _instance;
  MemoryManager3D._internal();

  final MemoryManager _baseManager = MemoryManager();
  
  // Object pools for reusable 3D resources
  final Queue<Map<String, dynamic>> _geometryPool = Queue();
  final Queue<Map<String, dynamic>> _materialPool = Queue();
  final Queue<Map<String, dynamic>> _texturePool = Queue();
  
  // LRU caches for active resources
  final LinkedHashMap<String, _TextureCacheEntry> _textureCache = LinkedHashMap();
  final LinkedHashMap<String, _GeometryCacheEntry> _geometryCache = LinkedHashMap();
  final LinkedHashMap<String, _MaterialCacheEntry> _materialCache = LinkedHashMap();
  
  // Memory tracking
  int _currentTextureMemory = 0;
  int _currentGeometryMemory = 0;
  int _currentMaterialMemory = 0;
  // WebGL resource tracking
  final Map<String, _WebGLResourceEntry> _webglResources = {};
  int _totalWebGLResources = 0;
  int _totalWebGLMemory = 0;
  
  // Memory budgets (bytes)
  late final int _maxTextureMemory;
  late final int _maxGeometryMemory;
  late final int _maxMaterialMemory;
  late final int _maxTotalMemory;
  
  // Pool limits
  static const int _maxGeometryPoolSize = 50;
  static const int _maxMaterialPoolSize = 100;
  static const int _maxTexturePoolSize = 30;
  
  // Cache limits
  late final int _maxTextureCacheSize;
  late final int _maxGeometryCacheSize;
  late final int _maxMaterialCacheSize;
  
  Timer? _memoryMonitorTimer;
  bool _isInitialized = false;
  bool _isMemoryPressure = false;
  
  /// Initialize 3D memory manager with device-specific budgets
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize base memory manager first
      await _baseManager.initialize();
      
      // Set memory budgets based on platform
      _setMemoryBudgets();
      
      // Start memory monitoring
      _memoryMonitorTimer = Timer.periodic(
        Duration(seconds: PlatformUtils.isMobile ? 15 : 30),
        (_) => _monitorMemoryUsage(),
      );
      
      _isInitialized = true;
      
      AppLogger.info('3D Memory Manager initialized',
        component: 'MemoryManager3D',
        metadata: {
          'platform': PlatformUtils.isMobile ? 'mobile' : 'desktop',
          'maxTextureMemory': '${(_maxTextureMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'maxGeometryMemory': '${(_maxGeometryMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'maxMaterialMemory': '${(_maxMaterialMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'maxTotalMemory': '${(_maxTotalMemory / 1024 / 1024).toStringAsFixed(1)}MB',
        });
    } catch (e) {
      AppLogger.error('Failed to initialize 3D memory manager',
        component: 'MemoryManager3D',
        error: e);
    }
  }
  
  /// Set memory budgets based on device capabilities
  void _setMemoryBudgets() {
    if (PlatformUtils.isMobile) {
      // Conservative mobile budgets
      _maxTextureMemory = 50 * 1024 * 1024;  // 50MB
      _maxGeometryMemory = 20 * 1024 * 1024; // 20MB
      _maxMaterialMemory = 10 * 1024 * 1024; // 10MB
      _maxTotalMemory = 100 * 1024 * 1024;   // 100MB total
      
      _maxTextureCacheSize = 20;
      _maxGeometryCacheSize = 30;
      _maxMaterialCacheSize = 50;
    } else {
      // More generous desktop budgets
      _maxTextureMemory = 200 * 1024 * 1024; // 200MB
      _maxGeometryMemory = 100 * 1024 * 1024; // 100MB
      _maxMaterialMemory = 50 * 1024 * 1024;  // 50MB
      _maxTotalMemory = 400 * 1024 * 1024;    // 400MB total
      
      _maxTextureCacheSize = 50;
      _maxGeometryCacheSize = 100;
      _maxMaterialCacheSize = 150;
    }
  }
  
  /// Cache texture with LRU eviction policy
  void cacheTexture(String key, Map<String, dynamic> textureData, int estimatedSize) {
    try {
      // Check if we need to evict textures
      while (_textureCache.length >= _maxTextureCacheSize || 
             _currentTextureMemory + estimatedSize > _maxTextureMemory) {
        _evictOldestTexture();
      }
      
      // Remove existing entry if present
      if (_textureCache.containsKey(key)) {
        final existing = _textureCache.remove(key)!;
        _currentTextureMemory -= existing.estimatedSize;
      }
      
      // Add new entry
      final entry = _TextureCacheEntry(
        data: textureData,
        estimatedSize: estimatedSize,
        lastAccessed: DateTime.now(),
        accessCount: 1,
      );
      
      _textureCache[key] = entry;
      _currentTextureMemory += estimatedSize;
      
      AppLogger.debug('Cached texture',
        component: 'MemoryManager3D',
        metadata: {
          'key': key,
          'size': '${(estimatedSize / 1024).toStringAsFixed(1)}KB',
          'totalTextures': _textureCache.length,
          'totalTextureMemory': '${(_currentTextureMemory / 1024 / 1024).toStringAsFixed(1)}MB',
        });
    } catch (e) {
      AppLogger.warning('Failed to cache texture',
        component: 'MemoryManager3D',
        error: e,
        metadata: {'key': key});
    }
  }
  
  /// Get cached texture with LRU update
  Map<String, dynamic>? getCachedTexture(String key) {
    final entry = _textureCache[key];
    if (entry == null) return null;
    
    // Update LRU
    entry.lastAccessed = DateTime.now();
    entry.accessCount++;
    
    // Move to end (most recently used)
    _textureCache.remove(key);
    _textureCache[key] = entry;
    
    AppLogger.debug('Texture cache hit',
      component: 'MemoryManager3D',
      metadata: {
        'key': key,
        'accessCount': entry.accessCount,
      });
    
    return entry.data;
  }
  
  /// Cache geometry with memory management
  void cacheGeometry(String key, Map<String, dynamic> geometryData, int estimatedSize) {
    try {
      // Check if we need to evict geometries
      while (_geometryCache.length >= _maxGeometryCacheSize || 
             _currentGeometryMemory + estimatedSize > _maxGeometryMemory) {
        _evictOldestGeometry();
      }
      
      // Remove existing entry if present
      if (_geometryCache.containsKey(key)) {
        final existing = _geometryCache.remove(key)!;
        _currentGeometryMemory -= existing.estimatedSize;
      }
      
      // Add new entry
      final entry = _GeometryCacheEntry(
        data: geometryData,
        estimatedSize: estimatedSize,
        lastAccessed: DateTime.now(),
        accessCount: 1,
      );
      
      _geometryCache[key] = entry;
      _currentGeometryMemory += estimatedSize;
      
      AppLogger.debug('Cached geometry',
        component: 'MemoryManager3D',
        metadata: {
          'key': key,
          'size': '${(estimatedSize / 1024).toStringAsFixed(1)}KB',
          'totalGeometries': _geometryCache.length,
          'totalGeometryMemory': '${(_currentGeometryMemory / 1024 / 1024).toStringAsFixed(1)}MB',
        });
    } catch (e) {
      AppLogger.warning('Failed to cache geometry',
        component: 'MemoryManager3D',
        error: e,
        metadata: {'key': key});
    }
  }
  
  /// Get cached geometry with LRU update
  Map<String, dynamic>? getCachedGeometry(String key) {
    final entry = _geometryCache[key];
    if (entry == null) return null;
    
    // Update LRU
    entry.lastAccessed = DateTime.now();
    entry.accessCount++;
    
    // Move to end (most recently used)
    _geometryCache.remove(key);
    _geometryCache[key] = entry;
    
    AppLogger.debug('Geometry cache hit',
      component: 'MemoryManager3D',
      metadata: {
        'key': key,
        'accessCount': entry.accessCount,
      });
    
    return entry.data;
  }
  
  /// Cache material with memory management
  void cacheMaterial(String key, Map<String, dynamic> materialData, int estimatedSize) {
    try {
      // Check if we need to evict materials
      while (_materialCache.length >= _maxMaterialCacheSize || 
             _currentMaterialMemory + estimatedSize > _maxMaterialMemory) {
        _evictOldestMaterial();
      }
      
      // Remove existing entry if present
      if (_materialCache.containsKey(key)) {
        final existing = _materialCache.remove(key)!;
        _currentMaterialMemory -= existing.estimatedSize;
      }
      
      // Add new entry
      final entry = _MaterialCacheEntry(
        data: materialData,
        estimatedSize: estimatedSize,
        lastAccessed: DateTime.now(),
        accessCount: 1,
      );
      
      _materialCache[key] = entry;
      _currentMaterialMemory += estimatedSize;
      
      AppLogger.debug('Cached material',
        component: 'MemoryManager3D',
        metadata: {
          'key': key,
          'size': '${(estimatedSize / 1024).toStringAsFixed(1)}KB',
          'totalMaterials': _materialCache.length,
          'totalMaterialMemory': '${(_currentMaterialMemory / 1024 / 1024).toStringAsFixed(1)}MB',
        });
    } catch (e) {
      AppLogger.warning('Failed to cache material',
        component: 'MemoryManager3D',
        error: e,
        metadata: {'key': key});
    }
  }
  
  /// Get cached material with LRU update
  Map<String, dynamic>? getCachedMaterial(String key) {
    final entry = _materialCache[key];
    if (entry == null) return null;
    
    // Update LRU
    entry.lastAccessed = DateTime.now();
    entry.accessCount++;
    
    // Move to end (most recently used)
    _materialCache.remove(key);
    _materialCache[key] = entry;
    
    AppLogger.debug('Material cache hit',
      component: 'MemoryManager3D',
      metadata: {
        'key': key,
        'accessCount': entry.accessCount,
      });
    
    return entry.data;
  }
  
  /// Get pooled geometry or create new one
  Map<String, dynamic> getPooledGeometry() {
    if (_geometryPool.isNotEmpty) {
      final geometry = _geometryPool.removeFirst();
      AppLogger.debug('Reused pooled geometry',
        component: 'MemoryManager3D',
        metadata: {'poolSize': _geometryPool.length});
      return geometry;
    }
    
    // Create new geometry placeholder
    return {
      'type': 'geometry',
      'id': 'geo_${DateTime.now().millisecondsSinceEpoch}',
      'vertices': <double>[],
      'indices': <int>[],
      'normals': <double>[],
      'uvs': <double>[],
    };
  }
  
  /// Return geometry to pool for reuse
  void returnGeometryToPool(Map<String, dynamic> geometry) {
    if (_geometryPool.length >= _maxGeometryPoolSize) {
      AppLogger.debug('Geometry pool full, discarding geometry',
        component: 'MemoryManager3D');
      return;
    }
    
    // Clear geometry data for reuse
    geometry['vertices'] = <double>[];
    geometry['indices'] = <int>[];
    geometry['normals'] = <double>[];
    geometry['uvs'] = <double>[];
    
    _geometryPool.add(geometry);
    
    AppLogger.debug('Returned geometry to pool',
      component: 'MemoryManager3D',
      metadata: {'poolSize': _geometryPool.length});
  }
  
  /// Get pooled material or create new one
  Map<String, dynamic> getPooledMaterial() {
    if (_materialPool.isNotEmpty) {
      final material = _materialPool.removeFirst();
      AppLogger.debug('Reused pooled material',
        component: 'MemoryManager3D',
        metadata: {'poolSize': _materialPool.length});
      return material;
    }
    
    // Create new material placeholder
    return {
      'type': 'material',
      'id': 'mat_${DateTime.now().millisecondsSinceEpoch}',
      'color': 0xffffff,
      'opacity': 1.0,
      'transparent': false,
      'textures': <String, dynamic>{},
    };
  }
  
  /// Return material to pool for reuse
  void returnMaterialToPool(Map<String, dynamic> material) {
    if (_materialPool.length >= _maxMaterialPoolSize) {
      AppLogger.debug('Material pool full, discarding material',
        component: 'MemoryManager3D');
      return;
    }
    
    // Reset material properties for reuse
    material['color'] = 0xffffff;
    material['opacity'] = 1.0;
    material['transparent'] = false;
    material['textures'] = <String, dynamic>{};
    
    _materialPool.add(material);
    
    AppLogger.debug('Returned material to pool',
      component: 'MemoryManager3D',
      metadata: {'poolSize': _materialPool.length});
  }
  
  /// Get pooled texture or create new one
  Map<String, dynamic> getPooledTexture() {
    if (_texturePool.isNotEmpty) {
      final texture = _texturePool.removeFirst();
      AppLogger.debug('Reused pooled texture',
        component: 'MemoryManager3D',
        metadata: {'poolSize': _texturePool.length});
      return texture;
    }
    
    // Create new texture placeholder
    return {
      'type': 'texture',
      'id': 'tex_${DateTime.now().millisecondsSinceEpoch}',
      'width': 0,
      'height': 0,
      'format': 'RGBA',
      'data': null,
    };
  }
  
  /// Return texture to pool for reuse
  void returnTextureToPool(Map<String, dynamic> texture) {
    if (_texturePool.length >= _maxTexturePoolSize) {
      AppLogger.debug('Texture pool full, discarding texture',
        component: 'MemoryManager3D');
      return;
    }
    
    // Clear texture data for reuse
    texture['width'] = 0;
    texture['height'] = 0;
    texture['data'] = null;
    
    _texturePool.add(texture);
    
    AppLogger.debug('Returned texture to pool',
      component: 'MemoryManager3D',
      metadata: {'poolSize': _texturePool.length});
  }
  
  /// Register WebGL resource for tracking with detailed information
  void registerWebGLResource(String resourceId, String resourceType, int estimatedSize, {
    Map<String, dynamic>? metadata,
  }) {
    final entry = _WebGLResourceEntry(
      id: resourceId,
      type: resourceType,
      estimatedSize: estimatedSize,
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
      accessCount: 1,
      metadata: metadata ?? {},
    );
    
    _webglResources[resourceId] = entry;
    _totalWebGLResources++;
    _totalWebGLMemory += estimatedSize;
    _baseManager.registerWebGLContext(resourceId);
    
    AppLogger.debug('Registered WebGL resource',
      component: 'MemoryManager3D',
      metadata: {
        'resourceId': resourceId,
        'type': resourceType,
        'size': '${(estimatedSize / 1024).toStringAsFixed(1)}KB',
        'totalResources': _totalWebGLResources,
        'totalMemory': '${(_totalWebGLMemory / 1024 / 1024).toStringAsFixed(1)}MB',
      });
    
    // Trigger cleanup if memory usage is too high
    if (_totalWebGLMemory > _maxTotalMemory * 0.9) {
      _performWebGLCleanup();
    }
  }
  
  /// Update WebGL resource access tracking
  void accessWebGLResource(String resourceId) {
    final entry = _webglResources[resourceId];
    if (entry != null) {
      entry.lastAccessed = DateTime.now();
      entry.accessCount++;
      
      AppLogger.debug('Accessed WebGL resource',
        component: 'MemoryManager3D',
        metadata: {
          'resourceId': resourceId,
          'accessCount': entry.accessCount,
          'type': entry.type,
        });
    }
  }
  
  /// Unregister WebGL resource with cleanup
  void unregisterWebGLResource(String resourceId) {
    final entry = _webglResources.remove(resourceId);
    if (entry != null) {
      _totalWebGLResources = math.max(0, _totalWebGLResources - 1);
      _totalWebGLMemory = math.max(0, _totalWebGLMemory - entry.estimatedSize);
      _baseManager.unregisterWebGLContext(resourceId);
      
      AppLogger.debug('Unregistered WebGL resource',
        component: 'MemoryManager3D',
        metadata: {
          'resourceId': resourceId,
          'type': entry.type,
          'size': '${(entry.estimatedSize / 1024).toStringAsFixed(1)}KB',
          'lifespan': '${DateTime.now().difference(entry.createdAt).inSeconds}s',
          'totalAccesses': entry.accessCount,
          'remainingResources': _totalWebGLResources,
        });
    }
  }
  
  /// Perform WebGL resource cleanup based on usage patterns
  void _performWebGLCleanup() {
    AppLogger.warning('Performing WebGL resource cleanup',
      component: 'MemoryManager3D',
      metadata: {
        'totalResources': _totalWebGLResources,
        'totalMemory': '${(_totalWebGLMemory / 1024 / 1024).toStringAsFixed(1)}MB',
      });
    
    // Find least recently used resources
    final sortedResources = _webglResources.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    // Remove oldest 25% of resources
    final resourcesToRemove = (sortedResources.length * 0.25).ceil();
    int removedCount = 0;
    int freedMemory = 0;
    
    for (int i = 0; i < resourcesToRemove && i < sortedResources.length; i++) {
      final entry = sortedResources[i];
      freedMemory += entry.value.estimatedSize;
      unregisterWebGLResource(entry.key);
      removedCount++;
    }
    
    AppLogger.info('WebGL resource cleanup completed',
      component: 'MemoryManager3D',
      metadata: {
        'removedResources': removedCount,
        'freedMemory': '${(freedMemory / 1024 / 1024).toStringAsFixed(1)}MB',
        'remainingResources': _totalWebGLResources,
        'remainingMemory': '${(_totalWebGLMemory / 1024 / 1024).toStringAsFixed(1)}MB',
      });
  }
  
  /// Get WebGL resource statistics
  Map<String, dynamic> getWebGLResourceStats() {
    final resourcesByType = <String, int>{};
    final memoryByType = <String, int>{};
    int totalAccesses = 0;
    
    for (final entry in _webglResources.values) {
      resourcesByType[entry.type] = (resourcesByType[entry.type] ?? 0) + 1;
      memoryByType[entry.type] = (memoryByType[entry.type] ?? 0) + entry.estimatedSize;
      totalAccesses += entry.accessCount;
    }
    
    return {
      'totalResources': _totalWebGLResources,
      'totalMemory': _totalWebGLMemory,
      'resourcesByType': resourcesByType,
      'memoryByType': memoryByType,
      'totalAccesses': totalAccesses,
      'averageAccessesPerResource': _totalWebGLResources > 0 ? totalAccesses / _totalWebGLResources : 0,
      'oldestResourceAge': _getOldestWebGLResourceAge(),
      'memoryUsagePercent': (_totalWebGLMemory / _maxTotalMemory * 100).round(),
    };
  }
  
  /// Get age of oldest WebGL resource (in minutes)
  int _getOldestWebGLResourceAge() {
    if (_webglResources.isEmpty) return 0;
    
    final oldestTime = _webglResources.values
        .map((entry) => entry.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    
    return DateTime.now().difference(oldestTime).inMinutes;
  }
  
  /// Force garbage collection for WebGL resources
  void forceWebGLGarbageCollection() {
    AppLogger.info('Forcing WebGL garbage collection',
      component: 'MemoryManager3D',
      metadata: {
        'resourcesBeforeGC': _totalWebGLResources,
        'memoryBeforeGC': '${(_totalWebGLMemory / 1024 / 1024).toStringAsFixed(1)}MB',
      });
    
    // Remove all resources that haven't been accessed in the last 5 minutes
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 5));
    final resourcesToRemove = <String>[];
    
    for (final entry in _webglResources.entries) {
      if (entry.value.lastAccessed.isBefore(cutoffTime)) {
        resourcesToRemove.add(entry.key);
      }
    }
    
    for (final resourceId in resourcesToRemove) {
      unregisterWebGLResource(resourceId);
    }
    
    AppLogger.info('WebGL garbage collection completed',
      component: 'MemoryManager3D',
      metadata: {
        'removedResources': resourcesToRemove.length,
        'remainingResources': _totalWebGLResources,
        'remainingMemory': '${(_totalWebGLMemory / 1024 / 1024).toStringAsFixed(1)}MB',
      });
  }
  
  /// Monitor memory usage and trigger cleanup if needed
  void _monitorMemoryUsage() {
    try {
      final totalMemory = _currentTextureMemory + _currentGeometryMemory + _currentMaterialMemory;
      final memoryUsagePercent = (totalMemory / _maxTotalMemory * 100).round();
      
      AppLogger.debug('3D Memory usage',
        component: 'MemoryManager3D',
        metadata: {
          'totalMemory': '${(totalMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'maxMemory': '${(_maxTotalMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'usagePercent': '$memoryUsagePercent%',
          'textureMemory': '${(_currentTextureMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'geometryMemory': '${(_currentGeometryMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'materialMemory': '${(_currentMaterialMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'webglResources': _totalWebGLResources,
        });
      
      // Trigger cleanup if memory usage is high
      if (memoryUsagePercent > 80) {
        AppLogger.warning('High 3D memory usage detected, triggering cleanup',
          component: 'MemoryManager3D',
          metadata: {'usagePercent': '$memoryUsagePercent%'});
        
        _performMemoryCleanup();
      }
      
      // Set memory pressure flag
      _isMemoryPressure = memoryUsagePercent > 90;
      
    } catch (e) {
      AppLogger.warning('3D memory monitoring failed',
        component: 'MemoryManager3D',
        error: e);
    }
  }
  
  /// Perform memory cleanup by evicting least recently used items
  void _performMemoryCleanup() {
    final initialMemory = _currentTextureMemory + _currentGeometryMemory + _currentMaterialMemory;
    
    // Evict 25% of cached items
    final texturesToEvict = (_textureCache.length * 0.25).ceil();
    final geometriesToEvict = (_geometryCache.length * 0.25).ceil();
    final materialsToEvict = (_materialCache.length * 0.25).ceil();
    
    for (int i = 0; i < texturesToEvict; i++) {
      _evictOldestTexture();
    }
    
    for (int i = 0; i < geometriesToEvict; i++) {
      _evictOldestGeometry();
    }
    
    for (int i = 0; i < materialsToEvict; i++) {
      _evictOldestMaterial();
    }
    
    final finalMemory = _currentTextureMemory + _currentGeometryMemory + _currentMaterialMemory;
    final freedMemory = initialMemory - finalMemory;
    
    AppLogger.info('3D memory cleanup completed',
      component: 'MemoryManager3D',
      metadata: {
        'freedMemory': '${(freedMemory / 1024 / 1024).toStringAsFixed(1)}MB',
        'remainingMemory': '${(finalMemory / 1024 / 1024).toStringAsFixed(1)}MB',
        'texturesEvicted': texturesToEvict,
        'geometriesEvicted': geometriesToEvict,
        'materialsEvicted': materialsToEvict,
      });
  }
  
  /// Evict oldest texture from cache
  void _evictOldestTexture() {
    if (_textureCache.isEmpty) return;
    
    final oldestKey = _textureCache.keys.first;
    final entry = _textureCache.remove(oldestKey)!;
    _currentTextureMemory -= entry.estimatedSize;
    
    AppLogger.debug('Evicted texture from cache',
      component: 'MemoryManager3D',
      metadata: {
        'key': oldestKey,
        'size': '${(entry.estimatedSize / 1024).toStringAsFixed(1)}KB',
        'accessCount': entry.accessCount,
      });
  }
  
  /// Evict oldest geometry from cache
  void _evictOldestGeometry() {
    if (_geometryCache.isEmpty) return;
    
    final oldestKey = _geometryCache.keys.first;
    final entry = _geometryCache.remove(oldestKey)!;
    _currentGeometryMemory -= entry.estimatedSize;
    
    AppLogger.debug('Evicted geometry from cache',
      component: 'MemoryManager3D',
      metadata: {
        'key': oldestKey,
        'size': '${(entry.estimatedSize / 1024).toStringAsFixed(1)}KB',
        'accessCount': entry.accessCount,
      });
  }
  
  /// Evict oldest material from cache
  void _evictOldestMaterial() {
    if (_materialCache.isEmpty) return;
    
    final oldestKey = _materialCache.keys.first;
    final entry = _materialCache.remove(oldestKey)!;
    _currentMaterialMemory -= entry.estimatedSize;
    
    AppLogger.debug('Evicted material from cache',
      component: 'MemoryManager3D',
      metadata: {
        'key': oldestKey,
        'size': '${(entry.estimatedSize / 1024).toStringAsFixed(1)}KB',
        'accessCount': entry.accessCount,
      });
  }
  
  /// Automatic texture cleanup on memory pressure
  void triggerTextureCleanup() {
    if (_isMemoryPressure || _currentTextureMemory > _maxTextureMemory * 0.8) {
      AppLogger.warning('Triggering automatic texture cleanup due to memory pressure',
        component: 'MemoryManager3D',
        metadata: {
          'currentTextureMemory': '${(_currentTextureMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'maxTextureMemory': '${(_maxTextureMemory / 1024 / 1024).toStringAsFixed(1)}MB',
          'isMemoryPressure': _isMemoryPressure,
        });
      
      // Evict 50% of textures when under pressure
      final texturesToEvict = (_textureCache.length * 0.5).ceil();
      for (int i = 0; i < texturesToEvict; i++) {
        _evictOldestTexture();
      }
      
      // Clear texture pool to free memory
      _texturePool.clear();
      
      AppLogger.info('Automatic texture cleanup completed',
        component: 'MemoryManager3D',
        metadata: {
          'texturesEvicted': texturesToEvict,
          'remainingTextures': _textureCache.length,
          'freedMemory': '${(texturesToEvict * 2048 / 1024).toStringAsFixed(1)}KB', // Estimate
        });
    }
  }
  
  /// Estimate texture memory usage based on dimensions and format
  static int estimateTextureMemory(int width, int height, String format) {
    int bytesPerPixel;
    switch (format.toUpperCase()) {
      case 'RGBA':
        bytesPerPixel = 4;
        break;
      case 'RGB':
        bytesPerPixel = 3;
        break;
      case 'LUMINANCE_ALPHA':
        bytesPerPixel = 2;
        break;
      case 'LUMINANCE':
      case 'ALPHA':
        bytesPerPixel = 1;
        break;
      case 'DXT1':
      case 'ETC1':
        return (width * height) ~/ 2; // Compressed format
      case 'DXT5':
      case 'ETC2':
      case 'ASTC':
        return width * height; // Compressed format
      default:
        bytesPerPixel = 4; // Default to RGBA
    }
    
    return width * height * bytesPerPixel;
  }
  
  /// Get texture cache statistics
  Map<String, dynamic> getTextureCacheStats() {
    final totalTextures = _textureCache.length;
    final averageSize = totalTextures > 0 ? _currentTextureMemory / totalTextures : 0;
    
    // Calculate access frequency statistics
    final accessCounts = _textureCache.values.map((entry) => entry.accessCount).toList();
    accessCounts.sort();
    
    final medianAccess = accessCounts.isNotEmpty 
        ? accessCounts[accessCounts.length ~/ 2] 
        : 0;
    
    return {
      'totalTextures': totalTextures,
      'totalMemoryUsed': _currentTextureMemory,
      'totalMemoryLimit': _maxTextureMemory,
      'averageTextureSize': averageSize.round(),
      'memoryUsagePercent': (_currentTextureMemory / _maxTextureMemory * 100).round(),
      'cacheHitRate': _calculateCacheHitRate(),
      'medianAccessCount': medianAccess,
      'oldestTextureAge': _getOldestTextureAge(),
      'poolSize': _texturePool.length,
    };
  }
  
  /// Calculate cache hit rate (simplified estimation)
  double _calculateCacheHitRate() {
    if (_textureCache.isEmpty) return 0.0;
    
    final totalAccesses = _textureCache.values
        .map((entry) => entry.accessCount)
        .reduce((a, b) => a + b);
    
    // Estimate hit rate based on access patterns
    // More accessed textures indicate better cache performance
    return (totalAccesses / (_textureCache.length * 2)).clamp(0.0, 1.0);
  }
  
  /// Get age of oldest texture in cache (in minutes)
  int _getOldestTextureAge() {
    if (_textureCache.isEmpty) return 0;
    
    final oldestTime = _textureCache.values
        .map((entry) => entry.lastAccessed)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    
    return DateTime.now().difference(oldestTime).inMinutes;
  }
  
  /// Preload textures with priority
  Future<void> preloadTextures(List<Map<String, dynamic>> textureSpecs) async {
    AppLogger.info('Starting texture preloading',
      component: 'MemoryManager3D',
      metadata: {'textureCount': textureSpecs.length});
    
    // Sort by priority (higher priority first)
    textureSpecs.sort((a, b) => (b['priority'] ?? 0).compareTo(a['priority'] ?? 0));
    
    for (final spec in textureSpecs) {
      try {
        final key = spec['key'] as String;
        final width = spec['width'] as int? ?? 512;
        final height = spec['height'] as int? ?? 512;
        final format = spec['format'] as String? ?? 'RGBA';
        
        // Check if we have memory budget for this texture
        final estimatedSize = estimateTextureMemory(width, height, format);
        if (_currentTextureMemory + estimatedSize > _maxTextureMemory) {
          AppLogger.warning('Skipping texture preload due to memory limit',
            component: 'MemoryManager3D',
            metadata: {
              'textureKey': key,
              'estimatedSize': '${(estimatedSize / 1024).toStringAsFixed(1)}KB',
            });
          continue;
        }
        
        // Create placeholder texture data
        final textureData = {
          'width': width,
          'height': height,
          'format': format,
          'data': null, // Will be loaded later
          'priority': spec['priority'] ?? 0,
          'preloaded': true,
        };
        
        cacheTexture(key, textureData, estimatedSize);
        
        AppLogger.debug('Preloaded texture',
          component: 'MemoryManager3D',
          metadata: {
            'key': key,
            'size': '${(estimatedSize / 1024).toStringAsFixed(1)}KB',
            'priority': spec['priority'] ?? 0,
          });
        
      } catch (e) {
        AppLogger.warning('Failed to preload texture',
          component: 'MemoryManager3D',
          error: e,
          metadata: {'textureSpec': spec});
      }
    }
    
    AppLogger.info('Texture preloading completed',
      component: 'MemoryManager3D',
      metadata: {
        'totalTextures': _textureCache.length,
        'totalMemory': '${(_currentTextureMemory / 1024 / 1024).toStringAsFixed(1)}MB',
      });
  }
  Map<String, dynamic> getMemoryStats() {
    final totalMemory = _currentTextureMemory + _currentGeometryMemory + _currentMaterialMemory;
    
    return {
      'isInitialized': _isInitialized,
      'isMemoryPressure': _isMemoryPressure,
      'totalMemoryUsed': totalMemory,
      'totalMemoryLimit': _maxTotalMemory,
      'memoryUsagePercent': (totalMemory / _maxTotalMemory * 100).round(),
      
      // Texture stats
      'textureMemoryUsed': _currentTextureMemory,
      'textureMemoryLimit': _maxTextureMemory,
      'textureCacheSize': _textureCache.length,
      'textureCacheLimit': _maxTextureCacheSize,
      'texturePoolSize': _texturePool.length,
      
      // Geometry stats
      'geometryMemoryUsed': _currentGeometryMemory,
      'geometryMemoryLimit': _maxGeometryMemory,
      'geometryCacheSize': _geometryCache.length,
      'geometryCacheLimit': _maxGeometryCacheSize,
      'geometryPoolSize': _geometryPool.length,
      
      // Material stats
      'materialMemoryUsed': _currentMaterialMemory,
      'materialMemoryLimit': _maxMaterialMemory,
      'materialCacheSize': _materialCache.length,
      'materialCacheLimit': _maxMaterialCacheSize,
      'materialPoolSize': _materialPool.length,
      
      // WebGL stats
      'totalWebGLResources': _totalWebGLResources,
      
      // Base manager stats
      'baseManagerStats': _baseManager.getMemoryStats(),
    };
  }
  
  /// Force garbage collection and cleanup
  void forceCleanup() {
    AppLogger.info('Forcing 3D memory cleanup',
      component: 'MemoryManager3D');
    
    _performMemoryCleanup();
    
    // Clear pools if memory pressure is high
    if (_isMemoryPressure) {
      _geometryPool.clear();
      _materialPool.clear();
      _texturePool.clear();
      
      AppLogger.info('Cleared all object pools due to memory pressure',
        component: 'MemoryManager3D');
    }
  }
  
  /// Dispose of all resources
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    
    // Clear all caches
    _textureCache.clear();
    _geometryCache.clear();
    _materialCache.clear();
    
    // Clear all pools
    _geometryPool.clear();
    _materialPool.clear();
    _texturePool.clear();
    
    // Reset counters
    _currentTextureMemory = 0;
    _currentGeometryMemory = 0;
    _currentMaterialMemory = 0;
    
    _isInitialized = false;
    _isMemoryPressure = false;
    
    AppLogger.info('3D Memory Manager disposed',
      component: 'MemoryManager3D');
  }
}

/// Cache entry for textures with LRU tracking
class _TextureCacheEntry {
  final Map<String, dynamic> data;
  final int estimatedSize;
  DateTime lastAccessed;
  int accessCount;
  
  _TextureCacheEntry({
    required this.data,
    required this.estimatedSize,
    required this.lastAccessed,
    required this.accessCount,
  });
}

/// Cache entry for geometries with LRU tracking
class _GeometryCacheEntry {
  final Map<String, dynamic> data;
  final int estimatedSize;
  DateTime lastAccessed;
  int accessCount;
  
  _GeometryCacheEntry({
    required this.data,
    required this.estimatedSize,
    required this.lastAccessed,
    required this.accessCount,
  });
}

/// Cache entry for materials with LRU tracking
class _MaterialCacheEntry {
  final Map<String, dynamic> data;
  final int estimatedSize;
  DateTime lastAccessed;
  int accessCount;
  
  _MaterialCacheEntry({
    required this.data,
    required this.estimatedSize,
    required this.lastAccessed,
    required this.accessCount,
  });
}

/// WebGL resource entry for detailed tracking
class _WebGLResourceEntry {
  final String id;
  final String type;
  final int estimatedSize;
  final DateTime createdAt;
  DateTime lastAccessed;
  int accessCount;
  final Map<String, dynamic> metadata;
  
  _WebGLResourceEntry({
    required this.id,
    required this.type,
    required this.estimatedSize,
    required this.createdAt,
    required this.lastAccessed,
    required this.accessCount,
    required this.metadata,
  });
}