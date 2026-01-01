import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../animation/animation_config.dart';
import '../state/futuristic_ui_state.dart';
import '../design/app_spacing.dart';
import '../navigation/safe_navigation.dart';
import '../../Screens/categories.dart';

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
    // Improved responsive breakpoints
    int crossAxisCount;
    double childAspectRatio;
    double spacing;
    
    if (size.width < AppSpacing.mobileBreakpoint) {
      // Mobile: Single column with Google-style horizontal cards
      crossAxisCount = 1;
      childAspectRatio = 4.5; // Wider aspect ratio for horizontal layout
      spacing = 8.0; // Tighter spacing for cleaner look
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      // Tablet: 2x2 grid
      crossAxisCount = 2;
      childAspectRatio = 1.4;
      spacing = 16.0;
    } else if (size.width < AppSpacing.desktopBreakpoint) {
      // Small desktop: 2x2 grid
      crossAxisCount = 2;
      childAspectRatio = 1.3;
      spacing = 20.0;
    } else {
      // Large desktop: All 4 in one row
      crossAxisCount = 4;
      childAspectRatio = 1.15;
      spacing = 24.0;
    }
    
    return GridView.builder(
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
        title: 'Start Virtual Tour',
        subtitle: 'Begin interactive campus exploration',
        icon: Icons.explore_rounded,
        color: const Color(0xFF4285F4), // Google Blue
        tooltip: 'Begin an immersive virtual tour of the campus',
        onTap: () {
          // Show loading screen before navigation
          _showLoadingAndNavigate(context);
        },
      ),
      QuickAction(
        title: 'Campus Map',
        subtitle: 'Interactive navigation and directions',
        icon: Icons.map_rounded,
        color: const Color(0xFF34A853), // Google Green
        tooltip: 'View detailed campus map with locations',
        onTap: () {
          // Show loading screen before navigation
          _showLoadingAndNavigate(context);
        },
      ),
      QuickAction(
        title: 'Locations',
        subtitle: 'Browse all campus facilities',
        icon: Icons.location_on_rounded,
        color: const Color(0xFF9C27B0), // Material Purple
        tooltip: 'Explore different campus locations and facilities',
        onTap: () {
          // Show loading screen before navigation
          _showLoadingAndNavigate(context);
        },
      ),
      QuickAction(
        title: 'About IQRA',
        subtitle: 'University information and history',
        icon: Icons.school_rounded,
        color: const Color(0xFFFF9800), // Material Orange
        tooltip: 'Learn about IQRA University history and achievements',
        onTap: () {
          // Show about dialog
          showDialog(
            context: context,
            builder: (context) => _buildAboutDialog(context),
          );
        },
      ),
    ];
  }

  Widget _buildAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFFF9800),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'About IQRA University',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Content
            Text(
              'IQRA University is a leading educational institution committed to providing quality higher education. Our state-of-the-art campus features modern facilities, advanced laboratories, and comprehensive learning environments designed to foster academic excellence and innovation.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Features
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Features:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    '• Modern classrooms with smart boards',
                    '• Advanced computer and science laboratories',
                    '• Comprehensive library with digital resources',
                    '• Sports facilities and recreational areas',
                    '• Student cafeteria and dining areas',
                  ].map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Use safe navigation with loading
                  _showLoadingAndNavigate(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Virtual Tour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Safe navigation with proper preloading to prevent mobile crashes
  static Future<void> _showLoadingAndNavigate(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    await SafeNavigation.navigateToScreen(
      context: context,
      screen: const CategoriesScreen(),
      screenName: 'categories',
      routeName: '/categories',
      showLoadingDialog: true,
      minLoadingTime: Duration(milliseconds: isMobile ? 3000 : 2000), // Longer for mobile
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
    context.read<FuturisticUIState>().setHoveredActionIndex(
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
    
    return Consumer<FuturisticUIState>(
      builder: (context, state, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Container(
                height: _getCardHeight(size),
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
                      size.width < AppSpacing.mobileBreakpoint ? 16 : 
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
      return 80; // Reduced height for Google-style horizontal layout
    } else if (size.width < AppSpacing.tabletBreakpoint) {
      return 140;
    } else {
      return 160;
    }
  }

  List<BoxShadow> _buildSimpleShadows() {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google-style mobile shadows - subtle and clean
      return [
        BoxShadow(
          color: widget.isDark 
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        if (_isHovered)
          BoxShadow(
            color: widget.action.color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
      ];
    } else {
      // Desktop/tablet shadows (unchanged)
      if (_isHovered) {
        return [
          BoxShadow(
            color: widget.isDark 
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: widget.action.color.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ];
      } else {
        return [
          BoxShadow(
            color: widget.isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];
      }
    }
  }

  Color _buildCardColor() {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google-style mobile card colors - clean and minimal
      final baseColor = widget.isDark 
          ? const Color(0xFF1F1F1F)  // Darker for better contrast
          : Colors.white;
      
      if (_isHovered) {
        return Color.lerp(baseColor, widget.action.color, 0.03)!;
      } else {
        return baseColor;
      }
    } else {
      // Desktop/tablet colors (unchanged)
      final baseColor = widget.isDark 
          ? Colors.grey[850]!
          : Colors.white;
      
      if (_isHovered) {
        return Color.lerp(baseColor, widget.action.color, 0.05)!;
      } else {
        return baseColor;
      }
    }
  }

  Border? _buildCardBorder() {
    final isMobile = MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;
    
    if (isMobile) {
      // Google-style mobile borders - very subtle
      if (_isHovered) {
        return Border.all(
          color: widget.action.color.withValues(alpha: 0.2),
          width: 1,
        );
      } else {
        return Border.all(
          color: widget.isDark 
              ? Colors.grey.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        );
      }
    } else {
      // Desktop/tablet borders (unchanged)
      if (_isHovered) {
        return Border.all(
          color: widget.action.color.withValues(alpha: 0.3),
          width: 1.5,
        );
      } else {
        return Border.all(
          color: widget.isDark 
              ? Colors.grey.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.action.icon,
              size: 24,
              color: widget.action.color,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Text content - Google-style typography
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
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.action.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    letterSpacing: 0.0,
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      // Desktop/tablet layout (unchanged)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Simple icon with background
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.action.icon,
              size: 32,
              color: widget.action.color,
            ),
          ),
          
          // Text content with flexible spacing
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Title
                  Flexible(
                    child: Text(
                      widget.action.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.2,
                        height: 1.1,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  SizedBox(height: 6),
                  
                  // Subtitle
                  Flexible(
                    child: Text(
                      widget.action.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        letterSpacing: 0.0,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
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