import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/core/widgets/header_badge.dart';
import 'package:virtualtouriu/core/widgets/navigation_arrow.dart';
import 'package:virtualtouriu/core/widgets/page_counter.dart';
import 'package:virtualtouriu/core/widgets/theme_toggle_button.dart';
import 'package:virtualtouriu/core/widgets/quick_actions_grid.dart';
import 'package:virtualtouriu/core/widgets/section_divider.dart';
import 'package:virtualtouriu/core/widgets/enhanced_explore_section.dart';
import 'package:virtualtouriu/core/widgets/google_style_page_indicator.dart';
import 'package:virtualtouriu/core/widgets/developer_credit.dart';
import 'package:virtualtouriu/core/design/app_spacing.dart';
import 'package:virtualtouriu/core/state/futuristic_ui_state.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:animate_do/animate_do.dart';

class TabletHomeScreen extends StatefulWidget {
  const TabletHomeScreen({super.key});

  @override
  State<TabletHomeScreen> createState() => _TabletHomeScreenState();
}

class _TabletHomeScreenState extends State<TabletHomeScreen> {
  late PageController _controller;
  late ScrollController _scrollController;
  int _selectedIndex = 0;
  bool _isInteracting = false;
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;
  
  // Futuristic UI state
  late FuturisticUIState _futuristicUIState;

  @override
  void initState() {
    super.initState();
    _futuristicUIState = FuturisticUIState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);

    final middleIndex = AppConstants.locationCards.length ~/ 2;

    // Use MediaQuery in build method instead of window
    final double viewportFraction = 0.35; // Default value, will be updated in build

    _controller = PageController(
      viewportFraction: viewportFraction,
      initialPage: middleIndex,
    );
    _selectedIndex = middleIndex;

    _controller.addListener(() {
      if (_controller.hasClients) {
        final newIndex = _controller.page?.round() ?? middleIndex;
        if (newIndex != _selectedIndex) {
          setState(() {
            _selectedIndex = newIndex;
            _isInteracting = true;
            _updateArrowVisibility();
          });
        }
      }
    });

