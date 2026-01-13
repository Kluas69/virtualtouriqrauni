import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../animation/animation_config.dart';
import '../state/ui_state.dart';
import '../design/app_spacing.dart';
import '../../Screens/categories.dart';
import '../../Screens/about_university_screen.dart';


/// Quick action model for grid items
class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  const QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });
}

/// Quick actions grid with animated icons and glassmorphic styling
class QuickActionsGrid extends StatelessWidget {
  final bool isDark;
  final Function(QuickAction) onActionTapped;
  final EdgeInsets? padding;
  final double? spacing;

  const QuickActionsGrid({
    super.key,
    required this.isDark,
    required this.onActionTapped,
    this.padding,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getQuickActions(context);
    final size = MediaQuery.of(context).size;
    
    return Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: size.width < AppSpacing.mobileBreakpoint 
            ? 16.0 
            : size.width < AppSpacing.tabletBreakpoint 
                ? 24.0 
                : 32.0,
        vertical: size.width < AppSpacing.mobileBreakpoint ? 16.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with enhanced typography matching Campus Locations style
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                isDark ? Colors.white : Colors.black87,
                Theme.of(context).primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Explore Campus',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: _getTitleFontSize(size),
                letterSpacing: -0.5,
                height: 1.2,
                color: Colors.white, // This will be masked by the shader
              ),
            ),
          ),
          SizedBox(height: size.width < AppSpacing.mobileBreakpoint ? 8 : 12),
          Text(
            'Discover IQRA University through interactive experiences',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: _getSubtitleFontSize(size),
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: size.width < AppSpacing.mobileBreakpoint ? 20 : 32),
          
          // Enhanced actions grid
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveGrid(context, actions, size);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, List<QuickAction> actions, Size size) {
    // Google-style responsive design optimized for 2 cards
    int crossAxisCount;
    double childAspectRatio;
    double spacing;
    double maxWidth;
    
    if (size.width < AppSpacing.mobileBreakpoint) {
      // Mobile: Single column with Google-style horizontal cards
      crossAxisCount = 1;
      childAspectRatio = 5.0; // Wider for better mobile experience
      spacing = 12.0;
      maxWidth = double.infinity;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      // Tablet: 2 cards in a row for perfect balance
      crossAxisCount = 2;
      childAspectRatio = 2.2; // Balanced ratio for 2 cards
      spacing = 16.0;
      maxWidth = 600; // Constrain width for better appearance
    } else if (size.width < 1200) {
      // Small desktop: 2 cards in a row
      crossAxisCount = 2;
      childAspectRatio = 2.8; // Balanced cards for desktop
      spacing = 20.0;
      maxWidth = 700; // Constrain width
    } else {
      // Large desktop: 2 cards in a row with maximum width constraint
      crossAxisCount = 2;
      childAspectRatio = 3.2; // Wider cards for large screens
      spacing = 24.0;
      maxWidth = 800; // Maximum width for better UX
    }
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return EnhancedQuickActionCard(
              action: actions[index],
              isDark: isDark,
              index: index,
              onTap: () => onActionTapped(actions[index]),
            );
          },
        ),
      ),
    );
  }

  double _getTitleFontSize(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 24;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 28;
    } else {
      return 32;
    }
  }

  double _getSubtitleFontSize(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 12;
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 14;
    } else {
      return 16;
    }
  }

  List<QuickAction> _getQuickActions(BuildContext context) {
    return [
      QuickAction(
        title: 'Campus Locations',
        subtitle: 'Browse all locations',
        icon: Icons.location_on_rounded,
        color: const Color(0xFF34A853), // Google Green
        tooltip: 'Explore different campus locations and facilities',
        onTap: () {
          // Navigate to categories screen to browse locations
          _showLoadingAndNavigate(context, CategoriesScreen(), 'categories');
        },
      ),
      QuickAction(
        title: 'About IQRA',
        subtitle: 'University information',
        icon: Icons.school_rounded,
        color: const Color(0xFFFF9800), // Material Orange
        tooltip: 'Learn about IQRA University history and achievements',
        onTap: () {
          // Navigate to about university page
          _showLoadingAndNavigate(context, AboutUniversityScreen(), 'about_university');
        },
      ),
    ];
  }

  // Direct navigation without loading dialogs (loading only in categories screen)
  static Future<void> _showLoadingAndNavigate(BuildContext context, Widget screen, String screenName) async {
    // Direct navigation for all platforms - no loading dialogs
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
        settings: RouteSettings(name: '/$screenName'),
      ),
    );
  }
}

