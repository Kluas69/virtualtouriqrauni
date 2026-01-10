import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:virtualtouriu/core/widgets/tag_badge.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';

class EnhancedExploreSection extends StatelessWidget {
  final bool isMobile;

  const EnhancedExploreSection({
    super.key,
    required this.isMobile,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark 
                ? Colors.white.withValues(alpha: 0.03)
                : theme.primaryColor.withValues(alpha: 0.02),
            isDark 
                ? theme.primaryColor.withValues(alpha: 0.05)
                : Colors.blue.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(
          isSmallMobile ? 20 : isMediumMobile ? 22 : isMobile ? 24 : isTablet ? 28 : 32
        ),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSmallMobile ? 16 : isMediumMobile ? 20 : isMobile ? 24 : 32,
            offset: Offset(0, isSmallMobile ? 4 : isMediumMobile ? 6 : isMobile ? 8 : 12),
          ),
        ],
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
          
          SizedBox(height: isMobile 
              ? (isSmallMobile ? 20 : isMediumMobile ? 22 : 24) 
              : isTablet ? 32 : 40),
          
          // Call to Action Button
          _buildCallToActionButton(theme, isDark, size, isTablet, isDesktop, isSmallMobile, isMediumMobile, context),
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
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(
                isSmallMobile ? 16 : isMediumMobile ? 18 : 20
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
              theme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(
            isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 24 : 28
          ),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
              blurRadius: isSmallMobile ? 16 : isMediumMobile ? 20 : isMobile ? 24 : isTablet ? 28 : 32,
              offset: Offset(0, isSmallMobile ? 8 : isMediumMobile ? 10 : isMobile ? 12 : isTablet ? 14 : 16),
            ),
          ],
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
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
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
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  isSmallMobile ? 16 : isMediumMobile ? 18 : 20
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: isSmallMobile ? 16 : isMediumMobile ? 18 : 20,
                    offset: const Offset(0, 10),
                  ),
                ],
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              isDark 
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.01),
            ],
          ),
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
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: 0.2),
                theme.primaryColor.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(
              isSmallMobile ? 12 : isMediumMobile ? 13 : isMobile ? 14 : 16
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
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
    return FadeInUp(
      duration: const Duration(milliseconds: 950),
      delay: const Duration(milliseconds: 350),
      child: Center(
        child: Container(
          width: isMobile ? double.infinity : isTablet ? 300 : 350,
          height: isSmallMobile ? 52 : isMediumMobile ? 56 : isMobile ? 60 : isTablet ? 64 : 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(
              isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 22 : 24
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.4),
                blurRadius: isSmallMobile ? 16 : isMediumMobile ? 20 : isMobile ? 24 : 28,
                offset: Offset(0, isSmallMobile ? 6 : isMediumMobile ? 8 : isMobile ? 10 : 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => HomeScreen.navigateToGame(context),
              borderRadius: BorderRadius.circular(
                isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : isTablet ? 22 : 24
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 20 : isMediumMobile ? 24 : isMobile ? 28 : 32,
                  vertical: isSmallMobile ? 16 : isMediumMobile ? 18 : isMobile ? 20 : 22,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled_rounded,
                      size: isSmallMobile ? 24 : isMediumMobile ? 26 : isMobile ? 28 : isTablet ? 30 : 32,
                      color: Colors.white,
                    ),
                    SizedBox(width: isSmallMobile ? 10 : isMediumMobile ? 12 : 14),
                    Text(
                      'Play Campus Tour',
                      style: GoogleFonts.roboto(
                        fontSize: isSmallMobile ? 16 : isMediumMobile ? 17 : isMobile ? 18 : isTablet ? 19 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: isSmallMobile ? 8 : isMediumMobile ? 10 : 12),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: isSmallMobile ? 20 : isMediumMobile ? 22 : isMobile ? 24 : isTablet ? 26 : 28,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}