    _updateArrowVisibility();
  }

  void _handleScroll() {
    final currentScrollPosition = _scrollController.offset;

    if (currentScrollPosition > _lastScrollPosition &&
        currentScrollPosition > 100) {
      if (_isHeaderVisible) {
        setState(() => _isHeaderVisible = false);
      }
    } else if (currentScrollPosition < _lastScrollPosition) {
      if (!_isHeaderVisible) {
        setState(() => _isHeaderVisible = true);
      }
    }

    _lastScrollPosition = currentScrollPosition;
  }

  void _updateArrowVisibility() {
    setState(() {
      _showLeftArrow = _selectedIndex > 0;
      _showRightArrow = _selectedIndex < AppConstants.locationCards.length - 1;
    });
  }

  void _navigateToPage(int delta) {
    final newIndex = (_selectedIndex + delta).clamp(
      0,
      AppConstants.locationCards.length - 1,
    );
    _controller.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleChatbotNavigation(String location) {
    final normalizedLocation = location.toLowerCase().trim();

    final locationMappings = {
      'library': ['library', 'lib', 'book', 'study', 'reading'],
      'play area': [
        'play area',
        'play ground',
        'playground',
        'field',
        'sports ground',
        'ground',
      ],
      'auditorium': [
        'auditorium',
        'hall',
        'assembly hall',
        'theater',
        'theatre',
      ],
      'class rooms': [
        'classroom',
        'class room',
        'class rooms',
        'class',
        'lecture hall',
        'lecture room',
      ],
      'amphitheater': [
        'amphitheater',
        'amphitheatre',
        'outdoor theater',
        'open air',
      ],
      'cafeteria': [
        'cafeteria',
        'cafe',
        'canteen',
        'food court',
        'dining',
        'restaurant',
      ],
      'common room': [
        'common room',
        'commonroom',
        'lounge',
        'student lounge',
        'recreation',
      ],
      'playground': ['playground', 'play ground', 'sports', 'outdoor sports'],
      'swimming pool': ['swimming pool', 'pool', 'swimming', 'swim'],
      'webinar room': [
        'webinar room',
        'webinar',
        'virtual room',
        'online class',
        'meeting room',
      ],
    };

    int locationIndex = -1;

    locationIndex = AppConstants.locationCards.indexWhere(
      (card) =>
          card.title.toLowerCase().trim() == normalizedLocation ||
          card.title.toLowerCase().contains(normalizedLocation) ||
          normalizedLocation.contains(card.title.toLowerCase()),
    );

    if (locationIndex == -1) {
      for (var entry in locationMappings.entries) {
        if (entry.value.any(
          (term) =>
              normalizedLocation.contains(term) ||
              term.contains(normalizedLocation),
        )) {
          locationIndex = AppConstants.locationCards.indexWhere(
            (card) => card.title.toLowerCase().trim() == entry.key,
          );
          if (locationIndex != -1) break;
        }
      }
    }

    if (locationIndex != -1) {
      _controller.animateToPage(
        locationIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.6,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });

      // Removed snackbar feedback for cleaner UX
    } else {
      // Location not found - removed snackbar feedback for cleaner UX
    }
  }

  void _handleQuickAction(QuickAction action) {
    // Handle quick action tap - removed snackbar feedback for cleaner UX
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
                child: HomeScreen.buildCarousel(
                  context: context,
                  cardHeight: cardHeight,
                  controller: _controller,
                  selectedIndex: _selectedIndex,
                  isInteracting: _isInteracting,
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
                  child: NavigationArrow(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => _navigateToPage(-1),
                    isDark: isDark,
                  ),
                ),
              if (_showRightArrow && size.width > AppSpacing.mobileBreakpoint)
                Positioned(
                  right: size.width < AppSpacing.tabletBreakpoint ? -10 : -20,
                  child: NavigationArrow(
                    icon: Icons.arrow_forward_ios_rounded,
                    onPressed: () => _navigateToPage(1),
                    isDark: isDark,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: size.width < AppSpacing.mobileBreakpoint ? 20 : 32),
          
          // Enhanced Google-style Page Indicators
          GoogleStylePageIndicator(
            controller: _controller,
            count: AppConstants.locationCards.length,
            currentIndex: _selectedIndex,
            isDark: isDark,
            isMobile: size.width < AppSpacing.mobileBreakpoint,
            primaryColor: theme.primaryColor,
            showCounter: size.width > AppSpacing.mobileBreakpoint,
            showArrows: false, // Tablet uses separate navigation arrows
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    _scrollController.dispose();
    _futuristicUIState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final double heroHeight = (size.height * 0.55).clamp(480.0, 620.0);
    final double cardHeight = (size.width * 0.22).clamp(420.0, 520.0);

    return ChangeNotifierProvider.value(
      value: _futuristicUIState,
      child: Stack(
        children: [
          // Simple Google Material Design 3 background
          Container(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: SizedBox(
                    height: heroHeight,
                    width: double.infinity,
                    child: HomeScreen.buildHeroSection(
                      context: context,
                      fontSize: (size.width * 0.065).clamp(38.0, 56.0),
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
          ),
          _buildAnimatedHeader(context, isDark, theme),
          ChatbotWidget(onNavigate: _handleChatbotNavigation),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(
    BuildContext context,
    bool isDark,
    ThemeData theme,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _isHeaderVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FadeInLeft(
                duration: const Duration(milliseconds: 600),
                child: HeaderBadge(
                  isDark: isDark,
                  text: 'IQRA Virtual Tour',
                  icon: Icons.school,
                ),
              ),
              FadeInRight(
                duration: const Duration(milliseconds: 600),
                child: ThemeToggleButton(
                  isDark: isDark,
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
