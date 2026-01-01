import 'dart:ui';
import 'package:flutter/material.dart';
import '../animation/animation_config.dart';

/// Enhanced glassmorphic container with additional variants and animations
class EnhancedGlassmorphicContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool isDark;
  final Color? backgroundColor;
  final Border? border;
  final GlassmorphicVariant variant;
  final bool enableHoverEffect;
  final bool enableGlowEffect;
  final VoidCallback? onTap;
  final VoidCallback? onHover;
  final double? width;
  final double? height;
  final BoxShadow? customShadow;

  const EnhancedGlassmorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    required this.isDark,
    this.backgroundColor,
    this.border,
    this.variant = GlassmorphicVariant.standard,
    this.enableHoverEffect = false,
    this.enableGlowEffect = false,
    this.onTap,
    this.onHover,
    this.width,
    this.height,
    this.customShadow,
  });

  @override
  State<EnhancedGlassmorphicContainer> createState() => _EnhancedGlassmorphicContainerState();
}

class _EnhancedGlassmorphicContainerState extends State<EnhancedGlassmorphicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AnimationConfig.quickActionHover,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConfig.hoverScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.smoothCurve,
    ));

    _glowAnimation = AnimationUtils.createGlowAnimation(
      controller: _animationController,
    );

    _opacityAnimation = Tween<double>(
      begin: _getBaseOpacity(),
      end: _getHoverOpacity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.defaultCurve,
    ));
  }

  double _getBaseOpacity() {
    switch (widget.variant) {
      case GlassmorphicVariant.standard:
        return AnimationConfig.glassmorphicOpacity;
      case GlassmorphicVariant.elevated:
        return AnimationConfig.glassmorphicOpacity + 0.1;
      case GlassmorphicVariant.subtle:
        return AnimationConfig.glassmorphicOpacity - 0.05;
      case GlassmorphicVariant.prominent:
        return AnimationConfig.glassmorphicOpacity + 0.2;
    }
  }

  double _getHoverOpacity() {
    return _getBaseOpacity() + 0.1;
  }

  double _getBlurRadius() {
    switch (widget.variant) {
      case GlassmorphicVariant.standard:
        return AnimationConfig.defaultBlurRadius;
      case GlassmorphicVariant.elevated:
        return AnimationConfig.enhancedBlurRadius;
      case GlassmorphicVariant.subtle:
        return AnimationConfig.defaultBlurRadius - 2;
      case GlassmorphicVariant.prominent:
        return AnimationConfig.enhancedBlurRadius + 5;
    }
  }

  List<BoxShadow> _getShadows() {
    final baseShadows = <BoxShadow>[];
    
    // Add variant-specific shadows
    switch (widget.variant) {
      case GlassmorphicVariant.standard:
        baseShadows.add(BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ));
        break;
      case GlassmorphicVariant.elevated:
        baseShadows.addAll([
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ]);
        break;
      case GlassmorphicVariant.subtle:
        baseShadows.add(BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ));
        break;
      case GlassmorphicVariant.prominent:
        baseShadows.addAll([
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ]);
        break;
    }

    // Add custom shadow if provided
    if (widget.customShadow != null) {
      baseShadows.add(widget.customShadow!);
    }

    return baseShadows;
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHoverEffect) return;
    
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _animationController.forward();
      widget.onHover?.call();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.enableHoverEffect ? _scaleAnimation.value : 1.0,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    ..._getShadows(),
                    if (widget.enableGlowEffect && _isHovered)
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _getBlurRadius(),
                      sigmaY: _getBlurRadius(),
                    ),
                    child: Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor ??
                            (widget.isDark
                                ? Colors.black.withOpacity(_opacityAnimation.value)
                                : Colors.white.withOpacity(_opacityAnimation.value)),
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: widget.border ??
                            Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Glassmorphic container variants for different use cases
enum GlassmorphicVariant {
  /// Standard glassmorphic effect
  standard,
  
  /// Elevated with more prominent shadows
  elevated,
  
  /// Subtle effect for background elements
  subtle,
  
  /// Prominent effect for hero elements
  prominent,
}

/// Specialized glassmorphic containers for specific components

/// Search bar specific glassmorphic container
class SearchBarGlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool isExpanded;
  final bool isFocused;

  const SearchBarGlassmorphicContainer({
    super.key,
    required this.child,
    required this.isDark,
    required this.isExpanded,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedGlassmorphicContainer(
      isDark: isDark,
      variant: GlassmorphicVariant.elevated,
      enableGlowEffect: isFocused,
      borderRadius: isExpanded ? 16 : 25,
      customShadow: isFocused
          ? BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          : null,
      child: child,
    );
  }
}

/// Language selector specific glassmorphic container
class LanguageSelectorGlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool isOpen;

  const LanguageSelectorGlassmorphicContainer({
    super.key,
    required this.child,
    required this.isDark,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedGlassmorphicContainer(
      isDark: isDark,
      variant: GlassmorphicVariant.standard,
      enableHoverEffect: true,
      enableGlowEffect: isOpen,
      borderRadius: 12,
      child: child,
    );
  }
}

/// Quick action card specific glassmorphic container
class QuickActionGlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool isHovered;
  final VoidCallback? onTap;

  const QuickActionGlassmorphicContainer({
    super.key,
    required this.child,
    required this.isDark,
    required this.isHovered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedGlassmorphicContainer(
      isDark: isDark,
      variant: GlassmorphicVariant.elevated,
      enableHoverEffect: true,
      enableGlowEffect: true,
      onTap: onTap,
      borderRadius: 16,
      child: child,
    );
  }
}

/// Testimonial card specific glassmorphic container
class TestimonialGlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool isActive;

  const TestimonialGlassmorphicContainer({
    super.key,
    required this.child,
    required this.isDark,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedGlassmorphicContainer(
      isDark: isDark,
      variant: isActive ? GlassmorphicVariant.prominent : GlassmorphicVariant.standard,
      enableGlowEffect: isActive,
      borderRadius: 20,
      child: child,
    );
  }
}