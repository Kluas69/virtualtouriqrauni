import 'package:flutter/material.dart';

/// Glass container that provides glassmorphic effects
/// Reduces code duplication with parameterized variants
class GlassContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isDark;
  final GlassmorphicVariant variant;
  final bool enableAnimation;
  final Duration animationDuration;
  final VoidCallback? onTap;
  
  const GlassContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.isDark = false,
    this.variant = GlassmorphicVariant.standard,
    this.enableAnimation = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.onTap,
  }) : super(key: key);

  /// Factory method for search bar variant
  static Widget searchBar({
    required Widget child,
    bool isDark = false,
    bool isFocused = false,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      variant: GlassmorphicVariant.searchBar,
      isDark: isDark,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }

  /// Factory method for quick action variant
  static Widget quickAction({
    required Widget child,
    bool isDark = false,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      variant: GlassmorphicVariant.quickAction,
      isDark: isDark,
      onTap: onTap,
      enableAnimation: true,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  /// Factory method for language selector variant
  static Widget languageSelector({
    required Widget child,
    bool isDark = false,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      variant: GlassmorphicVariant.languageSelector,
      isDark: isDark,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.enableAnimation) {
      _animationController = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ));
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: _getDecoration(),
      child: widget.child,
    );

    Widget result = container;

    // Add animation if enabled
    if (widget.enableAnimation && _scaleAnimation != null) {
      result = AnimatedBuilder(
        animation: _scaleAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation!.value,
            child: container,
          );
        },
      );
    }

    // Add tap handling if provided
    if (widget.onTap != null) {
      result = GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _animationController?.forward(),
        onTapUp: (_) => _animationController?.reverse(),
        onTapCancel: () => _animationController?.reverse(),
        child: result,
      );
    }

    return result;
  }

  BoxDecoration _getDecoration() {
    switch (widget.variant) {
      case GlassmorphicVariant.searchBar:
        return _getSearchBarDecoration();
      case GlassmorphicVariant.languageSelector:
        return _getLanguageSelectorDecoration();
      case GlassmorphicVariant.quickAction:
        return _getQuickActionDecoration();
      case GlassmorphicVariant.testimonial:
        return _getTestimonialDecoration();
      case GlassmorphicVariant.enhanced:
        return _getEnhancedDecoration();
      case GlassmorphicVariant.standard:
      default:
        return _getStandardDecoration();
    }
  }

  BoxDecoration _getStandardDecoration() {
    return BoxDecoration(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.2),
      border: Border.all(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration _getSearchBarDecoration() {
    return BoxDecoration(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(25),
      color: widget.isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.9),
      border: Border.all(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration _getLanguageSelectorDecoration() {
    return BoxDecoration(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.8),
      border: Border.all(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration _getQuickActionDecoration() {
    return BoxDecoration(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
      color: widget.isDark
          ? Colors.white.withOpacity(0.08)
          : Colors.white.withOpacity(0.7),
      border: Border.all(
        color: widget.isDark
            ? Colors.white.withOpacity(0.15)
            : Colors.grey.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration _getTestimonialDecoration() {
    return BoxDecoration(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(18),
      color: widget.isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.white.withOpacity(0.85),
      border: Border.all(
        color: widget.isDark
            ? Colors.white.withOpacity(0.12)
            : Colors.grey.withOpacity(0.25),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  BoxDecoration _getEnhancedDecoration() {
    return BoxDecoration(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.isDark
            ? [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ]
            : [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
      ),
      border: Border.all(
        color: widget.isDark
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}

enum GlassmorphicVariant {
  standard,
  searchBar,
  languageSelector,
  quickAction,
  testimonial,
  enhanced,
}