import 'package:flutter/material.dart';

/// Animation configuration constants optimized for Google Material Design
class AnimationConfig {
  // Duration constants - Google Material Design timing
  static const Duration searchExpand = Duration(milliseconds: 250);
  static const Duration languageTransition = Duration(milliseconds: 300);
  static const Duration carousel3D = Duration(milliseconds: 400);
  static const Duration quickActionHover = Duration(milliseconds: 150);
  static const Duration testimonialRotation = Duration(seconds: 5);
  static const Duration shapeMovement = Duration(milliseconds: 80);
  static const Duration floatingShapeIdle = Duration(seconds: 30);
  static const Duration glowEffect = Duration(milliseconds: 600);
  static const Duration bounceEffect = Duration(milliseconds: 300);
  static const Duration fadeTransition = Duration(milliseconds: 200);
  static const Duration microInteraction = Duration(milliseconds: 100);
  static const Duration standardTransition = Duration(milliseconds: 300);
  
  // Curve constants - Google Material Design curves
  static const Curve defaultCurve = Curves.easeOutQuart;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutQuart;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve elasticCurve = Curves.elasticInOut;
  static const Curve materialCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  
  // Animation values
  static const double defaultBlurRadius = 10.0;
  static const double enhancedBlurRadius = 15.0;
  static const double glowBlurRadius = 20.0;
  static const double perspective3D = 0.001;
  static const double hoverScale = 1.05;
  static const double selectedScale = 1.1;
  static const double tiltAngle = 0.1;
  
  // Performance thresholds
  static const int targetFPS = 60;
  static const int minFPS = 30;
  static const int maxShapes = 20;
  static const int reducedMotionShapes = 5;
  
  // Opacity levels
  static const double glassmorphicOpacity = 0.2;
  static const double hoverOpacity = 0.3;
  static const double selectedOpacity = 0.4;
  static const double shapeBaseOpacity = 0.1;
  static const double shapeHoverOpacity = 0.2;
}

/// Enhanced animation utilities for complex transitions
class AnimationUtils {
  /// Creates a staggered animation controller for multiple elements
  static AnimationController createStaggeredController({
    required TickerProvider vsync,
    required Duration duration,
    double delay = 0.1,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }
  
  /// Creates a bounce animation with custom parameters
  static Animation<double> createBounceAnimation({
    required AnimationController controller,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = AnimationConfig.bounceCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
  
  /// Creates a 3D perspective animation
  static Animation<Matrix4> create3DAnimation({
    required AnimationController controller,
    double perspective = AnimationConfig.perspective3D,
    double rotationY = 0.0,
    double scale = 1.0,
  }) {
    return Tween<Matrix4>(
      begin: Matrix4.identity(),
      end: Matrix4.identity()
        ..setEntry(3, 2, perspective)
        ..rotateY(rotationY)
        ..scale(scale),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: AnimationConfig.smoothCurve,
    ));
  }
  
  /// Creates a glow effect animation
  static Animation<double> createGlowAnimation({
    required AnimationController controller,
    double minRadius = AnimationConfig.defaultBlurRadius,
    double maxRadius = AnimationConfig.glowBlurRadius,
  }) {
    return Tween<double>(
      begin: minRadius,
      end: maxRadius,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }
  
  /// Creates a parallax offset animation based on scroll
  static Offset calculateParallaxOffset({
    required double scrollOffset,
    required double sensitivity,
    required Size screenSize,
  }) {
    final normalizedOffset = scrollOffset / screenSize.height;
    return Offset(
      normalizedOffset * sensitivity * 0.5,
      normalizedOffset * sensitivity,
    );
  }
  
  /// Calculates mouse parallax effect
  static Offset calculateMouseParallax({
    required Offset mousePosition,
    required Size screenSize,
    required double sensitivity,
  }) {
    final normalizedX = (mousePosition.dx / screenSize.width - 0.5) * 2;
    final normalizedY = (mousePosition.dy / screenSize.height - 0.5) * 2;
    
    return Offset(
      normalizedX * sensitivity,
      normalizedY * sensitivity,
    );
  }
}