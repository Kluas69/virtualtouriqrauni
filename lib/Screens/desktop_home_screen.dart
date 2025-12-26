import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:virtualtouriu/Screens/HomeScreen.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/themes/Themes.dart';
import 'package:animate_do/animate_do.dart';

class DesktopHomeScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const DesktopHomeScreen({super.key, this.scrollController});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  late final PageController _controller;
  late final ScrollController _scrollController;

  int _selectedIndex = 0;
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;

  static final _initFuture = AppConstants.initialize();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_handleScroll);

    final middleIndex = AppConstants.locationCards.length ~/ 2;
    final width =
        WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;

    _controller = PageController(
      viewportFraction: _calculateViewportFraction(width),
      initialPage: middleIndex,
    )..addListener(_onPageScroll);

    _selectedIndex = middleIndex;
    _updateArrowVisibility();
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
    if (!_controller.hasClients) return;

    final newIndex = _controller.page?.round() ?? _selectedIndex;
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
    final index = _findLocationIndex(location);

    if (index != -1) {
      final locationData = AppConstants.locationCards[index];
      Navigator.push(context, _buildPageRoute(locationData));
      _showSnackBar('Opening ${locationData.title}', Colors.green);
    } else {
      _showSnackBar('Location "$location" not found', Colors.orange);
    }
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

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: Duration(seconds: color == Colors.green ? 2 : 4),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return FutureBuilder<void>(
      future: _initFuture,
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

        final heroHeight = (size.height * 0.52).clamp(500.0, 650.0);
        final cardHeight = (size.width * 0.20).clamp(420.0, 520.0);

        return Stack(
          children: [
            _buildBackground(isDark),
            _buildScrollableContent(
              size,
              heroHeight,
              cardHeight,
              isDark,
              theme,
            ),
            _buildAnimatedHeader(isDark, theme),
            ChatbotWidget(onNavigate: _handleChatbotNavigation),
          ],
        );
      },
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? Colors.black.withOpacity(0.1) : Colors.grey.shade100,
            isDark ? Colors.black.withOpacity(0.2) : Colors.white,
          ],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 8 : 5,
          sigmaY: isDark ? 8 : 5,
        ),
        child: Container(
          color: (isDark ? Colors.black : Colors.white).withOpacity(0.2),
        ),
      ),
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
          SizedBox(height: size.height * 0.04),
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: HomeScreen.buildInfoSection(
                context: context,
                isMobile: false,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.06),
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            delay: const Duration(milliseconds: 200),
            child: _buildCarouselSection(size, cardHeight, isDark, theme),
          ),
          SizedBox(height: size.height * 0.08),
        ],
      ),
    );
  }

  Widget _buildCarouselSection(
    Size size,
    double cardHeight,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
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
                  isInteracting: false,
                  onPageChanged:
                      (index) => setState(() => _selectedIndex = index),
                  isDesktop: true,
                  onTap: (_) {},
                  setInteracting: (_) {},
                ),
              ),
              if (_showLeftArrow)
                Positioned(
                  left: 0,
                  child: _buildNavigationArrow(
                    Icons.arrow_back_ios_new_rounded,
                    () => _navigateToPage(-1),
                    isDark,
                    theme,
                  ),
                ),
              if (_showRightArrow)
                Positioned(
                  right: 0,
                  child: _buildNavigationArrow(
                    Icons.arrow_forward_ios_rounded,
                    () => _navigateToPage(1),
                    isDark,
                    theme,
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
              dotColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          _buildPageCounter(isDark),
        ],
      ),
    );
  }

  Widget _buildPageCounter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: Text(
        '${_selectedIndex + 1} / ${AppConstants.locationCards.length}',
        style: TextStyle(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FadeInLeft(
                duration: const Duration(milliseconds: 600),
                child: _buildHeaderBadge(isDark, theme),
              ),
              FadeInRight(
                duration: const Duration(milliseconds: 600),
                child: _buildThemeToggle(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(
              isDark ? 0.3 : 0.05,
            ),
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
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(
              isDark ? 0.3 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder:
              (child, animation) => RotationTransition(
                turns: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
          child: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            key: ValueKey(isDark),
            color: isDark ? Colors.amber : Colors.indigo,
          ),
        ),
        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        tooltip: isDark ? 'Light Mode' : 'Dark Mode',
      ),
    );
  }

  Widget _buildNavigationArrow(
    IconData icon,
    VoidCallback onPressed,
    bool isDark,
    ThemeData theme,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
    );
  }
}
