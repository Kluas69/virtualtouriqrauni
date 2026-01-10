import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../logging/app_logger.dart';
import '../memory/memory_manager.dart';
import '../platform/platform_utils.dart';

/// Unified asset management system that consolidates AppAssets and AssetManager
/// Provides comprehensive asset loading, caching, and optimization with centralized paths
class UnifiedAssetManager {
  static final UnifiedAssetManager _instance = UnifiedAssetManager._internal();
  factory UnifiedAssetManager() => _instance;
  UnifiedAssetManager._internal();
  
  static const String _logComponent = 'UnifiedAssetManager';
  
  final MemoryManager _memoryManager = MemoryManager();
  final Map<String, Completer<dynamic>> _loadingAssets = {};
  
  bool _isInitialized = false;

  // Base paths
  static const String _imagesPath = 'lib/images/';
  static const String _panoramasPath = 'lib/images/panoramas/';
  static const String _modelsPath = 'assets/models/';
  static const String _dataPath = 'assets/';

  // Image assets
  static const String backgroundImage = '${_imagesPath}backgroundiu.jpg';
  static const String mainImage = '${_imagesPath}Main.jpg';
  static const String main2Image = '${_imagesPath}main2.jpg';

  // Location images
  static const Map<String, String> locationImages = {
    'Library': '${_imagesPath}library.jpg',
    'Play Area': '${_imagesPath}ground.jpg',
    'Auditorium': '${_imagesPath}auditorium.jpg',
    'Class Rooms': '${_imagesPath}class.jpg',
    'Amphitheater': '${_imagesPath}Amphitheater.jpg',
    'Cafeteria': '${_imagesPath}cafe.jpg',
    'Common Room': '${_imagesPath}commonroom.jpg',
    'Playground': '${_imagesPath}playground.jpg',
    'Swimming Pool': '${_imagesPath}swimming.jpg',
    'Webinar Room': '${_imagesPath}webinarroom.jpg',
  };

  // Panorama images
  static const Map<String, String> panoramaImages = {
    'Library': '${_panoramasPath}library_panorama.jpg',
    'Play Area': '${_panoramasPath}play_area_panorama.jpg',
    'Auditorium': '${_panoramasPath}auditorium_panorama.jpg',
    'Class Rooms': '${_panoramasPath}class_rooms_panorama.jpg',
    'Amphitheater': '${_panoramasPath}amphitheater_panorama.jpg',
    'Cafeteria': '${_panoramasPath}cafeteria_panorama.jpg',
    'Common Room': '${_panoramasPath}common_room_panorama.jpg',
    'Playground': '${_panoramasPath}playground_panorama.jpg',
    'Swimming Pool': '${_panoramasPath}swimming_pool_panorama.jpg',
    'Webinar Room': '${_panoramasPath}webinar_room_panorama.jpg',
  };

  // Fallback assets
  static const String fallbackPanorama = '${_panoramasPath}fallback_panorama.jpg';
  static const String fallbackImage = '${_imagesPath}backgroundiu.jpg';

  // 3D Models
  static const Map<String, String> models = {
    'classroom': '${_modelsPath}classroom.glb',
  };

  // Data files
  static const String appDataJson = '${_dataPath}app_data.json';

  // WebGL URLs
  static const Map<String, String> webglUrls = {
    'classroom': '/threejs/professional_classroom_enhanced.html',
    'library': '/threejs/library.html',
    'auditorium': '/threejs/auditorium.html',
  };

  // Asset optimization settings
  static const int defaultImageCacheWidth = 800;
  static const int defaultImageCacheHeight = 600;
  static const int thumbnailCacheWidth = 400;
  static const int thumbnailCacheHeight = 300;
  static const int mobileImageCacheWidth = 400;
  static const int mobileImageCacheHeight = 300;
  static const int mobileThumbnailCacheWidth = 200;
  static const int mobileThumbnailCacheHeight = 150;

  /// Initialize asset manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _memoryManager.initialize();
      _configureImageCache();
      
