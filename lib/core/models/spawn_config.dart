// lib/core/models/spawn_config.dart
// Configuration for 3D spawn position and camera orientation
// Used to position players at location-specific coordinates in the WebGL environment

import 'dart:convert';
import 'vector3.dart';

/// Spawn configuration for a campus location
/// 
/// Coordinate System (Three.js right-handed):
/// - X-axis: Positive = Right, Negative = Left
/// - Y-axis: Positive = Up, Negative = Down  
/// - Z-axis: Positive = Forward (toward camera), Negative = Backward
///
/// Rotation (Euler angles in radians):
/// - Pitch: Rotation around X-axis (looking up/down)
/// - Yaw: Rotation around Y-axis (looking left/right)
/// - Roll: Rotation around Z-axis (tilting head)
class SpawnConfig {
  /// 3D position where player spawns (x, y, z)
  final Vector3 position;
  
  /// Camera rotation in Euler angles (pitch, yaw, roll) in radians
  final Vector3 rotation;
  
  /// Name of the location this spawn config is for
  final String locationName;
  
  /// Optional description of the spawn point
  final String? description;
  
  /// Scale factor for the player model (default: 1.0)
  final double scaleFactor;
  
  /// Environment type identifier (default: 'classroom')
  final String environmentType;

  const SpawnConfig({
    required this.position,
    required this.rotation,
    required this.locationName,
    this.description,
    this.scaleFactor = 1.0,
    this.environmentType = 'classroom',
  });

  /// Creates a default spawn configuration
  /// Position: (0, 1.6, 5) - center, eye height, 5 units forward
  /// Rotation: (0, 0, 0) - facing forward
  factory SpawnConfig.defaultConfig() {
    return const SpawnConfig(
      position: Vector3(0.0, 1.6, 5.0),
      rotation: Vector3.zero(),
      locationName: 'default',
      description: 'Default classroom entrance',
      scaleFactor: 1.0,
      environmentType: 'classroom',
    );
  }

  /// Creates spawn config from JSON
  factory SpawnConfig.fromJson(Map<String, dynamic> json) {
    return SpawnConfig(
      position: json['position'] != null
          ? Vector3.fromJson(json['position'] as Map<String, dynamic>)
          : const Vector3(0.0, 1.6, 5.0),
      rotation: json['rotation'] != null
          ? Vector3.fromJson(json['rotation'] as Map<String, dynamic>)
          : const Vector3.zero(),
      locationName: json['locationName'] as String? ?? 'unknown',
      description: json['description'] as String?,
      scaleFactor: (json['scaleFactor'] as num?)?.toDouble() ?? 1.0,
      environmentType: json['environmentType'] as String? ?? 'classroom',
    );
  }

  /// Converts spawn config to JSON
  Map<String, dynamic> toJson() {
    return {
      'position': position.toJson(),
      'rotation': rotation.toJson(),
      'locationName': locationName,
      if (description != null) 'description': description,
      'scaleFactor': scaleFactor,
      'environmentType': environmentType,
    };
  }

  /// Converts spawn config to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Converts spawn config to URL query parameters
  /// Format: spawnX=0&spawnY=1.6&spawnZ=5&pitch=0&yaw=0&roll=0
  String toUrlParams() {
    return 'spawnX=${position.x}&spawnY=${position.y}&spawnZ=${position.z}'
        '&pitch=${rotation.x}&yaw=${rotation.y}&roll=${rotation.z}'
        '&scale=$scaleFactor&env=$environmentType';
  }

  /// Validates that coordinates are within safe bounds
  /// Returns true if valid, false otherwise
  bool isValid() {
    // Y coordinate must be above ground (0.5) and below ceiling (10.0)
    if (position.y < 0.5 || position.y > 10.0) return false;
    
    // X and Z coordinates must be within reasonable bounds
    if (position.x.abs() > 50.0 || position.z.abs() > 50.0) return false;
    
    // Scale factor must be positive
    if (scaleFactor <= 0.0) return false;
    
    return true;
  }

  /// Returns a clamped version of this config with coordinates within safe bounds
  SpawnConfig clampToBounds() {
    return SpawnConfig(
      position: Vector3(
        position.x.clamp(-50.0, 50.0),
        position.y.clamp(0.5, 10.0),
        position.z.clamp(-50.0, 50.0),
      ),
      rotation: Vector3(
        _normalizeAngle(rotation.x),
        _normalizeAngle(rotation.y),
        _normalizeAngle(rotation.z),
      ),
      locationName: locationName,
      description: description,
      scaleFactor: scaleFactor.clamp(0.1, 10.0),
      environmentType: environmentType,
    );
  }

  /// Normalizes angle to [-π, π] range
  static double _normalizeAngle(double angle) {
    const pi = 3.14159265359;
    double normalized = angle;
    while (normalized > pi) normalized -= 2 * pi;
    while (normalized < -pi) normalized += 2 * pi;
    return normalized;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpawnConfig &&
        other.position == position &&
        other.rotation == rotation &&
        other.locationName == locationName &&
        other.description == description &&
        other.scaleFactor == scaleFactor &&
        other.environmentType == environmentType;
  }

  @override
  int get hashCode => Object.hash(
        position,
        rotation,
        locationName,
        description,
        scaleFactor,
        environmentType,
      );

  @override
  String toString() {
    return 'SpawnConfig('
        'location: $locationName, '
        'position: $position, '
        'rotation: $rotation, '
        'scale: $scaleFactor'
        ')';
  }

  /// Creates a copy of this config with optional field overrides
  SpawnConfig copyWith({
    Vector3? position,
    Vector3? rotation,
    String? locationName,
    String? description,
    double? scaleFactor,
    String? environmentType,
  }) {
    return SpawnConfig(
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      locationName: locationName ?? this.locationName,
      description: description ?? this.description,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      environmentType: environmentType ?? this.environmentType,
    );
  }
}
