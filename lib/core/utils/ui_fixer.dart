import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:ui' as ui;

/// Comprehensive UI fixer for deprecated APIs and Material Design compliance
/// 
/// This utility ensures pixel-perfect UI while fixing deprecated Flutter APIs
/// without changing the visual appearance.
class UIFixer {
  /// Fix deprecated withOpacity usage while maintaining exact visual appearance
  static Color fixOpacity(Color color, double opacity) {
    try {
      // Use the new withValues method (Flutter 3.27+)
      return color.withValues(alpha: opacity);
    } catch (e) {
      // Fallback to deprecated withOpacity for older Flutter versions
      // ignore: deprecated_member_use
      return color.withOpacity(opacity);
    }
  }
  
  /// Fix deprecated window usage with View.of(context) while maintaining functionality
  static Size getScreenSize(BuildContext context) {
    try {
      // Use the new View.of(context) method
      final view = View.of(context);
      return view.physicalSize / view.devicePixelRatio;
    } catch (e) {
      // Fallback to deprecated window for older Flutter versions
      // ignore: deprecated_member_use
      return ui.window.physicalSize / ui.window.devicePixelRatio;
    }
  }
  
  /// Fix deprecated window usage for device pixel ratio
  static double getDevicePixelRatio(BuildContext context) {
    try {
      return View.of(context).devicePixelRatio;
    } catch (e) {
      // ignore: deprecated_member_use
      return ui.window.devicePixelRatio;
    }
  }
  
  /// Fix deprecated window usage for platform brightness
  static Brightness getPlatformBrightness(BuildContext context) {
    try {
      return View.of(context).platformDispatcher.platformBrightness;
    } catch (e) {
      // ignore: deprecated_member_use
      return ui.window.platformBrightness;
    }
  }
  
  /// Fix deprecated Matrix4.translate while maintaining exact transformation
  static Matrix4 fixTranslate(double x, double y, [double z = 0.0]) {
    final matrix = Matrix4.identity();
    // Use the non-deprecated approach
    matrix.setTranslation(Vector3(x, y, z));
    return matrix;
  }
  
  /// Create Material Design compliant shadows
  static List<BoxShadow> createMaterialShadow({
    required Color color,
    double elevation = 4.0,
    double opacity = 0.16,
  }) {
    return [
      BoxShadow(
        color: fixOpacity(color, opacity),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation / 2),
      ),
    ];
  }
  
  /// Create Material Design compliant border
  static Border createMaterialBorder({
    required Color color,
    double width = 1.0,
    double opacity = 0.12,
  }) {
    return Border.all(
      color: fixOpacity(color, opacity),
      width: width,
    );
  }
  
  /// Create Material Design compliant gradient
  static LinearGradient createMaterialGradient({
    required Color startColor,
    required Color endColor,
    double startOpacity = 1.0,
    double endOpacity = 0.8,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        fixOpacity(startColor, startOpacity),
        fixOpacity(endColor, endOpacity),
      ],
    );
  }
}

/// Extension methods for seamless UI fixing
extension UIFixerExtensions on Color {
  /// Safe opacity replacement that maintains exact visual appearance
  Color safeOpacity(double opacity) => UIFixer.fixOpacity(this, opacity);
}

extension UIFixerMatrix4Extensions on Matrix4 {
  /// Safe translate replacement that maintains exact transformation
  static Matrix4 safeTranslate(double x, double y, [double z = 0.0]) {
    return UIFixer.fixTranslate(x, y, z);
  }
}