      _isInitialized = true;
      AppLogger.info('Unified asset manager initialized', component: _logComponent);
    } catch (e) {
      AppLogger.error('Failed to initialize unified asset manager',
        component: _logComponent,
        error: e);
    }
  }

  /// Get optimized cache dimensions based on device type
  static Map<String, int> getOptimizedCacheDimensions({bool isThumbnail = false}) {
    final isMobile = PlatformUtils.isMobile || PlatformUtils.isMobileScreen;
    
    if (isMobile) {
      return {
        'width': isThumbnail ? mobileThumbnailCacheWidth : mobileImageCacheWidth,
        'height': isThumbnail ? mobileThumbnailCacheHeight : mobileImageCacheHeight,
      };
    } else {
      return {
        'width': isThumbnail ? thumbnailCacheWidth : defaultImageCacheWidth,
        'height': isThumbnail ? thumbnailCacheHeight : defaultImageCacheHeight,
      };
    }
  }

  /// Get location image path
  static String getLocationImage(String locationName) {
    return locationImages[locationName] ?? fallbackImage;
  }

  /// Get panorama image path
  static String getPanoramaImage(String locationName) {
    return panoramaImages[locationName] ?? fallbackPanorama;
  }

  /// Get WebGL URL for location
  static String? getWebGLUrl(String locationName) {
    final urlKey = _locationNameToUrlKey(locationName);
    return webglUrls[urlKey];
  }

  /// Convert location name to URL-safe key
  static String _locationNameToUrlKey(String locationName) {
    switch (locationName.toLowerCase()) {
      case 'class rooms':
      case 'classroom':
      case 'classrooms':
        return 'classroom';
      case 'library':
        return 'library';
      case 'auditorium':
        return 'auditorium';
      default:
        return locationName.toLowerCase().replaceAll(' ', '_');
    }
  }

  /// Load image asset with caching and optimization
  Future<ImageProvider?> loadImage(
    String path, {
    bool isNetwork = false,
    Size? targetSize,
    bool cache = true,
  }) async {
    try {
      final cacheKey = 'image_${path}_${targetSize?.toString() ?? 'original'}';
      
      // Check cache first
      if (cache) {
        final cached = _memoryManager.getCached<ImageProvider>(cacheKey);
        if (cached != null) {
          AppLogger.debug('Image cache hit',
            component: _logComponent,
            metadata: {'path': path, 'cached': true});
          return cached;
        }
      }
      
      // Prevent duplicate loading
      if (_loadingAssets.containsKey(cacheKey)) {
        return await _loadingAssets[cacheKey]!.future as ImageProvider?;
      }
      
      final completer = Completer<ImageProvider?>();
      _loadingAssets[cacheKey] = completer;
      
      ImageProvider? imageProvider;
      
      if (isNetwork) {
        imageProvider = await _loadNetworkImage(path, targetSize);
      } else {
        imageProvider = await _loadAssetImage(path, targetSize);
      }
      
      // Cache the result
      if (cache && imageProvider != null) {
        _memoryManager.cache(cacheKey, imageProvider);
      }
      
      _loadingAssets.remove(cacheKey);
      completer.complete(imageProvider);
      
      AppLogger.debug('Image loaded successfully',
        component: _logComponent,
        metadata: {
          'path': path,
          'isNetwork': isNetwork,
          'targetSize': targetSize?.toString(),
        });
      
      return imageProvider;
    } catch (e) {
      final cacheKey = 'image_${path}_${targetSize?.toString() ?? 'original'}';
      _loadingAssets.remove(cacheKey);
      
      AppLogger.error('Failed to load image',
        component: _logComponent,
        error: e,
        metadata: {'path': path, 'isNetwork': isNetwork});
      
      return null;
    }
  }

  /// Load asset image with optimization
  Future<ImageProvider?> _loadAssetImage(String path, Size? targetSize) async {
    try {
      // For mobile devices, use optimized loading
      if (PlatformUtils.isMobile && targetSize != null) {
        return ResizeImage(
          AssetImage(path),
          width: targetSize.width.toInt(),
          height: targetSize.height.toInt(),
        );
      }
      
      return AssetImage(path);
    } catch (e) {
      AppLogger.warning('Asset image not found, trying fallback',
        component: _logComponent,
        error: e,
        metadata: {'path': path});
      
      // Return a fallback image
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  /// Load network image with caching
  Future<ImageProvider?> _loadNetworkImage(String url, Size? targetSize) async {
    try {
      if (PlatformUtils.isMobile && targetSize != null) {
        return ResizeImage(
          CachedNetworkImageProvider(url),
          width: targetSize.width.toInt(),
          height: targetSize.height.toInt(),
        );
      }
      
      return CachedNetworkImageProvider(url);
    } catch (e) {
      AppLogger.warning('Network image failed to load',
        component: _logComponent,
        error: e,
        metadata: {'url': url});
      
      return null;
    }
  }

  /// Load JSON asset
  Future<Map<String, dynamic>?> loadJsonAsset(String path) async {
    try {
      final cacheKey = 'json_$path';
      
      // Check cache first
      final cached = _memoryManager.getCached<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        return cached;
      }
      
      final jsonString = await rootBundle.loadString(path);
      final jsonData = Map<String, dynamic>.from(
        await compute(_parseJson, jsonString),
      );
      
      // Cache the result
      _memoryManager.cache(cacheKey, jsonData);
      
      AppLogger.debug('JSON asset loaded',
        component: _logComponent,
        metadata: {'path': path, 'keys': jsonData.keys.length});
      
      return jsonData;
    } catch (e) {
      AppLogger.error('Failed to load JSON asset',
        component: _logComponent,
        error: e,
        metadata: {'path': path});
      
      return null;
    }
  }

  /// Load string asset
  Future<String> loadStringAsset(String path) async {
    try {
      AppLogger.debug('Loading string asset: $path', component: _logComponent);
      
      final String content = await rootBundle.loadString(path);
      
      AppLogger.debug('String asset loaded successfully: $path',
        component: _logComponent,
        metadata: {'contentLength': content.length});
      
      return content;
    } catch (e) {
      AppLogger.error('Failed to load string asset: $path',
        component: _logComponent,
        error: e);
      return '';
    }
  }

  /// Load binary asset
  Future<Uint8List?> loadBinaryAsset(String path) async {
    try {
      final cacheKey = 'binary_$path';
      
      // Check cache first (but be careful with large binary data)
      final cached = _memoryManager.getCached<Uint8List>(cacheKey);
      if (cached != null) {
        return cached;
      }
      
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      
      // Only cache small binary files (< 1MB)
      if (bytes.length < 1024 * 1024) {
        _memoryManager.cache(cacheKey, bytes);
      }
      
      AppLogger.debug('Binary asset loaded',
        component: _logComponent,
        metadata: {'path': path, 'size': bytes.length});
      
      return bytes;
    } catch (e) {
      AppLogger.error('Failed to load binary asset',
        component: _logComponent,
        error: e,
        metadata: {'path': path});
      
      return null;
    }
  }

  /// Check if asset exists
  Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      AppLogger.warning('Asset not found: $assetPath',
        component: _logComponent,
        error: e);
      return false;
    }
  }

  /// Preload critical assets
  Future<void> preloadCriticalAssets() async {
    try {
      AppLogger.info('Preloading critical assets', component: _logComponent);
      
      final criticalAssets = [
        backgroundImage,
        mainImage,
        appDataJson,
      ];

      final futures = criticalAssets.map((asset) async {
        try {
          if (asset.endsWith('.json')) {
            await loadJsonAsset(asset);
          } else {
            await loadImage(asset);
          }
          AppLogger.debug('Preloaded asset: $asset', component: _logComponent);
        } catch (e) {
          AppLogger.warning('Failed to preload asset: $asset',
            component: _logComponent,
            error: e);
        }
      });

      await Future.wait(futures);
      AppLogger.info('Critical assets preloaded successfully', component: _logComponent);
    } catch (e) {
      AppLogger.error('Error preloading critical assets',
        component: _logComponent,
        error: e);
    }
  }

  /// Preload assets from list
  Future<void> preloadAssets(List<String> assetPaths) async {
    try {
      AppLogger.info('Preloading assets',
        component: _logComponent,
        metadata: {'count': assetPaths.length});
      
      final futures = assetPaths.map((path) async {
        try {
          if (path.endsWith('.json')) {
            await loadJsonAsset(path);
          } else if (path.contains('http')) {
            await loadImage(path, isNetwork: true);
          } else {
            await loadImage(path);
          }
        } catch (e) {
          AppLogger.warning('Failed to preload asset',
            component: _logComponent,
            error: e,
            metadata: {'path': path});
        }
      });
      
      await Future.wait(futures);
      
      AppLogger.info('Asset preloading completed', component: _logComponent);
    } catch (e) {
      AppLogger.error('Asset preloading failed',
        component: _logComponent,
        error: e);
    }
  }

  /// Validate all required assets exist
  Future<Map<String, bool>> validateAssets() async {
    AppLogger.info('Validating application assets', component: _logComponent);
    
    final Map<String, bool> results = {};
    
    // Validate critical assets
    final criticalAssets = [
      backgroundImage,
      mainImage,
      appDataJson,
    ];

    for (final asset in criticalAssets) {
      results[asset] = await assetExists(asset);
    }

    // Validate location images
    for (final entry in locationImages.entries) {
      results['location_${entry.key}'] = await assetExists(entry.value);
    }

    // Validate panorama images
    for (final entry in panoramaImages.entries) {
      results['panorama_${entry.key}'] = await assetExists(entry.value);
    }

    // Log validation results
    final missingAssets = results.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    if (missingAssets.isNotEmpty) {
      AppLogger.warning('Missing assets detected',
        component: _logComponent,
        metadata: {'missingAssets': missingAssets});
    } else {
      AppLogger.info('All assets validated successfully', component: _logComponent);
    }

    return results;
  }

  /// Get asset health report
  Future<AssetHealthReport> getHealthReport() async {
    final validationResults = await validateAssets();
    
    final totalAssets = validationResults.length;
    final validAssets = validationResults.values.where((valid) => valid).length;
    final missingAssets = validationResults.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    return AssetHealthReport(
      totalAssets: totalAssets,
      validAssets: validAssets,
      missingAssets: missingAssets,
      healthPercentage: (validAssets / totalAssets * 100).round(),
    );
  }

  /// Clear asset cache
  void clearCache() {
    _memoryManager.clearCache();
    _loadingAssets.clear();
    
    AppLogger.info('Asset cache cleared', component: _logComponent);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryStats': _memoryManager.getMemoryStats(),
      'loadingAssets': _loadingAssets.length,
      'isInitialized': _isInitialized,
    };
  }

  /// Configure image cache for optimal performance
  void _configureImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    if (PlatformUtils.isMobile) {
      // Conservative settings for mobile
      imageCache.maximumSize = 100;
      imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
    } else {
      // More generous settings for desktop/web
      imageCache.maximumSize = 200;
      imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
    }
    
    AppLogger.debug('Image cache configured',
      component: _logComponent,
      metadata: {
        'maxSize': imageCache.maximumSize,
        'maxSizeBytes': imageCache.maximumSizeBytes,
        'platform': PlatformUtils.isMobile ? 'mobile' : 'desktop',
      });
  }

  /// Dispose of resources
  void dispose() {
    clearCache();
    _memoryManager.dispose();
    _isInitialized = false;
    
    AppLogger.info('Unified asset manager disposed', component: _logComponent);
  }
}

