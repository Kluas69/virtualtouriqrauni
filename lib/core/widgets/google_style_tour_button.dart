import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // Start continuous glow animation
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
      HapticFeedback.lightImpact();
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
        animation: Listenable.merge([_elevationAnimation, _glowAnimation]),
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                  theme.primaryColor.withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: _elevationAnimation.value * 2,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: _glowAnimation.value * 0.5),
                  blurRadius: _elevationAnimation.value * 3,
                  offset: const Offset(0, 0),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: _glowAnimation.value * 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed();
                },
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: _glowAnimation.value * 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.view_in_ar_rounded, // Changed to 3D/VR icon
                          color: Colors.white,
                          size: widget.isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: widget.isMobile ? 12 : 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.isMobile ? 'Play Tour' : 'Play Campus Tour', // Shorter text for mobile
                              style: GoogleFonts.orbitron( // Changed to futuristic font
                                fontSize: widget.isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: widget.isMobile ? 0.8 : 1.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: _glowAnimation.value * 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.isMobile ? '3D Gaming Experience' : 'Explore in 3D Gaming Experience', // Shorter subtitle for mobile
                              style: GoogleFonts.roboto(
                                fontSize: widget.isMobile ? 11 : 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: widget.isMobile ? 8 : 12),
                      AnimatedRotation(
                        turns: _isHovered ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: _glowAnimation.value * 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: widget.isMobile ? 20 : 24,
                          ),
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
        animation: Listenable.merge([_elevationAnimation, _glowAnimation]),
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: _elevationAnimation.value * 2,
                  offset: Offset(0, _elevationAnimation.value / 2),
                ),
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: _glowAnimation.value * 0.5),
                  blurRadius: _elevationAnimation.value * 3,
                  offset: const Offset(0, 0),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: _glowAnimation.value * 0.3),
                width: 1.5,
              ),
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: _glowAnimation.value * 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: const Icon(Icons.view_in_ar_rounded),
              ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Start Tour',
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: _glowAnimation.value * 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
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
}