import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Utility class to handle deprecated API migrations
/// 
/// This class provides helper methods to replace deprecated Flutter APIs
/// with their modern equivalents while maintaining backward compatibility.
class DeprecatedApiFixer {
  /// Replace deprecated withOpacity with withValues
  static Color fixWithOpacity(Color color, double opacity) {
    try {
      // Use the new withValues method (Flutter 3.27+)
      return color.withValues(alpha: opacity);
    } catch (e) {
      // Fallback to deprecated withOpacity for older Flutter versions
      // ignore: deprecated_member_use
      return color.withOpacity(opacity);
    }
  }
  
  /// Replace deprecated window usage with View.of(context)
  static Size getScreenSize(BuildContext context) {
    try {
      // Use the new View.of(context) method
      return View.of(context).physicalSize / View.of(context).devicePixelRatio;
    } catch (e) {
      // Fallback to deprecated window for older Flutter versions
      // ignore: deprecated_member_use
      return ui.window.physicalSize / ui.window.devicePixelRatio;
    }
  }
  
  /// Replace deprecated Matrix4.translate with translateByVector3
  static Matrix4 fixTranslate(double x, double y, [double z = 0.0]) {
    try {
      // Use the new translateByVector3 method
      final matrix = Matrix4.identity();
      matrix.translate(x, y, z);
      return matrix;
    } catch (e) {
      // Fallback to deprecated translate for older Flutter versions
      // ignore: deprecated_member_use
      return Matrix4.identity()..translate(x, y, z);
    }
  }
  
  /// Get device pixel ratio safely
  static double getDevicePixelRatio(BuildContext context) {
    try {
      return View.of(context).devicePixelRatio;
    } catch (e) {
      // ignore: deprecated_member_use
      return ui.window.devicePixelRatio;
    }
  }
  
  /// Get platform brightness safely
  static Brightness getPlatformBrightness(BuildContext context) {
    try {
      return View.of(context).platformDispatcher.platformBrightness;
    } catch (e) {
      // ignore: deprecated_member_use
      return ui.window.platformBrightness;
    }
  }
}

/// Extension to provide safe deprecated API replacements
extension SafeColorExtension on Color {
  /// Safe replacement for deprecated withOpacity
  Color safeWithOpacity(double opacity) {
    return DeprecatedApiFixer.fixWithOpacity(this, opacity);
  }
}

/// Extension to provide safe Matrix4 operations
extension SafeMatrix4Extension on Matrix4 {
  /// Safe replacement for deprecated translate
  Matrix4 safeTranslate(double x, double y, [double z = 0.0]) {
    return DeprecatedApiFixer.fixTranslate(x, y, z);
  }
}