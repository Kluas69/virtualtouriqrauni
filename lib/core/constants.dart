import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'platform/platform_utils.dart';
import 'logging/app_logger.dart';

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

  // MOBILE OPTIMIZATION: Detect platform
  static bool get isMobile => PlatformUtils.isMobile || PlatformUtils.isMobileScreen;

  // MOBILE OPTIMIZATION: Image cache sizes based on device
  static int get imageCacheWidth => isMobile ? 400 : 800;
  static int get imageCacheHeight => isMobile ? 300 : 600;
  static int get thumbnailCacheWidth => isMobile ? 200 : 400;
  static int get thumbnailCacheHeight => isMobile ? 150 : 300;

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
        final String jsonString = await rootBundle
            .loadString('assets/app_data.json')
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
      } catch (jsonError) {
        AppLogger.error('Error loading JSON, using defaults', 
          component: 'AppConstants',
          error: jsonError);
        
        // Initialize with safe defaults
        panoramaImages = {};
        fallbackPanoramaImage = '';
        panoramaHotspots = {};
        locationFeatures = {};
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

  static String viewTypeFor(String locationName) {
    // FIXED: Removed mobile fallback for WebGL – now loads on mobile too (with warning in WebGlRoomScreen)
    if (locationName == 'Class Rooms') {
      return 'webgl';
    }
    return 'panorama';
  }

  static String? webglUrlFor(String locationName) {
    // FIXED: Removed mobile check – return URL on all devices
    if (locationName == 'Class Rooms') {
      return 'assets/models/classroom.glb';
    }
    return null;
  }
}
