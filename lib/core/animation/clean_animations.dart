import 'package:flutter/material.dart';

/// Clean animation utilities for smooth, performant animations
/// following Material Design 3 principles
class CleanAnimations {
  // Standard timing values
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Standard curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in from direction
  static Widget slideIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOutCubic,
    Offset begin = const Offset(0, 0.1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation
  static Widget scale({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOutCubic,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Combined fade and slide animation
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = easeOutCubic,
    Offset slideBegin = const Offset(0, 0.1),
    double fadeBegin = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, progress, child) {
        return Opacity(
          opacity: (progress * (1.0 - fadeBegin) + fadeBegin).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset.lerp(slideBegin, Offset.zero, progress)!,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    Duration itemDelay = const Duration(milliseconds: 100),
    Duration itemDuration = medium,
    Curve curve = easeOutCubic,
    Axis scrollDirection = Axis.vertical,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: itemDuration + (itemDelay * index),
          curve: curve,
          builder: (context, progress, child) {
            final slideOffset = scrollDirection == Axis.vertical
                ? Offset(0, (1 - progress) * 50)
                : Offset((1 - progress) * 50, 0);
            
            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: slideOffset,
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }

  /// Interactive feedback animation (for buttons, cards)
  static Widget interactiveFeedback({
    required Widget child,
    VoidCallback? onTap,
    Duration duration = fast,
    double scaleDown = 0.95,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: onTap,
          child: AnimatedScale(
            scale: isPressed ? scaleDown : 1.0,
            duration: duration,
            curve: easeOut,
            child: child,
          ),
        );
      },
    );
  }

  /// Shimmer loading animation
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    Color? baseColor,
    Color? highlightColor,
    bool enabled = true,
  }) {
    if (!enabled) return child;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, progress, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + 2.0 * progress, 0.0),
              end: Alignment(1.0 + 2.0 * progress, 0.0),
              colors: [
                baseColor ?? Colors.grey.shade300,
                highlightColor ?? Colors.grey.shade100,
                baseColor ?? Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// Accessibility-aware animation wrapper
  static Widget accessible({
    required Widget child,
    required Widget Function() animatedBuilder,
  }) {
    return Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final reduceMotion = mediaQuery.disableAnimations;
        
        if (reduceMotion) {
          return child;
        }
        
        return animatedBuilder();
      },
    );
  }

  /// Page transition builder
  static PageRouteBuilder pageTransition({
    required Widget page,
    PageTransitionType type = PageTransitionType.slideFromRight,
    Duration duration = medium,
    Curve curve = easeOutCubic,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case PageTransitionType.slideFromRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: curve)),
              child: child,
            );
          
          case PageTransitionType.slideFromBottom:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: curve)),
              child: child,
            );
          
          case PageTransitionType.fade:
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          
          case PageTransitionType.scale:
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(parent: animation, curve: curve)),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
        }
      },
    );
  }
}

enum PageTransitionType {
  slideFromRight,
  slideFromBottom,
  fade,
  scale,
}