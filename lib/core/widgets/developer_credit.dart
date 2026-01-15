import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../design/app_spacing.dart';

/// Developer credit widget with Google Material Design 3 aesthetics
/// Clean, minimal, and responsive design matching current theme
class DeveloperCredit extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  
  const DeveloperCredit({
    super.key,
    required this.isDark,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _getMaxWidth(size),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: _getHorizontalMargin(size),
              vertical: _getVerticalMargin(size),
            ),
            padding: EdgeInsets.all(_getPadding(size)),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(_getBorderRadius(size)),
              border: Border.all(
                color: _getBorderColor(),
                width: 0.5,
              ),
              boxShadow: _buildShadows(size),
            ),
            child: _buildContent(context, theme, size),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return _buildMobileLayout(theme, size);
    } else {
      return _buildDesktopLayout(theme, size);
    }
  }

  Widget _buildMobileLayout(ThemeData theme, Size size) {
    return Row(
      children: [
        // Icon container - Google Material Design 3 style
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.code_rounded,
            size: 22,
            color: theme.primaryColor,
          ),
        ),
        
        const SizedBox(width: 14),
        
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Designed & Built by Zahid & Muez ',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  height: 1.2,
                  color: isDark 
                      ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                      : const Color(0xFF1C1B1F),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Flutter & Three.js Developer',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  height: 1.3,
                  letterSpacing: 0.1,
                  color: isDark 
                      ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                      : const Color(0xFF49454F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Tech badges - minimal for mobile
        _buildMobileTechBadges(),
      ],
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, Size size) {
    return Column(
      children: [
        Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.code_rounded,
                size: 24,
                color: theme.primaryColor,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Designed & Built by Zahid & Muez',
                    style: GoogleFonts.roboto(
                      fontSize: _getTitleFontSize(size),
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      height: 1.2,
                      color: isDark 
                          ? const Color(0xFFE6E1E5)
                          : const Color(0xFF1C1B1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crafting immersive digital experiences with modern web technologies',
                    style: GoogleFonts.roboto(
                      fontSize: _getSubtitleFontSize(size),
                      height: 1.4,
                      letterSpacing: 0.1,
                      color: isDark 
                          ? const Color(0xFF938F99)
                          : const Color(0xFF49454F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: _getContentSpacing(size)),
        
        // Tech stack badges - Google style
        _buildDesktopTechBadges(size),
      ],
    );
  }

  Widget _buildMobileTechBadges() {
    final badges = [
      _TechBadge('Flutter', const Color(0xFF4285F4)), // Google Blue
      _TechBadge('Three.js', const Color(0xFF34A853)), // Google Green
      _TechBadge('3D', const Color(0xFFFF9800)), // Material Orange
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges.map((badge) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: badge.color.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        child: Text(
          badge.name,
          style: GoogleFonts.roboto(
            fontSize: 9,
            color: badge.color,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDesktopTechBadges(Size size) {
    final badges = [
      _TechBadge('Flutter', const Color(0xFF4285F4)), // Google Blue
      _TechBadge('Three.js', const Color(0xFF34A853)), // Google Green
      _TechBadge('Maya', const Color(0xFF00B4D8)), // Maya Cyan
      _TechBadge('Unity', const Color(0xFFFF6B35)), // Unity Orange
      _TechBadge('Substance', const Color(0xFFE63946)), // Substance Red
      _TechBadge('3D', const Color(0xFFFF9800)), // Material Orange
      _TechBadge('WebGL', const Color(0xFF9C27B0)), // Material Purple
      _TechBadge('Firebase', const Color(0xFFFF5722)), // Material Deep Orange
      _TechBadge('Dart', const Color(0xFF0175C2)), // Dart Blue
      _TechBadge('JavaScript', const Color(0xFFF7DF1E)), // JavaScript Yellow
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: badges.map((badge) => _buildTechBadge(badge, size)).toList(),
    );
  }

  Widget _buildTechBadge(_TechBadge badge, Size size) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width < AppSpacing.tabletBreakpoint ? 8 : 10,
        vertical: size.width < AppSpacing.tabletBreakpoint ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badge.color.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Text(
        badge.name,
        style: GoogleFonts.roboto(
          fontSize: size.width < AppSpacing.tabletBreakpoint ? 10 : 11,
          color: badge.color,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Responsive sizing methods
  double _getMaxWidth(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return double.infinity;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 600;
    } else {
      return 800;
    }
  }

  double _getHorizontalMargin(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 16;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 24;
    } else {
      return 32;
    }
  }

  double _getVerticalMargin(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 12;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 16;
    } else {
      return 20;
    }
  }

  double _getPadding(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 16;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 20;
    } else {
      return 24;
    }
  }

  double _getBorderRadius(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 16;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 18;
    } else {
      return 20;
    }
  }

  double _getTitleFontSize(Size size) {
    if (size.width < AppSpacing.tabletBreakpoint) {
      return 16;
    } else if (size.width < 1200) {
      return 18;
    } else {
      return 20;
    }
  }

  double _getSubtitleFontSize(Size size) {
    if (size.width < AppSpacing.tabletBreakpoint) {
      return 13;
    } else if (size.width < 1200) {
      return 14;
    } else {
      return 15;
    }
  }

  double _getContentSpacing(Size size) {
    if (size.width < AppSpacing.tabletBreakpoint) {
      return 12;
    } else {
      return 16;
    }
  }

  // Theme-aware colors matching Material Design 3
  Color _getBackgroundColor() {
    if (isDark) {
      return const Color(0xFF1C1B1F); // Material Design 3 dark surface
    } else {
      return const Color(0xFFFFFBFE); // Material Design 3 light surface
    }
  }

  Color _getBorderColor() {
    if (isDark) {
      return const Color(0xFF49454F).withValues(alpha: 0.12); // Material Design 3 outline
    } else {
      return const Color(0xFF79747E).withValues(alpha: 0.12);
    }
  }

  List<BoxShadow> _buildShadows(Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google Material Design 3 mobile shadows - minimal
      return [
        BoxShadow(
          color: isDark 
              ? Colors.black.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    } else {
      // Google Material Design 3 desktop/tablet shadows
      return [
        BoxShadow(
          color: isDark 
              ? Colors.black.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
  }
}

class _TechBadge {
  final String name;
  final Color color;
  
  const _TechBadge(this.name, this.color);
}