import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:virtualtouriu/core/navigation/navigation_helpers.dart';

class CampusTourSection extends StatelessWidget {
  final bool isMobile;
  final bool showButton;

  const CampusTourSection({
    super.key,
    required this.isMobile,
    this.showButton = true, // Default to showing button
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Google Material Design 3 responsive breakpoints
    final isSmallMobile = size.width < 360;
    final isMediumMobile = size.width >= 360 && size.width < 414;
    final isLargeMobile = size.width >= 414 && size.width < 768;
    final isTablet = size.width >= 768 && size.width < 1024;
    final isDesktop = size.width >= 1024;
    
    // Google-style responsive padding
    final horizontalPadding = isSmallMobile 
        ? 16.0
        : isMediumMobile 
            ? 20.0
            : isLargeMobile 
                ? 24.0
                : isTablet 
                    ? 32.0
                    : 40.0;
    
    final verticalPadding = isMobile 
        ? (isSmallMobile ? 24.0 : isMediumMobile ? 28.0 : 32.0)
        : isTablet ? 40.0 : 48.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 16.0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          isSmallMobile ? 20 : isMediumMobile ? 22 : isMobile ? 24 : isTablet ? 28 : 32
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Google Material Design 3 styling
          _buildHeaderSection(theme, isDark, size, isTablet, isDesktop, isSmallMobile, isMediumMobile),
          
          SizedBox(height: isMobile 
              ? (isSmallMobile ? 20 : isMediumMobile ? 22 : 24) 
              : isTablet ? 32 : 40),
          
          // Main Feature Highlight
          _buildMainFeatureHighlight(theme, isDark, size, isTablet, isDesktop, isSmallMobile, isMediumMobile, context),
          
          SizedBox(height: isMobile 
              ? (isSmallMobile ? 20 : isMediumMobile ? 22 : 24) 
              : isTablet ? 32 : 40),
          
          // Features Grid
          _buildFeaturesGrid(theme, isDark, size, isTablet, isDesktop, isSmallMobile, isMediumMobile),
          
          // Conditionally show the Call to Action Button
          if (showButton) ...[
            SizedBox(height: isMobile 
                ? (isSmallMobile ? 20 : isMediumMobile ? 22 : 24) 
                : isTablet ? 32 : 40),
            
            // Call to Action Button
            _buildCallToActionButton(theme, isDark, size, isTablet, isDesktop, isSmallMobile, isMediumMobile, context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme, bool isDark, Size size, bool isTablet, bool isDesktop, bool isSmallMobile, bool isMediumMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Google Material Design 3 badge
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 12 : isMediumMobile ? 14 : 16,
              vertical: isSmallMobile ? 6 : isMediumMobile ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(
                isSmallMobile ? 16 : isMediumMobile ? 18 : 20
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school_rounded,
                  size: isSmallMobile ? 14 : isMediumMobile ? 15 : 16,
                  color: Colors.white,
                ),
                SizedBox(width: isSmallMobile ? 6 : 8),
                Text(
                  '3D CAMPUS EXPERIENCE',
                  style: GoogleFonts.roboto(
                    fontSize: isSmallMobile ? 10 : isMediumMobile ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 24 : 28),
        
        // Main title with Google Material Design 3 typography
        FadeInUp(
          duration: const Duration(milliseconds: 700),
          delay: const Duration(milliseconds: 100),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                isDark ? Colors.white : Colors.black87,
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Explore IQRA University',
              style: GoogleFonts.roboto(
                fontSize: isSmallMobile ? 28 : isMediumMobile ? 32 : isMobile ? 36 : isTablet ? 42 : 48,
                fontWeight: FontWeight.w900,
                color: Colors.white, // This will be masked by the shader
                height: 1.1,
                letterSpacing: isSmallMobile ? -0.5 : isMobile ? -0.8 : -1.0,
              ),
            ),
          ),
        ),
        
        SizedBox(height: isSmallMobile ? 8 : isMediumMobile ? 10 : isMobile ? 12 : isTablet ? 14 : 16),
        
        // Description with Google Material Design 3 body text
        FadeInUp(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 200),
          child: Container(
            width: isMobile ? double.infinity : isTablet ? size.width * 0.8 : 700,
            child: Text(
              isMobile 
                  ? 'Step into our H-9 Islamabad campus through an immersive 3D gaming experience. Navigate with professional FPS controls and explore every corner of our world-class facilities.'
                  : 'Step into our H-9 Islamabad campus through an immersive 3D virtual reality experience powered by Three.js. Navigate seamlessly through classrooms, labs, and facilities with realistic WebGL rendering and professional gaming controls.',
              style: GoogleFonts.roboto(
                fontSize: isSmallMobile ? 14 : isMediumMobile ? 15 : isMobile ? 16 : isTablet ? 18 : 20,
                height: 1.6,
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                letterSpacing: 0.2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFeatureHighlight(ThemeData theme, bool isDark, Size size, bool isTablet, bool isDesktop, bool isSmallMobile, bool isMediumMobile, BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 850),
      delay: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          isSmallMobile ? 20 : isMediumMobile ? 22 : isMobile ? 24 : isTablet ? 28 : 32
        ),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.05)
              : theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(
            isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 24 : 28
          ),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: isDesktop ? _buildDesktopFeatureLayout(theme, isDark) : _buildMobileTabletFeatureLayout(theme, isDark, isTablet, isSmallMobile, isMediumMobile),
      ),
    );
  }

  Widget _buildDesktopFeatureLayout(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Enhanced icon section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.threed_rotation_rounded,
            size: 72,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(width: 40),
        
        // Content section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Three.js Powered 3D Experience',
                style: GoogleFonts.roboto(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Navigate through our campus using advanced WebGL rendering with Three.js. Experience realistic 3D environments with first-person controls, interactive hotspots, and optimized performance across all devices.',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletFeatureLayout(ThemeData theme, bool isDark, bool isTablet, bool isSmallMobile, bool isMediumMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced icon with gaming theme
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                isSmallMobile ? 16 : isMediumMobile ? 18 : isTablet ? 22 : 20
              ),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(
                  isSmallMobile ? 16 : isMediumMobile ? 18 : 20
                ),
              ),
              child: Icon(
                Icons.gamepad_rounded,
                size: isSmallMobile ? 36 : isMediumMobile ? 40 : isTablet ? 52 : 44,
                color: Colors.white,
              ),
            ),
            if (isMobile) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'GAMING MODE',
                        style: GoogleFonts.roboto(
                          fontSize: isSmallMobile ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Professional FPS Controls',
                      style: GoogleFonts.roboto(
                        fontSize: isSmallMobile ? 13 : isMediumMobile ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        
        SizedBox(height: isSmallMobile ? 18 : isMediumMobile ? 20 : isTablet ? 24 : 20),
        
        // Enhanced title
        Text(
          isMobile ? 'Professional 3D Campus Experience' : 'Three.js Powered 3D Experience',
          style: GoogleFonts.roboto(
            fontSize: isSmallMobile ? 22 : isMediumMobile ? 24 : isMobile ? 26 : isTablet ? 30 : 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            height: 1.2,
          ),
        ),
        
        SizedBox(height: isSmallMobile ? 8 : isMediumMobile ? 10 : isTablet ? 14 : 12),
        
        // Enhanced description
        Text(
          isMobile 
              ? 'Experience our campus like never before with professional FPS-style controls. Use WASD for movement, mouse for camera control, and explore every corner of our facilities in stunning 3D detail with realistic lighting and physics.'
              : 'Navigate through our campus using advanced WebGL rendering with Three.js. Experience realistic 3D environments with first-person controls, interactive hotspots, and optimized performance.',
          style: GoogleFonts.roboto(
            fontSize: isSmallMobile ? 14 : isMediumMobile ? 15 : isMobile ? 16 : isTablet ? 17 : 16,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(ThemeData theme, bool isDark, Size size, bool isTablet, bool isDesktop, bool isSmallMobile, bool isMediumMobile) {
    return FadeInUp(
      duration: const Duration(milliseconds: 900),
      delay: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 24 : 28,
          vertical: isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 22 : 24,
        ),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(
            isSmallMobile ? 12 : isMediumMobile ? 14 : isMobile ? 16 : isTablet ? 20 : 24
          ),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: isDesktop 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureItem(theme, Icons.web_rounded, 'WebGL', 'Hardware Accelerated', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                  _buildDivider(isDark),
                  _buildFeatureItem(theme, Icons.gamepad_rounded, 'WASD', 'Gaming Controls', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                  _buildDivider(isDark),
                  _buildFeatureItem(theme, Icons.speed_rounded, 'Optimized', 'Mobile Performance', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                ],
              )
            : isTablet
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureItem(theme, Icons.web_rounded, 'WebGL', 'Hardware Accelerated', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                      _buildDivider(isDark),
                      _buildFeatureItem(theme, Icons.gamepad_rounded, 'WASD', 'Controls', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                      _buildDivider(isDark),
                      _buildFeatureItem(theme, Icons.speed_rounded, 'Optimized', 'Performance', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureItem(theme, Icons.web_rounded, 'WebGL', 'Hardware Accelerated', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFeatureItem(theme, Icons.gamepad_rounded, 'WASD', 'Gaming Controls', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureItem(theme, Icons.speed_rounded, 'Optimized', 'Mobile Performance', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFeatureItem(theme, Icons.fullscreen_rounded, 'Fullscreen', 'Immersive Mode', isTablet, isDesktop, isSmallMobile, isMediumMobile),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, IconData icon, String value, String label, bool isTablet, bool isDesktop, bool isSmallMobile, bool isMediumMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(
            isSmallMobile ? 12 : isMediumMobile ? 13 : isMobile ? 14 : isTablet ? 16 : 18
          ),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              isSmallMobile ? 12 : isMediumMobile ? 13 : isMobile ? 14 : 16
            ),
          ),
          child: Icon(
            icon,
            size: isSmallMobile ? 22 : isMediumMobile ? 24 : isMobile ? 26 : isTablet ? 28 : 30,
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: isSmallMobile ? 8 : isMobile ? 10 : 12),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: isSmallMobile ? 18 : isMediumMobile ? 19 : isMobile ? 20 : isTablet ? 22 : 24,
            fontWeight: FontWeight.w800,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: isSmallMobile ? 11 : isMediumMobile ? 12 : isMobile ? 13 : isTablet ? 14 : 15,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 50,
      color: isDark 
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
    );
  }

  Widget _buildCallToActionButton(ThemeData theme, bool isDark, Size size, bool isTablet, bool isDesktop, bool isSmallMobile, bool isMediumMobile, BuildContext context) {
    // Calculate responsive font size based on screen width and text scale factor
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final baseSize = isSmallMobile 
        ? 14.0 
        : isMediumMobile 
            ? 15.0 
            : isMobile 
                ? 16.0 
                : isTablet 
                    ? 17.0 
                    : 18.0;
    
    // Adjust for user's text scale preference but keep it reasonable
    final responsiveFontSize = baseSize / textScaleFactor.clamp(0.8, 1.3);
    
    // Ensure minimum readable size
    final finalFontSize = responsiveFontSize.clamp(12.0, 22.0);
    
    return FadeInUp(
      duration: const Duration(milliseconds: 950),
      delay: const Duration(milliseconds: 350),
      child: Center(
        child: _FuturisticTourButton(
          width: isMobile ? double.infinity : isTablet ? 300 : 350,
          height: isSmallMobile ? 52 : isMediumMobile ? 56 : isMobile ? 60 : isTablet ? 64 : 68,
          borderRadius: isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 22 : 24,
          iconSize: isSmallMobile ? 24 : isMediumMobile ? 26 : isMobile ? 28 : isTablet ? 30 : 32,
          fontSize: finalFontSize,
          horizontalPadding: isSmallMobile ? 20 : isMediumMobile ? 24 : isMobile ? 28 : 32,
          verticalPadding: isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : 22,
          spacing: isSmallMobile ? 10 : isMediumMobile ? 12 : 14,
          arrowSize: isSmallMobile ? 20 : isMediumMobile ? 22 : isMobile ? 24 : isTablet ? 26 : 28,
          theme: theme,
          isDark: isDark,
          onPressed: () => NavigationHelpers.navigateToGame(context),
        ),
      ),
    );
  }
}

// Enhanced Futuristic Tour Button Widget
class _FuturisticTourButton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double spacing;
  final double arrowSize;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onPressed;

  const _FuturisticTourButton({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.iconSize,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.spacing,
    required this.arrowSize,
    required this.theme,
    required this.isDark,
    required this.onPressed,
  });

  @override
  State<_FuturisticTourButton> createState() => _FuturisticTourButtonState();
}

class _FuturisticTourButtonState extends State<_FuturisticTourButton>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;
  late Animation<Color?> _gradientAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Initialize animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation = ColorTween(
      begin: widget.theme.primaryColor,
      end: widget.theme.primaryColor.withValues(alpha: 0.8),
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    // Start continuous animations
    _glowController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverController,
        _pressController,
        _glowController,
        _particleController,
      ]),
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onPressed,
            child: Transform.scale(
              scale: _scaleAnimation.value * (1.0 - (_pressController.value * 0.05)),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    // Main shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                    // Glow effect
                    BoxShadow(
                      color: widget.theme.primaryColor.withValues(alpha: _glowAnimation.value * 0.5),
                      blurRadius: _elevationAnimation.value * 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.theme.primaryColor,
                            widget.theme.primaryColor.withValues(alpha: 0.8),
                            widget.theme.primaryColor.withValues(alpha: 0.9),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    
                    // Animated border glow
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: _glowAnimation.value * 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    
                    // Particle effects overlay
                    ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: CustomPaint(
                        painter: _ParticleEffectPainter(
                          animation: _particleAnimation.value,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        size: Size(widget.width, widget.height),
                      ),
                    ),
                    
                    // Button content
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: InkWell(
                        onTap: widget.onPressed,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.horizontalPadding,
                            vertical: widget.verticalPadding,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 3D/VR Icon with glow
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: _glowAnimation.value * 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.view_in_ar_rounded,
                                  size: widget.iconSize,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: widget.spacing),
                              
                              // Text with futuristic font - Enhanced Responsive
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.width < 280 ? 'Play Tour' : 'Play Campus Tour', // Shorter text for very small screens
                                    style: GoogleFonts.orbitron(
                                      fontSize: widget.fontSize,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: widget.fontSize * 0.06, // Responsive letter spacing
                                      shadows: [
                                        Shadow(
                                          color: Colors.white.withValues(alpha: _glowAnimation.value * 0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              SizedBox(width: widget.spacing * 0.8),
                              
                              // Animated arrow
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
                                    size: widget.arrowSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Holographic ring effect
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              color: Colors.cyan.withValues(alpha: 0.4),
                              width: 2,
                            ),
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
    );
  }
}

// Custom painter for particle effects
class _ParticleEffectPainter extends CustomPainter {
  final double animation;
  final Color color;

  _ParticleEffectPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create floating particles
    for (int i = 0; i < 8; i++) {
      final progress = (animation + (i * 0.125)) % 1.0;
      final x = (size.width * 0.2) + (size.width * 0.6 * progress);
      final y = size.height * 0.5 + (20 * (0.5 - progress).abs());
      final radius = 2.0 * (1.0 - progress);
      
      if (radius > 0.5) {
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint..color = color.withValues(alpha: color.alpha * (1.0 - progress)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}