import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleStyleTourButton extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onPressed;
  final bool isFloatingActionButton;

  const GoogleStyleTourButton({
    super.key,
    required this.isMobile,
    required this.onPressed,
    this.isFloatingActionButton = false,
  });

  @override
  State<GoogleStyleTourButton> createState() => _GoogleStyleTourButtonState();
}

class _GoogleStyleTourButtonState extends State<GoogleStyleTourButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.isFloatingActionButton) {
      return _buildFloatingActionButton(theme, isDark);
    }

    return _buildRegularButton(theme, isDark);
  }

  Widget _buildRegularButton(ThemeData theme, bool isDark) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: _elevationAnimation.value * 2,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
              ],
            ),
            child: Material(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 24 : 32,
                    vertical: widget.isMobile ? 16 : 20,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.explore_rounded,
                          color: Colors.white,
                          size: widget.isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: widget.isMobile ? 12 : 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start Virtual Tour',
                            style: GoogleFonts.roboto(
                              fontSize: widget.isMobile ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Explore in 360°',
                            style: GoogleFonts.roboto(
                              fontSize: widget.isMobile ? 11 : 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: widget.isMobile ? 8 : 12),
                      AnimatedRotation(
                        turns: _isHovered ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: widget.isMobile ? 20 : 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme, bool isDark) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: _elevationAnimation.value * 2,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: widget.onPressed,
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              elevation: _elevationAnimation.value,
              icon: const Icon(Icons.explore_rounded),
              label: Text(
                'Start Tour',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}