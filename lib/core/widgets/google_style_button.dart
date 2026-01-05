import 'package:flutter/material.dart';
import '../design/spacing.dart';
import '../design/animation_config.dart';

/// Google Material Design 3.0 Button Component
/// 
/// A button component that follows Google's Material Design specifications
/// with proper touch targets, ripple effects, and consistent styling.
class GoogleStyleButton extends StatefulWidget {
  /// The button text or content
  final Widget child;
  
  /// Callback when the button is pressed
  final VoidCallback? onPressed;
  
  /// The button variant (filled, outlined, text)
  final GoogleButtonVariant variant;
  
  /// The button size (small, medium, large)
  final GoogleButtonSize size;
  
  /// Custom background color (overrides theme color)
  final Color? backgroundColor;
  
  /// Custom foreground color (overrides theme color)
  final Color? foregroundColor;
  
  /// Custom border color (for outlined buttons)
  final Color? borderColor;
  
  /// Whether the button should expand to fill available width
  final bool fullWidth;
  
  /// Custom padding (overrides size-based padding)
  final EdgeInsetsGeometry? padding;
  
  /// Custom border radius
  final BorderRadius? borderRadius;
  
  /// Leading icon
  final Widget? icon;
  
  /// Whether to show loading state
  final bool isLoading;

  const GoogleStyleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.variant = GoogleButtonVariant.filled,
    this.size = GoogleButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.fullWidth = false,
    this.padding,
    this.borderRadius,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<GoogleStyleButton> createState() => _GoogleStyleButtonState();
}

class _GoogleStyleButtonState extends State<GoogleStyleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConfig.short4,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.standard,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    
    setState(() {
      _isPressed = true;
    });
    
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    
    setState(() {
      _isPressed = false;
    });
    
    _animationController.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    
    setState(() {
      _isPressed = false;
    });
    
    _animationController.reverse();
  }

  EdgeInsetsGeometry _getPadding() {
    if (widget.padding != null) return widget.padding!;
    
    switch (widget.size) {
      case GoogleButtonSize.small:
        return widget.icon != null 
            ? EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs)
            : EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs);
      case GoogleButtonSize.medium:
        return widget.icon != null
            ? EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm)
            : EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm);
      case GoogleButtonSize.large:
        return widget.icon != null
            ? EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md)
            : EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.md);
    }
  }

  double _getMinHeight() {
    switch (widget.size) {
      case GoogleButtonSize.small:
        return 32.0; // Minimum 32px for small buttons
      case GoogleButtonSize.medium:
        return 40.0; // Standard 40px for medium buttons
      case GoogleButtonSize.large:
        return 48.0; // Minimum 48px for large buttons (accessibility)
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (widget.size) {
      case GoogleButtonSize.small:
        return theme.textTheme.labelMedium!;
      case GoogleButtonSize.medium:
        return theme.textTheme.labelLarge!;
      case GoogleButtonSize.large:
        return theme.textTheme.labelLarge!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    // Get colors based on variant and state
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;
    
    switch (widget.variant) {
      case GoogleButtonVariant.filled:
        backgroundColor = widget.backgroundColor ?? 
                         (isEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.12));
        foregroundColor = widget.foregroundColor ?? 
                         (isEnabled ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.38));
        break;
      case GoogleButtonVariant.outlined:
        backgroundColor = widget.backgroundColor ?? Colors.transparent;
        foregroundColor = widget.foregroundColor ?? 
                         (isEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38));
        borderColor = widget.borderColor ?? 
                     (isEnabled ? colorScheme.outline : colorScheme.onSurface.withValues(alpha: 0.12));
        break;
      case GoogleButtonVariant.text:
        backgroundColor = widget.backgroundColor ?? Colors.transparent;
        foregroundColor = widget.foregroundColor ?? 
                         (isEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.38));
        break;
    }

    final buttonBorderRadius = widget.borderRadius ?? BorderRadius.circular(20.0);
    final buttonPadding = _getPadding();
    final minHeight = _getMinHeight();
    final textStyle = _getTextStyle(theme);

    Widget buttonChild = widget.child;
    
    // Add loading indicator if needed
    if (widget.isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          Spacing.hGapSM,
          buttonChild,
        ],
      );
    } else if (widget.icon != null) {
      // Add icon if provided
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(
              color: foregroundColor,
              size: widget.size == GoogleButtonSize.small ? 16 : 18,
            ),
            child: widget.icon!,
          ),
          Spacing.hGapXS,
          buttonChild,
        ],
      );
    }

    // Apply text style
    buttonChild = DefaultTextStyle(
      style: textStyle.copyWith(color: foregroundColor),
      child: buttonChild,
    );

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: minHeight,
          minWidth: widget.fullWidth ? double.infinity : minHeight,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: buttonBorderRadius,
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? () {} : null, // Handled by gesture detector
            borderRadius: buttonBorderRadius,
            child: Padding(
              padding: buttonPadding,
              child: Center(
                child: buttonChild,
              ),
            ),
          ),
        ),
      ),
    );

    // Add gesture detection for press animation
    button = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: button,
    );

    if (widget.fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

/// Button variant types
enum GoogleButtonVariant {
  filled,
  outlined,
  text,
}

/// Button size types
enum GoogleButtonSize {
  small,
  medium,
  large,
}

/// Specialized button variants for common use cases

/// Primary filled button
class GoogleStylePrimaryButton extends GoogleStyleButton {
  const GoogleStylePrimaryButton({
    super.key,
    required super.child,
    required super.onPressed,
    super.size = GoogleButtonSize.medium,
    super.fullWidth = false,
    super.padding,
    super.borderRadius,
    super.icon,
    super.isLoading = false,
  }) : super(variant: GoogleButtonVariant.filled);
}

/// Secondary outlined button
class GoogleStyleSecondaryButton extends GoogleStyleButton {
  const GoogleStyleSecondaryButton({
    super.key,
    required super.child,
    required super.onPressed,
    super.size = GoogleButtonSize.medium,
    super.fullWidth = false,
    super.padding,
    super.borderRadius,
    super.icon,
    super.isLoading = false,
  }) : super(variant: GoogleButtonVariant.outlined);
}

/// Text button for tertiary actions
class GoogleStyleTextButton extends GoogleStyleButton {
  const GoogleStyleTextButton({
    super.key,
    required super.child,
    required super.onPressed,
    super.size = GoogleButtonSize.medium,
    super.fullWidth = false,
    super.padding,
    super.borderRadius,
    super.icon,
    super.isLoading = false,
  }) : super(variant: GoogleButtonVariant.text);
}

/// Icon button for actions with just an icon
class GoogleStyleIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final GoogleButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool filled;

  const GoogleStyleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = GoogleButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = onPressed != null;
    
    double buttonSize;
    double iconSize;
    
    switch (size) {
      case GoogleButtonSize.small:
        buttonSize = 32.0;
        iconSize = 16.0;
        break;
      case GoogleButtonSize.medium:
        buttonSize = 40.0;
        iconSize = 20.0;
        break;
      case GoogleButtonSize.large:
        buttonSize = 48.0;
        iconSize = 24.0;
        break;
    }

    final bgColor = filled
        ? (backgroundColor ?? (isEnabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.12)))
        : (backgroundColor ?? Colors.transparent);
    
    final fgColor = filled
        ? (foregroundColor ?? (isEnabled ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.38)))
        : (foregroundColor ?? (isEnabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withValues(alpha: 0.38)));

    Widget button = Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(buttonSize / 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: fgColor,
                size: iconSize,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}