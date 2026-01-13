import 'package:flutter/material.dart';

/// Clean container widget that removes blue shadows and provides
/// a clean, modern Material Design 3 aesthetic
class CleanContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final CleanContainerVariant variant;
  final bool isDark;
  final VoidCallback? onTap;

  const CleanContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.variant = CleanContainerVariant.card,
    this.isDark = false,
    this.onTap,
  });

  /// Card variant - elevated with subtle shadow
  const CleanContainer.card({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.isDark = false,
    this.onTap,
  }) : variant = CleanContainerVariant.card;

  /// Section variant - flat with border
  const CleanContainer.section({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.isDark = false,
    this.onTap,
  }) : variant = CleanContainerVariant.section;

  /// Interactive variant - with hover/press states
  const CleanContainer.interactive({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.isDark = false,
    this.onTap,
  }) : variant = CleanContainerVariant.interactive;

  /// Floating variant - higher elevation
  const CleanContainer.floating({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.isDark = false,
    this.onTap,
  }) : variant = CleanContainerVariant.floating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? 
        (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    
    // Clean shadows - no blue tint, using black/gray only
    List<BoxShadow> shadows = _getShadowsForVariant(isDark);
    
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: border ?? _getBorderForVariant(isDark),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: container,
        ),
      );
    }

    return container;
  }

  List<BoxShadow> _getShadowsForVariant(bool isDark) {
    switch (variant) {
      case CleanContainerVariant.card:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      
      case CleanContainerVariant.section:
        return []; // No shadow for section variant
      
      case CleanContainerVariant.interactive:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ];
      
      case CleanContainerVariant.floating:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ];
    }
  }

  Border? _getBorderForVariant(bool isDark) {
    switch (variant) {
      case CleanContainerVariant.card:
        return null; // No border for card variant
      
      case CleanContainerVariant.section:
        return Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        );
      
      case CleanContainerVariant.interactive:
        return Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        );
      
      case CleanContainerVariant.floating:
        return null; // No border for floating variant
    }
  }
}

enum CleanContainerVariant {
  card,
  section,
  interactive,
  floating,
}