/// Parse JSON in isolate for better performance
Map<String, dynamic> _parseJson(String jsonString) {
  try {
    return Map<String, dynamic>.from(json.decode(jsonString));
  } catch (e) {
    return <String, dynamic>{};
  }
}

/// Asset health report data class
class AssetHealthReport {
  final int totalAssets;
  final int validAssets;
  final List<String> missingAssets;
  final int healthPercentage;

  const AssetHealthReport({
    required this.totalAssets,
    required this.validAssets,
    required this.missingAssets,
    required this.healthPercentage,
  });

  bool get isHealthy => missingAssets.isEmpty;
  int get missingCount => missingAssets.length;

  @override
  String toString() {
    return 'AssetHealthReport(total: $totalAssets, valid: $validAssets, '
           'missing: $missingCount, health: $healthPercentage%)';
  }
}

/// Optimized image widget with automatic loading and error handling
class OptimizedImage extends StatefulWidget {
  final String path;
  final bool isNetwork;
  final Size? targetSize;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final bool cache;
  
  const OptimizedImage({
    super.key,
    required this.path,
    this.isNetwork = false,
    this.targetSize,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.cache = true,
  });
  
  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  final UnifiedAssetManager _assetManager = UnifiedAssetManager();
  ImageProvider? _imageProvider;
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      final imageProvider = await _assetManager.loadImage(
        widget.path,
        isNetwork: widget.isNetwork,
        targetSize: widget.targetSize,
        cache: widget.cache,
      );
      
      if (mounted) {
        setState(() {
          _imageProvider = imageProvider;
          _isLoading = false;
          _hasError = imageProvider == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? 
          const Center(child: CircularProgressIndicator());
    }
    
    if (_hasError || _imageProvider == null) {
      return widget.errorWidget ?? 
          const Icon(Icons.error, color: Colors.red);
    }
    
    return Image(
      image: _imageProvider!,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? 
            const Icon(Icons.error, color: Colors.red);
      },
    );
  }
}