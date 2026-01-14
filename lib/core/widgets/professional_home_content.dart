import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../constants.dart';
import '../responsive/adaptive_layout.dart';
import '../design/app_spacing.dart';
import '../widgets/campus_tour_section.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/section_divider.dart';
import '../widgets/google_style_page_indicator.dart';
import '../widgets/developer_credit.dart';
import '../widgets/location_card.dart';
import '../navigation/navigation_helpers.dart';
import '../../themes/themes.dart';

/// Professional home content that adapts to all screen sizes
/// Eliminates code duplication across mobile/tablet/desktop screens
class ProfessionalHomeContent extends StatefulWidget {
  final ScrollController? scrollController;
  final Function(String)? onChatbotNavigation;

  const ProfessionalHomeContent({
    super.key,
    this.scrollController,
    this.onChatbotNavigation,
  });

  @override
  State<ProfessionalHomeContent> createState() => _ProfessionalHomeContentState();
}

class _ProfessionalHomeContentState extends State<ProfessionalHomeContent> {
  late PageController _pageController;
  late ScrollController _scrollController;
  int _selectedIndex = 0;
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force update on first build and screen size changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updatePageController();
      }
    });
  }

  void _initializeControllers() {
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_handleScroll);

    final middleIndex = AppConstants.locationCards.length ~/ 2;
    _selectedIndex = middleIndex;

    _pageController = PageController(
      viewportFraction: 0.30, // Default to desktop, will update in build
      initialPage: middleIndex,
    )..addListener(_onPageScroll);
  }

  void _updatePageController() {
    final size = MediaQuery.of(context).size;
    final newViewportFraction = _calculateViewportFraction(size.width);
    
    if ((_pageController.viewportFraction - newViewportFraction).abs() > 0.01) {
      final currentPage = _pageController.hasClients 
          ? (_pageController.page ?? _selectedIndex.toDouble())
          : _selectedIndex.toDouble();
      
      _pageController.dispose();
      
      setState(() {
        _pageController = PageController(
          viewportFraction: newViewportFraction,
          initialPage: currentPage.round(),
        )..addListener(_onPageScroll);
      });
    }
  }

  double _calculateViewportFraction(double width) {
    if (width < 600) return 0.85; // Mobile - shows 1 card
    if (width < 1024) return 0.45; // Tablet - shows ~2 cards
    return 0.30; // Desktop - shows 3 smaller cards side-by-side
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final pos = _scrollController.offset;
    final shouldHide = pos > _lastScrollPosition && pos > 100;

    if (_isHeaderVisible == shouldHide) {
      setState(() => _isHeaderVisible = !shouldHide);
    }
    _lastScrollPosition = pos;
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;

    final newIndex = _pageController.page?.round() ?? _selectedIndex;
    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
    }
  }

  void _navigateToPage(int delta) {
    final newIndex = (_selectedIndex + delta).clamp(
      0,
      AppConstants.locationCards.length - 1,
    );
    _pageController.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (context, config) {
        final isDark = context.watch<ThemeProvider>().isDark;
        final theme = Theme.of(context);

        return SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(config, isDark),
              SizedBox(height: AppSpacing.getSectionSpacing(MediaQuery.of(context).size) * 0.6),
              
              _buildExploreSection(config),
              SizedBox(height: AppSpacing.getSectionSpacing(MediaQuery.of(context).size)),
              
              _buildQuickActions(config, isDark),
              
              _buildSectionDivider(config, isDark, theme),
              
              _buildCarouselSection(config, isDark, theme),
              SizedBox(height: AppSpacing.getSectionSpacing(MediaQuery.of(context).size)),
              
              _buildDeveloperCredit(config, isDark),
              SizedBox(height: AppSpacing.getSectionSpacing(MediaQuery.of(context).size)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(AdaptiveConfig config, bool isDark) {
    final size = MediaQuery.of(context).size;
    final heroHeight = config.isMobile 
        ? (size.height * 0.50).clamp(380.0, 520.0)
        : config.isTablet
            ? (size.height * 0.55).clamp(480.0, 620.0)
            : (size.height * 0.52).clamp(500.0, 650.0);

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: Stack(
          children: [
            _buildHeroBackground(),
            _buildHeroOverlay(),
            _buildHeroContent(config, size),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBackground() {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          stops: const [0.3, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.darken,
      child: Image.asset(
        'lib/images/backgroundiu.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.3),
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Image unavailable',
                  style: GoogleFonts.roboto(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeroContent(AdaptiveConfig config, Size size) {
    final fontSize = config.isMobile 
        ? 32.0
        : config.isTablet
            ? (size.width * 0.065).clamp(38.0, 56.0)
            : (size.width * 0.06).clamp(42.0, 64.0);

    return Positioned(
      bottom: size.height * 0.12,
      left: size.width * 0.08,
      right: size.width * 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationBadge(),
          const SizedBox(height: 20),
          _buildMainTitle(fontSize),
          const SizedBox(height: 12),
          _buildAnimatedSubtitle(fontSize),
          const SizedBox(height: 24),
          _buildScrollHint(),
        ],
      ),
    );
  }

  Widget _buildLocationBadge() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'H-9 Islamabad Campus',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTitle(double fontSize) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      delay: const Duration(milliseconds: 200),
      child: Text(
        'IQRA UNIVERSITY',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: fontSize.clamp(32.0, 72.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
          height: 1.1,
          shadows: [
            Shadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSubtitle(double fontSize) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 400),
      child: AnimatedTextKit(
        animatedTexts: [
          TyperAnimatedText(
            'Experience Innovation',
            textStyle: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: (fontSize * 0.4).clamp(18.0, 36.0),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
            speed: const Duration(milliseconds: 100),
          ),
          TyperAnimatedText(
            'Explore Excellence',
            textStyle: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: (fontSize * 0.4).clamp(18.0, 36.0),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
            speed: const Duration(milliseconds: 100),
          ),
          TyperAnimatedText(
            'Virtual Campus Tour',
            textStyle: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: (fontSize * 0.4).clamp(18.0, 36.0),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
            speed: const Duration(milliseconds: 100),
          ),
        ],
        pause: const Duration(milliseconds: 2000),
        repeatForever: true,
      ),
    );
  }

  Widget _buildScrollHint() {
    return FadeInUp(
      duration: const Duration(milliseconds: 900),
      delay: const Duration(milliseconds: 600),
      child: Row(
        children: [
          Icon(
            Icons.arrow_downward,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Scroll to explore',
            style: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSection(AdaptiveConfig config) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: CampusTourSection(
        isMobile: config.isMobile,
        showButton: true, // Show button on all screen sizes
      ),
    );
  }

  Widget _buildQuickActions(AdaptiveConfig config, bool isDark) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 100),
      child: QuickActionsGrid(
        isDark: isDark,
        onActionTapped: (action) {
          // Handle quick action
        },
      ),
    );
  }

  Widget _buildSectionDivider(AdaptiveConfig config, bool isDark, ThemeData theme) {
    return FadeInUp(
      duration: const Duration(milliseconds: 900),
      delay: const Duration(milliseconds: 150),
      child: SectionDivider(
        isDark: isDark,
        subtitle: "Explore our beautiful campus locations",
        height: AppSpacing.getSectionSpacing(MediaQuery.of(context).size) * 0.8,
        accentColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildCarouselSection(AdaptiveConfig config, bool isDark, ThemeData theme) {
    final size = MediaQuery.of(context).size;
    final cardHeight = config.isMobile 
        ? size.height * 0.40
        : config.isTablet
            ? (size.width * 0.22).clamp(420.0, 520.0)
            : (size.width * 0.18).clamp(380.0, 480.0); // Desktop - smaller height for narrower cards

    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      delay: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: config.screenPadding,
        child: Column(
          children: [
            _buildCarouselHeader(config, isDark, theme),
            SizedBox(height: config.isMobile ? 20 : 32),
            _buildCarousel(config, cardHeight),
            SizedBox(height: config.isMobile ? 20 : 32),
            _buildPageIndicator(config, isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselHeader(AdaptiveConfig config, bool isDark, ThemeData theme) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              isDark ? Colors.white : Colors.black87,
              theme.primaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Campus Locations',
            style: TextStyle(
              fontSize: config.isMobile ? 24 : config.isTablet ? 28 : 32,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: config.isMobile ? 8 : 12),
        Text(
          'Take a virtual journey through our stunning campus facilities',
          style: TextStyle(
            fontSize: config.isMobile ? 12 : config.isTablet ? 14 : 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0.2,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCarousel(AdaptiveConfig config, double cardHeight) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            physics: const BouncingScrollPhysics(),
            itemCount: AppConstants.locationCards.length,
            itemBuilder: (context, index) {
              final card = AppConstants.locationCards[index];
              final isSelected = index == _selectedIndex;
              
              // On desktop, show all cards at full scale and opacity
              // On mobile/tablet, scale down non-selected cards
              final shouldScale = config.isMobile || config.isTablet;
              final targetScale = shouldScale ? (isSelected ? 1.0 : 0.92) : 1.0;
              final targetOpacity = shouldScale ? (isSelected ? 1.0 : 0.7) : 1.0;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: targetScale),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: targetOpacity,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: config.isMobile ? 8 : (config.isDesktop ? 8 : 12),
                        ),
                        child: LocationCard(
                          data: card,
                          isHovered: false, // Let individual cards handle their own hover state
                          onTap: () {
                            NavigationHelpers.navigateToLocation(context, card);
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Navigation arrows for non-mobile
        if (!config.isMobile) ...[
          if (_selectedIndex > 0)
            Positioned(
              left: config.isTablet ? -10 : -20,
              child: _buildNavigationArrow(
                Icons.arrow_back_ios_new_rounded,
                () => _navigateToPage(-1),
                config,
              ),
            ),
          if (_selectedIndex < AppConstants.locationCards.length - 1)
            Positioned(
              right: config.isTablet ? -10 : -20,
              child: _buildNavigationArrow(
                Icons.arrow_forward_ios_rounded,
                () => _navigateToPage(1),
                config,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildNavigationArrow(IconData icon, VoidCallback onPressed, AdaptiveConfig config) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final arrowSize = config.isTablet ? 50.0 : 60.0;
    final iconSize = config.isTablet ? 20.0 : 24.0;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark 
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.9),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: config.isTablet ? 8 : 16,
            offset: Offset(0, config.isTablet ? 4 : 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(arrowSize / 2),
          child: Container(
            width: arrowSize,
            height: arrowSize,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              icon,
              color: isDark ? Colors.white : Colors.black87,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(AdaptiveConfig config, bool isDark, ThemeData theme) {
    return GoogleStylePageIndicator(
      controller: _pageController,
      count: AppConstants.locationCards.length,
      currentIndex: _selectedIndex,
      isDark: isDark,
      isMobile: config.isMobile,
      primaryColor: theme.primaryColor,
      showCounter: !config.isMobile,
      showArrows: config.isDesktop,
      onPrevious: _selectedIndex > 0 ? () => _navigateToPage(-1) : null,
      onNext: _selectedIndex < AppConstants.locationCards.length - 1 
          ? () => _navigateToPage(1) : null,
    );
  }

  Widget _buildDeveloperCredit(AdaptiveConfig config, bool isDark) {
    return DeveloperCredit(
      isDark: isDark,
      isMobile: config.isMobile,
    );
  }
}