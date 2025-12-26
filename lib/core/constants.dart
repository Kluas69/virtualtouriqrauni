import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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

  // Convenience getter for name (same as title)
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

  static Future<void> initialize() async {
    try {
      // 1. Hardcoded local asset images for location cards → super fast loading
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

      // 2. Load the rest (panoramas, hotspots, features) from JSON
      final String jsonString = await rootBundle.loadString(
        'assets/app_data.json',
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);

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
    } catch (e) {
      print('Error initializing AppConstants: $e');
      rethrow;
    }
  }

  // Determine view type (WebGL or Panorama)
  static String viewTypeFor(String locationName) {
    if (locationName == 'Class Rooms') {
      return 'webgl';
    }
    return 'panorama';
  }

  // Return WebGL URL if applicable
  static String? webglUrlFor(String locationName) {
    if (locationName == 'Class Rooms') {
      return 'https://virtual-tour-iu.web.app';
    }
    return null;
  }

  // Single future to ensure initialize() is called only once
  static final Future<void> initializationFuture = initialize();
}
