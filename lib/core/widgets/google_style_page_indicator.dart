import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class GoogleStylePageIndicator extends StatefulWidget {
  final PageController controller;
  final int count;
  final int currentIndex;
  final bool isDark;
  final bool isMobile;
  final Color? primaryColor;
  final bool showCounter;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool showArrows;

  const GoogleStylePageIndicator({
    super.key,
    required this.controller,
    required this.count,
    required this.currentIndex,
    required this.isDark,
    this.isMobile = false,
    this.primaryColor,
    this.showCounter = true,
    this.onPrevious,
    this.onNext,
    this.showArrows = false,
  });

  @override
  State<GoogleStylePageIndicator> createState() => _GoogleStylePageIndicatorState();
}

class _GoogleStylePageIndicatorState extends State<GoogleStylePageIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GoogleStylePageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = widget.primaryColor ?? theme.primaryColor;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 16 : 24,
              vertical: widget.isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(widget.isMobile ? 24 : 32),
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isDark 
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: widget.isMobile ? 8 : 16,
                  offset: Offset(0, widget.isMobile ? 2 : 4),
                ),
                if (!widget.isDark)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous arrow (if enabled)
                if (widget.showArrows && widget.onPrevious != null) ...[
                  _buildArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: widget.currentIndex > 0 ? widget.onPrevious : null,
                    effectivePrimaryColor: effectivePrimaryColor,
                  ),
                  SizedBox(width: widget.isMobile ? 12 : 16),
                ],
                
                // Page indicator dots
                _buildPageIndicator(effectivePrimaryColor),
                
                // Divider and counter (if not mobile and counter enabled)
                if (!widget.isMobile && widget.showCounter) ...[
                  SizedBox(width: widget.isMobile ? 16 : 20),
                  _buildDivider(),
                  SizedBox(width: widget.isMobile ? 16 : 20),
                  _buildPageCounter(),
                ],
                
                // Next arrow (if enabled)
                if (widget.showArrows && widget.onNext != null) ...[
                  SizedBox(width: widget.isMobile ? 12 : 16),
                  _buildArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: widget.currentIndex < widget.count - 1 ? widget.onNext : null,
                    effectivePrimaryColor: effectivePrimaryColor,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(Color effectivePrimaryColor) {
    return SmoothPageIndicator(
      controller: widget.controller,
      count: widget.count,
      effect: _getIndicatorEffect(effectivePrimaryColor),
    );
  }

  IndicatorEffect _getIndicatorEffect(Color effectivePrimaryColor) {
    if (widget.isMobile) {
      return WormEffect(
        dotWidth: 8,
        dotHeight: 8,
        spacing: 12,
        radius: 4,
        activeDotColor: effectivePrimaryColor,
        dotColor: _getInactiveDotColor(),
        paintStyle: PaintingStyle.fill,
      );
    } else {
      return SlideEffect(
        dotWidth: 12,
        dotHeight: 12,
        spacing: 16,
        radius: 6,
        activeDotColor: effectivePrimaryColor,
        dotColor: _getInactiveDotColor(),
        paintStyle: PaintingStyle.fill,
      );
    }
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color effectivePrimaryColor,
  }) {
    final isEnabled = onPressed != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isMobile ? 32 : 36,
          height: widget.isMobile ? 32 : 36,
          decoration: BoxDecoration(
            color: isEnabled 
                ? effectivePrimaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled 
                  ? effectivePrimaryColor.withValues(alpha: 0.2)
                  : _getBorderColor(),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: widget.isMobile ? 18 : 20,
            color: isEnabled 
                ? effectivePrimaryColor
                : _getInactiveDotColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            _getBorderColor(),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildPageCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${widget.currentIndex + 1} / ${widget.count}',
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: widget.isDark 
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.7),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isDark) {
      return Colors.black.withValues(alpha: 0.6);
    } else {
      return Colors.white.withValues(alpha: 0.95);
    }
  }

  Color _getBorderColor() {
    if (widget.isDark) {
      return Colors.white.withValues(alpha: 0.15);
    } else {
      return Colors.black.withValues(alpha: 0.08);
    }
  }

  Color _getInactiveDotColor() {
    if (widget.isDark) {
      return Colors.white.withValues(alpha: 0.3);
    } else {
      return Colors.black.withValues(alpha: 0.25);
    }
  }
}