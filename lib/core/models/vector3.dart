// lib/core/models/vector3.dart
// Three.js-compatible 3D vector class for spawn coordinates
// Coordinate System: Right-handed (X: right, Y: up, Z: forward)

class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  /// Creates a zero vector
  const Vector3.zero() : x = 0.0, y = 0.0, z = 0.0;

  /// Creates a vector from JSON
  factory Vector3.fromJson(Map<String, dynamic> json) {
    return Vector3(
      (json['x'] as num?)?.toDouble() ?? 0.0,
      (json['y'] as num?)?.toDouble() ?? 0.0,
      (json['z'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts vector to JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vector3 &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vector3(x: $x, y: $y, z: $z)';

  /// Returns a copy of this vector
  Vector3 copy() => Vector3(x, y, z);

  /// Returns the length (magnitude) of this vector
  double get length => (x * x + y * y + z * z).squareRoot;

  /// Returns the squared length (avoids sqrt for performance)
  double get lengthSquared => x * x + y * y + z * z;
}

extension on double {
  double get squareRoot => this < 0 ? 0 : this.sqrt();
}

extension on double {
  double sqrt() {
    if (this < 0) return 0;
    double guess = this / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + this / guess) / 2;
    }
    return guess;
  }
}
