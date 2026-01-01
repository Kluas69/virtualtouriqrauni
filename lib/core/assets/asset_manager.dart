import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../logging/app_logger.dart';
import '../memory/memory_manager.dart';
import '../platform/platform_utils.dart';

/// Comprehensive asset management system with caching and optimization
/// 
/// This system provides efficient loading, caching, and memory management
/// for images, models, and other assets with mobile optimization.
class AssetManager {
  static final AssetManager _instance = AssetManager._internal();
  factory AssetManager() => _instance;
  AssetManager._internal();
  
  final MemoryManager _memoryManager = MemoryManager();
  final Map<String, Completer<dynamic>> _loadingAssets = {};
  
  bool _isInitialized = false;
  
  /// Initialize asset manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _memoryManager.initialize();
      _configureImageCache();
      
      _isInitialized = true;
      AppLogger.info('Asset manager initialized',
        component: 'AssetManager');
    } catch (e) {
      AppLogger.error('Failed to initialize asset manager',
        component: 'AssetManager',
        error: e);
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
            component: 'AssetManager',
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
        component: 'AssetManager',
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
        component: 'AssetManager',
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
        component: 'AssetManager',
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
        component: 'AssetManager',
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
        component: 'AssetManager',
        metadata: {'path': path, 'keys': jsonData.keys.length});
      
      return jsonData;
    } catch (e) {
      AppLogger.error('Failed to load JSON asset',
        component: 'AssetManager',
        error: e,
        metadata: {'path': path});
      
      return null;
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
        component: 'AssetManager',
        metadata: {'path': path, 'size': bytes.length});
      
      return bytes;
    } catch (e) {
      AppLogger.error('Failed to load binary asset',
        component: 'AssetManager',
        error: e,
        metadata: {'path': path});
      
      return null;
    }
  }
  
  /// Preload critical assets
  Future<void> preloadAssets(List<String> assetPaths) async {
    try {
      AppLogger.info('Preloading assets',
        component: 'AssetManager',
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
            component: 'AssetManager',
            error: e,
            metadata: {'path': path});
        }
      });
      
      await Future.wait(futures);
      
      AppLogger.info('Asset preloading completed',
        component: 'AssetManager');
    } catch (e) {
      AppLogger.error('Asset preloading failed',
        component: 'AssetManager',
        error: e);
    }
  }
  
  /// Clear asset cache
  void clearCache() {
    _memoryManager.clearCache();
    _loadingAssets.clear();
    
    AppLogger.info('Asset cache cleared',
      component: 'AssetManager');
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
      component: 'AssetManager',
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
    
    AppLogger.info('Asset manager disposed',
      component: 'AssetManager');
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
  final AssetManager _assetManager = AssetManager();
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