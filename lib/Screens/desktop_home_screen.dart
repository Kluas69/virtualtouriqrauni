import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/core/widgets/header_badge.dart';
import 'package:virtualtouriu/core/widgets/theme_toggle_button.dart';
import 'package:virtualtouriu/core/widgets/page_counter.dart';
import 'package:virtualtouriu/core/widgets/language_selector.dart';
import 'package:virtualtouriu/core/widgets/quick_actions_grid.dart';
import 'package:virtualtouriu/core/widgets/section_divider.dart';
import 'package:virtualtouriu/core/widgets/enhanced_explore_section.dart';
import 'package:virtualtouriu/core/widgets/google_style_page_indicator.dart';
import 'package:virtualtouriu/core/widgets/developer_credit.dart';
import 'package:virtualtouriu/core/state/futuristic_ui_state.dart';
import 'package:virtualtouriu/core/design/app_spacing.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:animate_do/animate_do.dart';

class DesktopHomeScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const DesktopHomeScreen({super.key, this.scrollController});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  PageController? _controller;
  late final ScrollController _scrollController;

  int _selectedIndex = 0;
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;

  // Futuristic UI state
  late FuturisticUIState _futuristicUIState;

  static final _initFuture = AppConstants.initialize();

  @override
  void initState() {
    super.initState();
    _futuristicUIState = FuturisticUIState();
    _initializeControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize controller with proper viewport fraction now that context is available
    if (_controller == null) {
      _initializePageController();
    }
  }

  void _initializeControllers() {
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_handleScroll);

    final middleIndex = AppConstants.locationCards.length ~/ 2;
    _selectedIndex = middleIndex;
    _updateArrowVisibility();
  }

  void _initializePageController() {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final middleIndex = AppConstants.locationCards.length ~/ 2;

    _controller = PageController(
      viewportFraction: _calculateViewportFraction(width),
      initialPage: middleIndex,
    )..addListener(_onPageScroll);
  }

  double _calculateViewportFraction(double width) {
    if (width > 2000) return 0.26;
    if (width > 1600) return 0.30;
    if (width > 1200) return 0.34;
    return 0.38;
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
    if (_controller == null || !_controller!.hasClients) return;

    final newIndex = _controller!.page?.round() ?? _selectedIndex;
    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
        _updateArrowVisibility();
      });
    }
  }

  void _updateArrowVisibility() {
    setState(() {
      _showLeftArrow = _selectedIndex > 0;
      _showRightArrow = _selectedIndex < AppConstants.locationCards.length - 1;
    });
  }

  void _navigateToPage(int delta) {
    if (_controller == null) return;
    
    final newIndex = (_selectedIndex + delta).clamp(
      0,
      AppConstants.locationCards.length - 1,
    );
    _controller!.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleChatbotNavigation(String location) {
    final index = _findLocationIndex(location);

    if (index != -1) {
      final locationData = AppConstants.locationCards[index];
      Navigator.push(context, _buildPageRoute(locationData));
      // Removed snackbar feedback for cleaner UX
    } else {
      // Location not found - removed snackbar feedback for cleaner UX
    }
  }

  void _handleLanguageChanged(Language language) {
    // Handle language change
    _futuristicUIState.setCurrentLanguage(language);
    
    // Save language preference
    LanguagePreferences.saveLanguage(language.code);
    
    // Language changed - removed snackbar feedback for cleaner UX
    
    // Apply RTL layout if needed
    if (language.isRTL) {
      // Force rebuild with RTL direction
      setState(() {});
    }
  }

  void _handleQuickAction(QuickAction action) {
    // Handle quick action tap - search functionality now accessed through actions
    // Removed snackbar feedback for cleaner UX
    // The action's onTap will be called automatically
  }

  int _findLocationIndex(String location) {
    final normalized = location.toLowerCase().trim();
    return AppConstants.locationCards.indexWhere(
      (card) =>
          card.title.toLowerCase().trim() == normalized ||
          card.title.toLowerCase().contains(normalized),
    );
  }

  PageRouteBuilder _buildPageRoute(LocationCardData data) {
    return PageRouteBuilder(
      pageBuilder:
          (_, __, ___) => LocationDetailScreen(
            locationName: data.title,
            imagePath: data.imagePath,
            locationData: data,
          ),
      transitionsBuilder:
          (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Removed _showSnackBar method for cleaner UX

  @override
  void dispose() {
    _controller?.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    _futuristicUIState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return ChangeNotifierProvider.value(
      value: _futuristicUIState,
      child: Stack(
        children: [
          // Main content without floating shapes
          Stack(
            children: [
              _buildBackground(isDark),
              _buildScrollableContent(
                size,
                (size.height * 0.52).clamp(500.0, 650.0),
                (size.width * 0.20).clamp(420.0, 520.0),
                isDark,
                theme,
              ),
            ],
          ),
          _buildAnimatedHeader(isDark, theme),
          ChatbotWidget(onNavigate: _handleChatbotNavigation),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
    );
  }

  Widget _buildScrollableContent(
    Size size,
    double heroHeight,
    double cardHeight,
    bool isDark,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: SizedBox(
              height: heroHeight,
              child: HomeScreen.buildHeroSection(
                context: context,
                fontSize: (size.width * 0.06).clamp(42.0, 64.0),
                heightFactor: 1.0,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.getSectionSpacing(size) * 0.6),
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: EnhancedExploreSection(
              isMobile: false,
              onTourPressed: () => HomeScreen.navigateToCategories(context),
            ),
          ),
          SizedBox(height: AppSpacing.getSectionSpacing(size)),
          
          // Quick Actions Grid
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 100),
            child: QuickActionsGrid(
              isDark: isDark,
              onActionTapped: _handleQuickAction,
            ),
          ),
          
          // Section Divider
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            delay: const Duration(milliseconds: 150),
            child: SectionDivider(
              isDark: isDark,
              subtitle: "Explore our beautiful campus locations",
              height: AppSpacing.getSectionSpacing(size) * 0.8,
              accentColor: theme.primaryColor,
            ),
          ),
          
          // Enhanced Carousel Section
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            delay: const Duration(milliseconds: 200),
            child: _buildEnhancedCarouselSection(size, cardHeight, isDark, theme),
          ),
          SizedBox(height: AppSpacing.getSectionSpacing(size)),
          
          // Developer Credit
          DeveloperCredit(
            isDark: isDark,
            isMobile: false,
          ),
          SizedBox(height: AppSpacing.getSectionSpacing(size)),
        ],
      ),
    );
  }

  Widget _buildEnhancedCarouselSection(
    Size size,
    double cardHeight,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width < AppSpacing.mobileBreakpoint 
            ? 16.0 
            : size.width < AppSpacing.tabletBreakpoint 
                ? 24.0 
                : 32.0,
        vertical: AppSpacing.getSectionSpacing(size) * 0.5,
      ),
      child: Column(
        children: [
          // Section Header - Simple without animations
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: size.width < AppSpacing.mobileBreakpoint ? 16.0 : 24.0,
              vertical: size.width < AppSpacing.mobileBreakpoint ? 16.0 : 24.0,
            ),
            child: Column(
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
                      fontSize: size.width < AppSpacing.mobileBreakpoint ? 24 : 
                               size.width < AppSpacing.tabletBreakpoint ? 28 : 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: Colors.white, // This will be masked by the shader
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: size.width < AppSpacing.mobileBreakpoint ? 8 : 12),
                Text(
                  'Take a virtual journey through our stunning campus facilities and discover what makes IQRA University special',
                  style: TextStyle(
                    fontSize: size.width < AppSpacing.mobileBreakpoint ? 12 : 
                             size.width < AppSpacing.tabletBreakpoint ? 14 : 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          SizedBox(height: size.width < AppSpacing.mobileBreakpoint ? 20 : 32),
          
          // Simple Carousel without white box container
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: cardHeight,
                child: _controller == null 
                  ? const Center(child: CircularProgressIndicator())
                  : HomeScreen.buildCarousel(
                      context: context,
                      cardHeight: cardHeight,
                      controller: _controller!,
                      selectedIndex: _selectedIndex,
                      isInteracting: false,
                      onPageChanged: (index) => setState(() => _selectedIndex = index),
                      isDesktop: size.width > AppSpacing.tabletBreakpoint,
                      onTap: (_) {},
                      setInteracting: (_) {},
                    ),
              ),
              
              // Navigation Arrows - responsive positioning with transparent style
              if (_showLeftArrow && size.width > AppSpacing.mobileBreakpoint)
                Positioned(
                  left: size.width < AppSpacing.tabletBreakpoint ? -10 : -20,
                  child: _buildTransparentNavigationArrow(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => _navigateToPage(-1),
                    isDark: isDark,
                    theme: theme,
                    size: size,
                  ),
                ),
              if (_showRightArrow && size.width > AppSpacing.mobileBreakpoint)
                Positioned(
                  right: size.width < AppSpacing.tabletBreakpoint ? -10 : -20,
                  child: _buildTransparentNavigationArrow(
                    icon: Icons.arrow_forward_ios_rounded,
                    onPressed: () => _navigateToPage(1),
                    isDark: isDark,
                    theme: theme,
                    size: size,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: size.width < AppSpacing.mobileBreakpoint ? 20 : 32),
          
          // Enhanced Google-style Page Indicators
          if (_controller != null)
            GoogleStylePageIndicator(
              controller: _controller!,
              count: AppConstants.locationCards.length,
              currentIndex: _selectedIndex,
              isDark: isDark,
              isMobile: size.width < AppSpacing.mobileBreakpoint,
              primaryColor: theme.primaryColor,
              showCounter: size.width > AppSpacing.mobileBreakpoint,
              showArrows: size.width > AppSpacing.tabletBreakpoint,
              onPrevious: _showLeftArrow ? () => _navigateToPage(-1) : null,
              onNext: _showRightArrow ? () => _navigateToPage(1) : null,
            ),
        ],
      ),
    );
  }

  Widget _buildTransparentNavigationArrow({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required ThemeData theme,
    required Size size,
  }) {
    final arrowSize = size.width < AppSpacing.mobileBreakpoint ? 40.0 : 
                     size.width < AppSpacing.tabletBreakpoint ? 50.0 : 60.0;
    final iconSize = size.width < AppSpacing.mobileBreakpoint ? 18.0 : 
                     size.width < AppSpacing.tabletBreakpoint ? 20.0 : 24.0;
    
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
            blurRadius: size.width < AppSpacing.mobileBreakpoint ? 8 : 16,
            offset: Offset(0, size.width < AppSpacing.mobileBreakpoint ? 4 : 8),
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
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

  Widget _buildAnimatedHeader(bool isDark, ThemeData theme) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _isHeaderVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _futuristicUIState,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Badge
                FadeInLeft(
                  duration: const Duration(milliseconds: 600),
                  child: HeaderBadge(
                    isDark: isDark,
                    text: 'IQRA Virtual Tour',
                    icon: Icons.school,
                  ),
                ),
                
                // Center - Spacer for clean layout
                const Spacer(),
                
                // Right side - Language Selector and Theme Toggle
                FadeInRight(
                  duration: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageSelector(
                        currentLanguage: _futuristicUIState.currentLanguage,
                        onLanguageChanged: _handleLanguageChanged,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      ThemeToggleButton(
                        isDark: isDark,
                        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
