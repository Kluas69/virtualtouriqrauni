import 'package:flutter/material.dart';

/// Visual enhancement utilities for consistent styling and animations
class VisualEnhancements {
  // Elevation constants
  static const double cardElevation = 8.0;
  static const double hoverElevation = 16.0;
  static const double activeElevation = 24.0;
  
  // Animation constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Curve animationCurve = Curves.easeOutCubic;
  static const Curve bounceAnimation = Curves.elasticOut;
  
  // Shadow definitions
  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
    spreadRadius: 0,
  );
  
  static BoxShadow get hoverShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 24,
    offset: const Offset(0, 8),
    spreadRadius: 2,
  );
  
  static BoxShadow get activeShadow => BoxShadow(
    color: Colors.black.withValues(alpha: 0.16),
    blurRadius: 32,
    offset: const Offset(0, 12),
    spreadRadius: 4,
  );
  
  /// Get themed shadow based on current theme
  static BoxShadow getThemedShadow(bool isDark, {double intensity = 1.0}) {
    if (isDark) {
      return BoxShadow(
        color: Colors.black.withValues(alpha: 0.3 * intensity),
        blurRadius: 20 * intensity,
        offset: Offset(0, 6 * intensity),
        spreadRadius: 1 * intensity,
      );
    } else {
      return BoxShadow(
        color: Colors.black.withValues(alpha: 0.1 * intensity),
        blurRadius: 16 * intensity,
        offset: Offset(0, 4 * intensity),
        spreadRadius: 0,
      );
    }
  }
  
  /// Get colored shadow for accent elements
  static BoxShadow getColoredShadow(Color color, {double intensity = 0.3}) {
    return BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 2,
    );
  }
  
  /// Get multiple layered shadows for depth
  static List<BoxShadow> getLayeredShadows(bool isDark, {bool isHovered = false}) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: isHovered ? 0.4 : 0.2),
          blurRadius: isHovered ? 24 : 16,
          offset: Offset(0, isHovered ? 8 : 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isHovered ? 0.2 : 0.1),
          blurRadius: isHovered ? 48 : 32,
          offset: Offset(0, isHovered ? 16 : 8),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: isHovered ? 0.12 : 0.08),
          blurRadius: isHovered ? 20 : 12,
          offset: Offset(0, isHovered ? 6 : 3),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isHovered ? 0.08 : 0.04),
          blurRadius: isHovered ? 40 : 24,
          offset: Offset(0, isHovered ? 12 : 6),
        ),
      ];
    }
  }
  
  /// Get gradient background for sections
  static LinearGradient getSectionGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0A0A0A),
          Color(0xFF1A1A1A),
          Color(0xFF0F0F0F),
        ],
        stops: [0.0, 0.5, 1.0],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFAFAFA),
          Color(0xFFFFFFFF),
          Color(0xFFF5F5F5),
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
  }
  
  /// Get subtle overlay gradient for cards
  static LinearGradient getCardOverlay(bool isDark, {double opacity = 0.05}) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: opacity * 2),
          Colors.white.withValues(alpha: opacity),
          Colors.transparent,
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: opacity * 3),
          Colors.white.withValues(alpha: opacity),
          Colors.black.withValues(alpha: opacity * 0.5),
        ],
      );
    }
  }
  
  /// Create smooth scale animation
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 1.0,
    double end = 1.05,
    Curve curve = Curves.easeOutCubic,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
  
  /// Create smooth fade animation
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.easeOut,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
  
  /// Create slide animation
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOutCubic,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
}

/// Extension for easy access to visual enhancements
extension VisualEnhancementsExtension on BuildContext {
  VisualEnhancements get visuals => VisualEnhancements();
  
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  
  BoxShadow get cardShadow => VisualEnhancements.getThemedShadow(isDark);
  BoxShadow get hoverShadow => VisualEnhancements.getThemedShadow(isDark, intensity: 1.5);
  List<BoxShadow> get layeredShadows => VisualEnhancements.getLayeredShadows(isDark);
  LinearGradient get sectionGradient => VisualEnhancements.getSectionGradient(isDark);
}