import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/app_spacing.dart';
import '../design/visual_enhancements.dart';

/// Animated section header with title, subtitle, and optional icon
class AnimatedSectionHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isDark;
  final TextAlign alignment;
  final EdgeInsets? padding;
  final Color? accentColor;
  final bool showAnimation;
  final Duration delay;

  const AnimatedSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.isDark,
    this.alignment = TextAlign.center,
    this.padding,
    this.accentColor,
    this.showAnimation = true,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedSectionHeader> createState() => _AnimatedSectionHeaderState();
}

class _AnimatedSectionHeaderState extends State<AnimatedSectionHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _iconController;
  
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.showAnimation) {
      _playAnimations();
    } else {
      _controller.value = 1.0;
      _iconController.value = 1.0;
    }
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: VisualEnhancements.animationDuration,
      vsync: this,
    );

    _iconController = AnimationController(
      duration: VisualEnhancements.slowAnimation,
      vsync: this,
    );

    // Title animations
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Subtitle animations
    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    // Icon animations
    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconRotationAnimation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOutBack,
    ));
  }

  void _playAnimations() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _iconController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final accentColor = widget.accentColor ?? theme.primaryColor;

    return Container(
      width: double.infinity,
      padding: widget.padding ?? AppSpacing.getSectionPadding(size),
      child: Column(
        crossAxisAlignment: _getCrossAxisAlignment(),
        children: [
          // Icon if provided
          if (widget.icon != null) ...[
            AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Transform.rotate(
                    angle: _iconRotationAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.2),
                            accentColor.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 32,
                        color: accentColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: AppSpacing.elementSpacing),
          ],

          // Title
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _titleFadeAnimation,
                child: SlideTransition(
                  position: _titleSlideAnimation,
                  child: _buildTitle(theme, size),
                ),
              );
            },
          ),

          // Subtitle if provided
          if (widget.subtitle != null) ...[
            SizedBox(height: AppSpacing.microSpacing),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _subtitleFadeAnimation,
                  child: SlideTransition(
                    position: _subtitleSlideAnimation,
                    child: _buildSubtitle(theme, size),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, Size size) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          theme.textTheme.headlineMedium?.color ?? Colors.black,
          (widget.accentColor ?? theme.primaryColor),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        widget.title,
        style: GoogleFonts.roboto(
          fontSize: _getTitleFontSize(size),
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.5,
          color: Colors.white, // This will be masked by the shader
        ),
        textAlign: widget.alignment,
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme, Size size) {
    return Text(
      widget.subtitle!,
      style: GoogleFonts.roboto(
        fontSize: _getSubtitleFontSize(size),
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.2,
        color: widget.isDark ? Colors.white70 : Colors.black54,
      ),
      textAlign: widget.alignment,
    );
  }

  CrossAxisAlignment _getCrossAxisAlignment() {
    switch (widget.alignment) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      default:
        return CrossAxisAlignment.center;
    }
  }

  double _getTitleFontSize(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 28;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 32;
    } else {
      return 36;
    }
  }

  double _getSubtitleFontSize(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 14;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 16;
    } else {
      return 18;
    }
  }
}

/// Compact version of the section header for smaller sections
class CompactSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDark;
  final TextAlign alignment;
  final EdgeInsets? padding;

  const CompactSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.isDark,
    this.alignment = TextAlign.left,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: AppSpacing.getHorizontalSpacing(size.width, multiplier: 0.5),
        vertical: AppSpacing.elementSpacing,
      ),
      child: Column(
        crossAxisAlignment: _getCrossAxisAlignment(),
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: alignment,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: alignment,
            ),
          ],
        ],
      ),
    );
  }

  CrossAxisAlignment _getCrossAxisAlignment() {
    switch (alignment) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      case TextAlign.center:
      default:
        return CrossAxisAlignment.center;
    }
  }
}