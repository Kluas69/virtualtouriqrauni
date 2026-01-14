import 'dart:convert';
import 'platform/platform_utils.dart';
import 'logging/app_logger.dart';
import 'assets/asset_manager.dart';
import 'models/spawn_config.dart';

class LocationCardData {
  final String tag;
  final String title;
  final String imagePath;
  final String description;

  LocationCardData({
    required this.tag,
    required this.title,
    required this.imagePath,
    this.description = '',
  });

  String get name => title;

  factory LocationCardData.fromJson(Map<String, dynamic> json) {
    return LocationCardData(
      tag: json['tag'] ?? '',
      title: json['title'] ?? '',
      imagePath: json['imagePath'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class AppConstants {
  static late List<LocationCardData> locationCards;
  static late Map<String, String> panoramaImages;
  static late String fallbackPanoramaImage;
  static late Map<String, List<Map<String, dynamic>>> panoramaHotspots;
  static late Map<String, List<Map<String, dynamic>>> locationFeatures;
  
  // SPAWN SYSTEM: Location-specific 3D spawn configurations
  static late Map<String, SpawnConfig> locationSpawnConfigs;
  static late SpawnConfig defaultSpawnConfig;

  // MOBILE OPTIMIZATION: Detect platform
  static bool get isMobile => PlatformUtils.isMobile || PlatformUtils.isMobileScreen;

  // MOBILE OPTIMIZATION: Image cache sizes based on device
  static int get imageCacheWidth => isMobile ? UnifiedAssetManager.mobileImageCacheWidth : UnifiedAssetManager.defaultImageCacheWidth;
  static int get imageCacheHeight => isMobile ? UnifiedAssetManager.mobileImageCacheHeight : UnifiedAssetManager.defaultImageCacheHeight;
  static int get thumbnailCacheWidth => isMobile ? UnifiedAssetManager.mobileThumbnailCacheWidth : UnifiedAssetManager.thumbnailCacheWidth;
  static int get thumbnailCacheHeight => isMobile ? UnifiedAssetManager.mobileThumbnailCacheHeight : UnifiedAssetManager.thumbnailCacheHeight;

  static Future<void> initialize() async {
    try {
      AppLogger.info('Starting AppConstants initialization', 
        component: 'AppConstants');
      
      // Hardcoded location cards for fast loading
      locationCards = [
        LocationCardData(
          tag: "Discover",
          title: "Library",
          imagePath: "lib/images/library.jpg",
          description:
              "A state-of-the-art learning hub with vast collections of books, digital resources, and quiet study spaces designed to foster academic excellence.",
        ),
        LocationCardData(
          tag: "Exclusive",
          title: "Play Area",
          imagePath: "lib/images/ground.jpg",
          description:
              "Modern recreational facilities featuring sports courts and open spaces perfect for physical activities and student engagement.",
        ),
        LocationCardData(
          tag: "NEW",
          title: "Auditorium",
          imagePath: "lib/images/auditorium.jpg",
          description:
              "A premium venue equipped with cutting-edge audio-visual technology, ideal for seminars, conferences, and cultural events.",
        ),
        LocationCardData(
          tag: "NEW",
          title: "Class Rooms",
          imagePath: "lib/images/class.jpg",
          description:
              "Contemporary learning spaces designed with ergonomic furniture and modern teaching aids to enhance the educational experience.",
        ),
        LocationCardData(
          tag: "Discover",
          title: "Amphitheater",
          imagePath: "lib/images/Amphitheater.jpg",
          description:
              "An open-air venue perfect for outdoor events, performances, and gatherings under the sky.",
        ),
        LocationCardData(
          tag: "Discover",
          title: "Cafeteria",
          imagePath: "lib/images/cafe.jpg",
          description:
              "A vibrant dining space offering diverse cuisine options and comfortable seating for students to relax and socialize.",
        ),
        LocationCardData(
          tag: "Discover",
          title: "Common Room",
          imagePath: "lib/images/commonroom.jpg",
          description:
              "A collaborative space designed for informal meetings, group discussions, and casual student interactions.",
        ),
        LocationCardData(
          tag: "Discover",
          title: "Playground",
          imagePath: "lib/images/playground.jpg",
          description:
              "Expansive outdoor facilities for sports and recreational activities promoting health and wellness.",
        ),
        LocationCardData(
          tag: "Discover",
          title: "Swimming Pool",
          imagePath: "lib/images/swimming.jpg",
          description:
              "An Olympic-standard swimming facility for aquatic sports, fitness, and recreation.",
        ),
        LocationCardData(
          tag: "Discover",
          title: "Webinar Room",
          imagePath: "lib/images/webinarroom.jpg",
          description:
              "Advanced technology-enabled rooms designed for virtual meetings, online classes, and digital conferences.",
        ),
      ];

      AppLogger.info('Location cards initialized', 
        component: 'AppConstants',
        metadata: {'count': locationCards.length});

      // Load JSON data with shorter timeout and better error handling
      try {
        final String jsonString = await UnifiedAssetManager().loadStringAsset(UnifiedAssetManager.appDataJson)
            .timeout(const Duration(seconds: 5), onTimeout: () {
              AppLogger.warning('JSON loading timed out, using defaults', 
                component: 'AppConstants');
              return '{}';
            });

        AppLogger.info('JSON loaded successfully', 
          component: 'AppConstants',
          metadata: {'length': jsonString.length});

        final Map<String, dynamic> json =
            jsonString.isNotEmpty ? jsonDecode(jsonString) : {};

        panoramaImages = Map<String, String>.from(json['panoramaImages'] ?? {});
        fallbackPanoramaImage = json['fallbackPanoramaImage'] ?? '';

        final Map<String, dynamic> hotspotsJson = json['panoramaHotspots'] ?? {};
        panoramaHotspots = hotspotsJson.map((key, value) {
          return MapEntry(key, List<Map<String, dynamic>>.from(value));
        });

        final Map<String, dynamic> featuresJson = json['locationFeatures'] ?? {};
        locationFeatures = featuresJson.map((key, value) {
          return MapEntry(key, List<Map<String, dynamic>>.from(value));
        });

        AppLogger.info('JSON data processed successfully', 
          component: 'AppConstants',
          metadata: {
            'panoramaImages': panoramaImages.length,
            'hotspots': panoramaHotspots.length,
            'features': locationFeatures.length,
          });
        
        // SPAWN SYSTEM: Load spawn configurations
        try {
          final Map<String, dynamic> spawnConfigsJson = 
              json['locationSpawnConfigs'] as Map<String, dynamic>? ?? {};
          
          locationSpawnConfigs = {};
          for (final entry in spawnConfigsJson.entries) {
            try {
              final config = SpawnConfig.fromJson(entry.value as Map<String, dynamic>);
              // Validate and clamp coordinates to safe bounds
              locationSpawnConfigs[entry.key] = config.isValid() 
                  ? config 
                  : config.clampToBounds();
              
              if (!config.isValid()) {
                AppLogger.warning('Spawn config for ${entry.key} had invalid coordinates, clamped to safe bounds',
                  component: 'AppConstants');
              }
            } catch (configError) {
              AppLogger.error('Error parsing spawn config for ${entry.key}',
                component: 'AppConstants',
                error: configError);
            }
          }
          
          // Initialize default spawn configuration
          defaultSpawnConfig = SpawnConfig.defaultConfig();
          
          AppLogger.info('Spawn configurations loaded successfully',
            component: 'AppConstants',
            metadata: {'count': locationSpawnConfigs.length});
            
        } catch (spawnError) {
          AppLogger.error('Error loading spawn configurations, using defaults',
            component: 'AppConstants',
            error: spawnError);
          
          // Initialize with safe defaults
          locationSpawnConfigs = {};
          defaultSpawnConfig = SpawnConfig.defaultConfig();
        }
      } catch (jsonError) {
        AppLogger.error('Error loading JSON, using defaults', 
          component: 'AppConstants',
          error: jsonError);
        
        // Initialize with safe defaults
        panoramaImages = {};
        fallbackPanoramaImage = '';
        panoramaHotspots = {};
        locationFeatures = {};
        locationSpawnConfigs = {};
        defaultSpawnConfig = SpawnConfig.defaultConfig();
      }

      AppLogger.info('AppConstants initialization completed successfully', 
        component: 'AppConstants');
    } catch (e) {
      AppLogger.error('Error initializing AppConstants', 
        component: 'AppConstants',
        error: e,
        metadata: {'operation': 'initialize'});
      
      // Initialize with defaults to prevent crash
      locationCards = [];
      panoramaImages = {};
      fallbackPanoramaImage = '';
      panoramaHotspots = {};
      locationFeatures = {};
      locationSpawnConfigs = {};
      defaultSpawnConfig = SpawnConfig.defaultConfig();
      
      // Re-throw to let caller handle
      rethrow;
    }
  }

  // Create initialization future lazily to avoid immediate execution
  static Future<void>? _initializationFuture;
  static Future<void> get initializationFuture {
    _initializationFuture ??= initialize();
    return _initializationFuture!;
  }

  /// SPAWN SYSTEM: Get spawn configuration for a location
  /// Returns the spawn config for the given location name, or default if not found
  static SpawnConfig getSpawnConfigFor(String locationName) {
    final config = locationSpawnConfigs[locationName];
    if (config == null) {
      AppLogger.warning('No spawn config for $locationName, using default',
        component: 'AppConstants',
        metadata: {'location': locationName});
      return defaultSpawnConfig;
    }
    return config;
  }

  /// SPAWN SYSTEM: Check if a location has a spawn configuration
  static bool hasSpawnConfig(String locationName) {
    return locationSpawnConfigs.containsKey(locationName);
  }

  static String viewTypeFor(String locationName) {
    // SPAWN SYSTEM: All locations now support WebGL with dynamic spawn coordinates
    // Return 'webgl' for all 10 campus locations
    const webglLocations = [
      'Library',
      'Play Area',
      'Auditorium',
      'Class Rooms',
      'Amphitheater',
      'Cafeteria',
      'Common Room',
      'Playground',
      'Swimming Pool',
      'Webinar Room',
    ];
    
    if (webglLocations.contains(locationName)) {
      return 'webgl';
    }
    
    // Fallback to panorama for any other locations
    return 'panorama';
  }

  static String? webglUrlFor(String locationName) {
    return UnifiedAssetManager.getWebGLUrl(locationName);
  }
}