/// Simple and elegant quick action card without complex animations
class EnhancedQuickActionCard extends StatefulWidget {
  final QuickAction action;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const EnhancedQuickActionCard({
    super.key,
    required this.action,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  @override
  State<EnhancedQuickActionCard> createState() => _EnhancedQuickActionCardState();
}

class _EnhancedQuickActionCardState extends State<EnhancedQuickActionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    // Update global state
    context.read<UIState>().setHoveredActionIndex(
      isHovered ? widget.index : -1,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    
    // Light haptic feedback
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    
    widget.onTap();
    widget.action.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Consumer<UIState>(
      builder: (context, state, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: _isPressed 
              ? (Matrix4.identity()..setEntry(0, 0, 0.98)..setEntry(1, 1, 0.98))
              : Matrix4.identity(),
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: _getCardHeight(size),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    size.width < AppSpacing.mobileBreakpoint ? 16 : 
                    size.width < AppSpacing.tabletBreakpoint ? 18 : 20,
                  ),
                  boxShadow: _buildSimpleShadows(),
                ),
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(
                    size.width < AppSpacing.mobileBreakpoint ? 16 : 
                    size.width < AppSpacing.tabletBreakpoint ? 18 : 20,
                  ),
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.all(
                      size.width < AppSpacing.mobileBreakpoint ? 14 : 
                      size.width < AppSpacing.tabletBreakpoint ? 20 : 24,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        size.width < AppSpacing.mobileBreakpoint ? 16 : 
                        size.width < AppSpacing.tabletBreakpoint ? 18 : 20,
                      ),
                      color: _buildCardColor(),
                      border: _buildCardBorder(),
                    ),
                    child: _buildCardContent(size),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getCardHeight(Size size) {
    if (size.width < AppSpacing.mobileBreakpoint) {
      return 68; // Reduced height for mobile to prevent overflow
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 100; // Smaller, more elegant tablet cards
    } else if (size.width < 1200) {
      return 110; // Compact desktop cards
    } else {
      return 120; // Slightly larger for very wide screens
    }
  }

  List<BoxShadow> _buildSimpleShadows() {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google Material Design 3 mobile shadows
      return [
        BoxShadow(
          color: widget.isDark 
              ? Colors.black.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        if (_isHovered)
          BoxShadow(
            color: widget.action.color.withValues(alpha: 0.12),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
      ];
    } else {
      // Google Material Design 3 desktop/tablet shadows
      if (_isHovered) {
        return [
          // Primary shadow
          BoxShadow(
            color: widget.isDark 
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          // Secondary shadow for depth
          BoxShadow(
            color: widget.isDark 
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          // Accent color glow
          BoxShadow(
            color: widget.action.color.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        return [
          BoxShadow(
            color: widget.isDark 
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      }
    }
  }

  Color _buildCardColor() {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google Material Design 3 mobile colors
      final baseColor = widget.isDark 
          ? const Color(0xFF1C1B1F)  // Material Design 3 dark surface
          : const Color(0xFFFFFBFE); // Material Design 3 light surface
      
      if (_isHovered) {
        return Color.lerp(baseColor, widget.action.color, 0.02)!;
      } else {
        return baseColor;
      }
    } else {
      // Google Material Design 3 desktop/tablet colors
      final baseColor = widget.isDark 
          ? const Color(0xFF1C1B1F)  // Material Design 3 dark surface
          : const Color(0xFFFFFBFE); // Material Design 3 light surface
      
      if (_isHovered) {
        return Color.lerp(baseColor, widget.action.color, 0.03)!;
      } else {
        return baseColor;
      }
    }
  }

  Border? _buildCardBorder() {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google Material Design 3 mobile borders - minimal
      if (_isHovered) {
        return Border.all(
          color: widget.action.color.withValues(alpha: 0.12),
          width: 1,
        );
      } else {
        return Border.all(
          color: widget.isDark 
              ? const Color(0xFF49454F).withValues(alpha: 0.12) // Material Design 3 outline
              : const Color(0xFF79747E).withValues(alpha: 0.12),
          width: 0.5,
        );
      }
    } else {
      // Google Material Design 3 desktop/tablet borders
      if (_isHovered) {
        return Border.all(
          color: widget.action.color.withValues(alpha: 0.16),
          width: 1,
        );
      } else {
        return Border.all(
          color: widget.isDark 
              ? const Color(0xFF49454F).withValues(alpha: 0.12) // Material Design 3 outline
              : const Color(0xFF79747E).withValues(alpha: 0.12),
          width: 0.5,
        );
      }
    }
  }

  Widget _buildCardContent(Size size) {
    final isMobile = size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google-style mobile card layout
      return Row(
        children: [
          // Icon container with Google-style design
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.action.icon,
              size: 22,
              color: widget.action.color,
            ),
          ),
          
          const SizedBox(width: 14),
          
          // Text content - Google-style typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.action.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: -0.1,
                      height: 1.1,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 1),
                Flexible(
                  child: Text(
                    widget.action.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      letterSpacing: 0.0,
                      color: widget.isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Arrow indicator - Google-style
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: widget.isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4),
          ),
        ],
      );
    } else {
      // Google Material Design 3 desktop/tablet layout
      return Row(
        children: [
          // Icon container with Material Design 3 styling
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.action.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.action.icon,
              size: 24,
              color: widget.action.color,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Text content with Google typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.action.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.1,
                    height: 1.2,
                    color: widget.isDark 
                        ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                        : const Color(0xFF1C1B1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.action.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    letterSpacing: 0.1,
                    color: widget.isDark 
                        ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                        : const Color(0xFF49454F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Arrow indicator with Material Design 3 styling
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: widget.isDark 
                ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                : const Color(0xFF49454F),
          ),
        ],
      );
    }
  }
}

/// Animated tooltip for quick actions
class AnimatedTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final bool isDark;

  const AnimatedTooltip({
    super.key,
    required this.message,
    required this.child,
    required this.isDark,
  });

  @override
  State<AnimatedTooltip> createState() => _AnimatedTooltipState();
}

class _AnimatedTooltipState extends State<AnimatedTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConfig.fadeTransition,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.defaultCurve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.defaultCurve,
    ));
  }

  void _showTooltip() {
    setState(() {
      _isVisible = true;
    });
    _controller.forward();
  }

  void _hideTooltip() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
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
    return MouseRegion(
      onEnter: (_) => _showTooltip(),
      onExit: (_) => _hideTooltip(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_isVisible)
            Positioned(
              bottom: -40,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark 
                            ? Colors.grey[800] 
                            : Colors.grey[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}