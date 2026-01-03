import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:virtualtouriu/core/widgets/google_style_tour_button.dart';
import 'package:virtualtouriu/core/widgets/tag_badge.dart';

class EnhancedExploreSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onTourPressed;

  const EnhancedExploreSection({
    super.key,
    required this.isMobile,
    required this.onTourPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Responsive breakpoints
    final isTablet = size.width >= 768 && size.width < 1024;
    final isDesktop = size.width >= 1024;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * (isMobile ? 0.06 : isTablet ? 0.08 : 0.10),
        vertical: isMobile ? 32 : isTablet ? 40 : 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeaderSection(theme, isDark, size, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 24 : isTablet ? 32 : 40),
          
          // Main 3D Tour Feature
          _buildMainFeature(theme, isDark, size, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 24 : isTablet ? 32 : 40),
          
          // 3D Tour Features Grid
          _build3DTourFeatures(theme, isDark, size, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 32 : isTablet ? 40 : 48),
          
          // Tour Button
          _buildTourButtonSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme, bool isDark, Size size, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: TagBadge(
            text: '3D VIRTUAL TOUR',
            fontSize: isMobile ? 11 : isTablet ? 12 : 13,
          ),
        ),
        SizedBox(height: isMobile ? 16 : isTablet ? 20 : 24),
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
                fontSize: isMobile ? 28 : isTablet ? 42 : 56,
                fontWeight: FontWeight.w900,
                color: Colors.white, // This will be masked by the shader
                height: 1.1,
                letterSpacing: isMobile ? -0.5 : -1.0,
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 8 : isTablet ? 10 : 12),
        FadeInUp(
          duration: const Duration(milliseconds: 800),
          delay: const Duration(milliseconds: 200),
          child: SizedBox(
            width: isMobile ? double.infinity : isTablet ? size.width * 0.7 : 600,
            child: Text(
              'Step into our H-9 Islamabad campus through immersive 3D virtual reality powered by Three.js. Navigate seamlessly through classrooms, labs, and facilities with realistic WebGL rendering.',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : isTablet ? 16 : 18,
                height: 1.6,
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainFeature(ThemeData theme, bool isDark, Size size, bool isTablet, bool isDesktop) {
    return FadeInUp(
      duration: const Duration(milliseconds: 850),
      delay: const Duration(milliseconds: 250),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 20 : isTablet ? 28 : 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withValues(alpha: 0.12),
              theme.primaryColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 16 : isTablet ? 20 : 24),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.08),
              blurRadius: isMobile ? 16 : isTablet ? 24 : 32,
              offset: Offset(0, isMobile ? 8 : isTablet ? 12 : 16),
            ),
          ],
        ),
        child: isDesktop ? _buildDesktopFeatureLayout(theme, isDark) : _buildMobileTabletFeatureLayout(theme, isDark, isTablet),
      ),
    );
  }

  Widget _buildDesktopFeatureLayout(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Icon Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.threed_rotation,
            size: 64,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(width: 32),
        
        // Content Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Three.js Powered 3D Experience',
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Navigate through our campus using advanced WebGL rendering with Three.js. Experience realistic 3D environments with first-person controls, interactive hotspots, and optimized performance across all devices.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
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

  Widget _buildMobileTabletFeatureLayout(ThemeData theme, bool isDark, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(isTablet ? 18 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.threed_rotation,
            size: isTablet ? 48 : 40,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: isTablet ? 20 : 16),
        
        // Title
        Text(
          'Three.js Powered 3D Experience',
          style: GoogleFonts.roboto(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1.2,
          ),
        ),
        
        SizedBox(height: isTablet ? 12 : 8),
        
        // Description
        Text(
          'Navigate through our campus using advanced WebGL rendering with Three.js. Experience realistic 3D environments with first-person controls and interactive hotspots.',
          style: GoogleFonts.roboto(
            fontSize: isTablet ? 15 : 14,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _build3DTourFeatures(ThemeData theme, bool isDark, Size size, bool isTablet, bool isDesktop) {
    return FadeInUp(
      duration: const Duration(milliseconds: 900),
      delay: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : isTablet ? 20 : 24,
          vertical: isMobile ? 16 : isTablet ? 18 : 20,
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
          borderRadius: BorderRadius.circular(isMobile ? 12 : isTablet ? 16 : 20),
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: isDesktop 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureItem(theme, Icons.web, 'WebGL', 'Hardware Accelerated', isTablet, isDesktop),
                  _buildDivider(isDark),
                  _buildFeatureItem(theme, Icons.gamepad, 'WASD', 'First-Person Controls', isTablet, isDesktop),
                  _buildDivider(isDark),
                  _buildFeatureItem(theme, Icons.memory, 'Optimized', 'Mobile Performance', isTablet, isDesktop),
                ],
              )
            : isTablet
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureItem(theme, Icons.web, 'WebGL', 'Hardware Accelerated', isTablet, isDesktop),
                      _buildDivider(isDark),
                      _buildFeatureItem(theme, Icons.gamepad, 'WASD', 'Controls', isTablet, isDesktop),
                      _buildDivider(isDark),
                      _buildFeatureItem(theme, Icons.memory, 'Optimized', 'Performance', isTablet, isDesktop),
                    ],
                  )
                : Column(
                    children: [
                      _buildFeatureItem(theme, Icons.web, 'WebGL', 'Hardware Accelerated Rendering', isTablet, isDesktop),
                      const SizedBox(height: 16),
                      _buildFeatureItem(theme, Icons.gamepad, 'WASD', 'First-Person Controls', isTablet, isDesktop),
                      const SizedBox(height: 16),
                      _buildFeatureItem(theme, Icons.memory, 'Optimized', 'Mobile Performance', isTablet, isDesktop),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, IconData icon, String value, String label, bool isTablet, bool isDesktop) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 10 : isTablet ? 11 : 12),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          ),
          child: Icon(
            icon,
            size: isMobile ? 20 : isTablet ? 22 : 24,
            color: theme.primaryColor,
          ),
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 18 : isTablet ? 20 : 22,
            fontWeight: FontWeight.w800,
            color: theme.primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 11 : isTablet ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      color: isDark 
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
    );
  }

  Widget _buildTourButtonSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 950),
      delay: const Duration(milliseconds: 350),
      child: Center(
        child: GoogleStyleTourButton(
          isMobile: isMobile,
          onPressed: onTourPressed,
        ),
      ),
    );
  }
}