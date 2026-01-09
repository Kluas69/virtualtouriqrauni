// lib/core/assets/app_assets.dart
/// Centralized asset management for the Virtual Tour application
/// This file contains all asset paths, loading utilities, and asset optimization logic

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:virtualtouriu/core/logging/app_logger.dart';
import 'package:virtualtouriu/core/platform/platform_utils.dart';

/// Asset paths organized by category
class AppAssets {
  static const String _logComponent = 'AppAssets';

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
    // Convert location name to URL-safe format
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

  /// Check if asset exists
  static Future<bool> assetExists(String assetPath) async {
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
  static Future<void> preloadCriticalAssets() async {
    try {
      AppLogger.info('Preloading critical assets', component: _logComponent);
      
      final criticalAssets = [
        backgroundImage,
        mainImage,
        appDataJson,
      ];

      final futures = criticalAssets.map((asset) async {
        try {
          await rootBundle.load(asset);
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
}

/// Asset loading utilities
class AssetLoader {
  static const String _logComponent = 'AssetLoader';

  /// Load JSON data from assets
  static Future<Map<String, dynamic>> loadJsonAsset(String assetPath) async {
    try {
      AppLogger.debug('Loading JSON asset: $assetPath', component: _logComponent);
      
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      AppLogger.debug('JSON asset loaded successfully: $assetPath',
          component: _logComponent,
          metadata: {'dataKeys': data.keys.toList()});
      
      return data;
    } catch (e) {
      AppLogger.error('Failed to load JSON asset: $assetPath',
          component: _logComponent,
          error: e);
      return {};
    }
  }

  /// Load string asset
  static Future<String> loadStringAsset(String assetPath) async {
    try {
      AppLogger.debug('Loading string asset: $assetPath', component: _logComponent);
      
      final String content = await rootBundle.loadString(assetPath);
      
      AppLogger.debug('String asset loaded successfully: $assetPath',
          component: _logComponent,
          metadata: {'contentLength': content.length});
      
      return content;
    } catch (e) {
      AppLogger.error('Failed to load string asset: $assetPath',
          component: _logComponent,
          error: e);
      return '';
    }
  }

  /// Load binary asset
  static Future<ByteData?> loadBinaryAsset(String assetPath) async {
    try {
      AppLogger.debug('Loading binary asset: $assetPath', component: _logComponent);
      
      final ByteData data = await rootBundle.load(assetPath);
      
      AppLogger.debug('Binary asset loaded successfully: $assetPath',
          component: _logComponent,
          metadata: {'dataSize': data.lengthInBytes});
      
      return data;
    } catch (e) {
      AppLogger.error('Failed to load binary asset: $assetPath',
          component: _logComponent,
          error: e);
      return null;
    }
  }
}

/// Asset validation utilities
class AssetValidator {
  static const String _logComponent = 'AssetValidator';

  /// Validate all required assets exist
  static Future<Map<String, bool>> validateAssets() async {
    AppLogger.info('Validating application assets', component: _logComponent);
    
    final Map<String, bool> results = {};
    
    // Validate critical assets
    final criticalAssets = [
      AppAssets.backgroundImage,
      AppAssets.mainImage,
      AppAssets.appDataJson,
    ];

    for (final asset in criticalAssets) {
      results[asset] = await AppAssets.assetExists(asset);
    }

    // Validate location images
    for (final entry in AppAssets.locationImages.entries) {
      results['location_${entry.key}'] = await AppAssets.assetExists(entry.value);
    }

    // Validate panorama images
    for (final entry in AppAssets.panoramaImages.entries) {
      results['panorama_${entry.key}'] = await AppAssets.assetExists(entry.value);
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
  static Future<AssetHealthReport> getHealthReport() async {
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