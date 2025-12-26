import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:virtualtouriu/Screens/HomeScreen.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/themes/Themes.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);

    final middleIndex = AppConstants.locationCards.length ~/ 2;

    final double width =
        WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;

    final double viewportFraction = _calculateViewportFraction(width);

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

  double _calculateViewportFraction(double width) {
    if (width > 1400) return 0.32;
    if (width > 1200) return 0.35;
    if (width > 1000) return 0.38;
    if (width > 900) return 0.42;
    return 0.46;
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

  // Add navigation handler for chatbot
  void _handleChatbotNavigation(String location) {
    // Normalize the input location
    final normalizedLocation = location.toLowerCase().trim();

    // Create a mapping of common terms to actual card titles from constants.dart
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

    // Try to find a match
    int locationIndex = -1;

    // First, try direct match with card titles
    locationIndex = AppConstants.locationCards.indexWhere(
      (card) =>
          card.title.toLowerCase().trim() == normalizedLocation ||
          card.title.toLowerCase().contains(normalizedLocation) ||
          normalizedLocation.contains(card.title.toLowerCase()),
    );

    // If no direct match, try the mappings
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
      // Navigate to the found location
      _controller.animateToPage(
        locationIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );

      // Scroll to carousel section
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.6,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Taking you to ${AppConstants.locationCards[locationIndex].title}',
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Show available locations
      final availableLocations = AppConstants.locationCards
          .map((card) => card.title)
          .take(5)
          .join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Location "$location" not found')),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Try: $availableLocations...',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return FutureBuilder<void>(
      future: AppConstants.initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        final double heroHeight = (size.height * 0.55).clamp(480.0, 620.0);
        final double cardHeight = (size.width * 0.22).clamp(420.0, 520.0);

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.black.withOpacity(0.1)
                        : Colors.grey.shade100,
                    isDark ? Colors.black.withOpacity(0.2) : Colors.white,
                  ],
                ),
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: isDark ? 8.0 : 5.0,
                    sigmaY: isDark ? 8.0 : 5.0,
                  ),
                  child: Container(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
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
                  SizedBox(height: size.height * 0.045),

                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.08,
                      ),
                      child: HomeScreen.buildInfoSection(
                        context: context,
                        isMobile: false,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),

                  // Section header
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 100),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.08,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FEATURED LOCATIONS',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.5,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Discover Our Campus',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: (size.width * 0.04).clamp(28.0, 38.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),

                  // Enhanced carousel with navigation
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.02,
                        vertical: size.height * 0.03,
                      ),
                      constraints: const BoxConstraints(maxWidth: 1800),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: cardHeight + 40,
                                child: HomeScreen.buildCarousel(
                                  context: context,
                                  cardHeight: cardHeight,
                                  controller: _controller,
                                  selectedIndex: _selectedIndex,
                                  isInteracting: _isInteracting,
                                  onPageChanged:
                                      (index) => setState(
                                        () => _selectedIndex = index,
                                      ),
                                  isDesktop: true,
                                  onTap: (index) {},
                                  setInteracting: (value) {},
                                ),
                              ),

                              if (_showLeftArrow)
                                Positioned(
                                  left: 0,
                                  child: _buildNavigationArrow(
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onPressed: () => _navigateToPage(-1),
                                    isDark: isDark,
                                    theme: theme,
                                  ),
                                ),

                              if (_showRightArrow)
                                Positioned(
                                  right: 0,
                                  child: _buildNavigationArrow(
                                    icon: Icons.arrow_forward_ios_rounded,
                                    onPressed: () => _navigateToPage(1),
                                    isDark: isDark,
                                    theme: theme,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          SmoothPageIndicator(
                            controller: _controller,
                            count: AppConstants.locationCards.length,
                            effect: WormEffect(
                              dotWidth: 10,
                              dotHeight: 10,
                              spacing: 12,
                              activeDotColor: theme.primaryColor,
                              dotColor:
                                  isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade400,
                              paintStyle: PaintingStyle.fill,
                            ),
                          ),

                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.06),
                              ),
                            ),
                            child: Text(
                              '${_selectedIndex + 1} / ${AppConstants.locationCards.length}',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.black.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.08),
                ],
              ),
            ),
            _buildAnimatedHeader(context, isDark, theme),
            // Add chatbot widget
            ChatbotWidget(onNavigate: _handleChatbotNavigation),
          ],
        );
      },
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school, size: 20, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'IQRA Virtual Tour',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FadeInRight(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        key: ValueKey(isDark),
                        color: isDark ? Colors.amber : Colors.indigo,
                      ),
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                    tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required ThemeData theme,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.95),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : theme.primaryColor,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
