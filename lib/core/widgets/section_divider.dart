import 'package:flutter/material.dart';
import '../design/app_spacing.dart';
import '../design/visual_enhancements.dart';

/// Elegant section divider with optional subtitle and visual enhancements
class SectionDivider extends StatefulWidget {
  final bool isDark;
  final String? subtitle;
  final double height;
  final bool showGradient;
  final bool showGeometry;
  final Color? accentColor;
  final EdgeInsets? padding;

  const SectionDivider({
    super.key,
    required this.isDark,
    this.subtitle,
    this.height = 80.0,
    this.showGradient = true,
    this.showGeometry = true,
    this.accentColor,
    this.padding,
  });

  @override
  State<SectionDivider> createState() => _SectionDividerState();
}

class _SectionDividerState extends State<SectionDivider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _playAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: VisualEnhancements.animationDuration,
      vsync: this,
    );

    _fadeAnimation = VisualEnhancements.createFadeAnimation(_controller);
    _scaleAnimation = VisualEnhancements.createScaleAnimation(
      _controller,
      begin: 0.8,
      end: 1.0,
    );
    _slideAnimation = VisualEnhancements.createSlideAnimation(
      _controller,
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    );
  }

  void _playAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final accentColor = widget.accentColor ?? theme.primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: widget.height,
              width: double.infinity,
              padding: widget.padding ?? AppSpacing.getSectionPadding(size),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main divider with geometric elements
                  if (widget.showGeometry) _buildGeometricDivider(accentColor, size),
                  
                  // Subtitle if provided
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 16),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: widget.isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeometricDivider(Color accentColor, Size size) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background gradient line
          if (widget.showGradient) _buildGradientLine(accentColor, size),
          
          // Central geometric element
          _buildCentralElement(accentColor),
          
          // Side decorative elements
          _buildSideElements(accentColor, size),
        ],
      ),
    );
  }

  Widget _buildGradientLine(Color accentColor, Size size) {
    return Container(
      height: 1,
      width: size.width * 0.6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            accentColor.withValues(alpha: 0.3),
            accentColor.withValues(alpha: 0.6),
            accentColor.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
      ),
    );
  }

  Widget _buildCentralElement(Color accentColor) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              accentColor.withValues(alpha: 0.8),
              accentColor.withValues(alpha: 0.4),
              accentColor.withValues(alpha: 0.1),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isDark 
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSideElements(Color accentColor, Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSideElement(accentColor, isLeft: true),
        _buildSideElement(accentColor, isLeft: false),
      ],
    );
  }

  Widget _buildSideElement(Color accentColor, {required bool isLeft}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: 60,
        height: 20,
        child: CustomPaint(
          painter: _GeometricElementPainter(
            color: accentColor.withValues(alpha: 0.4),
            isDark: widget.isDark,
            isLeft: isLeft,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for geometric decorative elements
class _GeometricElementPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final bool isLeft;

  _GeometricElementPainter({
    required this.color,
    required this.isDark,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (isLeft) {
      // Left side geometric pattern
      path.moveTo(0, size.height * 0.5);
      path.lineTo(size.width * 0.3, size.height * 0.2);
      path.lineTo(size.width * 0.6, size.height * 0.5);
      path.lineTo(size.width * 0.3, size.height * 0.8);
      path.close();
    } else {
      // Right side geometric pattern (mirrored)
      path.moveTo(size.width, size.height * 0.5);
      path.lineTo(size.width * 0.7, size.height * 0.2);
      path.lineTo(size.width * 0.4, size.height * 0.5);
      path.lineTo(size.width * 0.7, size.height * 0.8);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple divider variant for minimal sections
class SimpleSectionDivider extends StatelessWidget {
  final bool isDark;
  final double height;
  final Color? color;

  const SimpleSectionDivider({
    super.key,
    required this.isDark,
    this.height = 40.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? 
        (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1));

    return Container(
      height: height,
      width: double.infinity,
      child: Center(
        child: Container(
          height: 1,
          width: MediaQuery.of(context).size.width * 0.3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                dividerColor,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}