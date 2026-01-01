import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/utils/image_utils.dart';
import 'package:virtualtouriu/core/utils/memory_manager.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/core/widgets/header_badge.dart';
import 'package:virtualtouriu/core/widgets/theme_toggle_button.dart';
import 'package:virtualtouriu/core/widgets/page_counter.dart';
import 'package:virtualtouriu/themes/themes.dart';

class MobileHomeScreenOptimized extends StatefulWidget {
  final ScrollController? scrollController;

  const MobileHomeScreenOptimized({super.key, this.scrollController});

  @override
  State<MobileHomeScreenOptimized> createState() =>
      _MobileHomeScreenOptimizedState();
}

class _MobileHomeScreenOptimizedState extends State<MobileHomeScreenOptimized> {
  late final PageController _controller;
  late final ScrollController _scrollController;

  int _selectedIndex = 0;
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;
  bool _memoryOptimized = false;

  static final _initFuture = AppConstants.initialize();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optimize memory only once
    if (!_memoryOptimized && mounted) {
      MemoryManager.optimizeForDevice(context);
      _memoryOptimized = true;
    }
  }

  void _initializeControllers() {
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_handleScroll);

    final middleIndex = AppConstants.locationCards.length ~/ 2;
    _controller = PageController(
      viewportFraction: 0.85,
      initialPage: middleIndex,
    )..addListener(_onPageScroll);

    _selectedIndex = middleIndex;
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final pos = _scrollController.offset;
    final shouldHide = pos > _lastScrollPosition && pos > 80;

    if (_isHeaderVisible == shouldHide) {
      setState(() => _isHeaderVisible = !shouldHide);
    }
    _lastScrollPosition = pos;
  }

  void _onPageScroll() {
    if (!_controller.hasClients) return;

    final newIndex = _controller.page?.round() ?? _selectedIndex;
    if (newIndex != _selectedIndex) {
      setState(() => _selectedIndex = newIndex);
    }
  }

  void _handleChatbotNavigation(String location) {
    final normalized = location.toLowerCase().trim();
    final cards = AppConstants.locationCards;

    final index = cards.indexWhere(
      (card) =>
          card.title.toLowerCase().trim() == normalized ||
          card.title.toLowerCase().contains(normalized),
    );

    if (index != -1) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent * 0.6,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        });
      }

      _showSnackBar('Taking you to ${cards[index].title}', true);
    } else {
      _showSnackBar('Location "$location" not found', false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: theme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final heroHeight = (size.height * 0.50).clamp(380.0, 520.0);
        final cardHeight = size.height * 0.40;

        return Stack(
          children: [
            _buildSimpleBackground(isDark),
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

  // Simple background - NO blur filter for performance
  Widget _buildSimpleBackground(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
          ],
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
          // Hero section - simplified for mobile
          SizedBox(
            height: heroHeight,
            child: _buildMobileHeroSection(context, size, isDark),
          ),
          SizedBox(height: size.height * 0.04),

          // Info section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildMobileInfoSection(context, theme, isDark),
          ),
          SizedBox(height: size.height * 0.05),

          // Carousel section
          _buildCarouselSection(size, cardHeight, isDark, theme),
          SizedBox(height: size.height * 0.08),
        ],
      ),
    );
  }

  // Simplified hero section for mobile performance
  Widget _buildMobileHeroSection(BuildContext context, Size size, bool isDark) {
    return Stack(
      children: [
        // Background image with optimized loading
        Positioned.fill(
          child: ResponsiveImageLoader.loadOptimizedImage(
            imagePath: 'lib/images/backgroundiu.jpg',
            fit: BoxFit.cover,
          ),
        ),

        // Simple gradient overlay (no blur)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: size.height * 0.08,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'H-9 Islamabad Campus',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'IQRA UNIVERSITY',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Virtual Campus Tour',
                style: GoogleFonts.roboto(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Simplified info section
  Widget _buildMobileInfoSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            '360° VIRTUAL TOUR',
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Explore Iqra University',
          style: GoogleFonts.roboto(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: theme.textTheme.headlineMedium?.color,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Discover our state-of-the-art H-9 Islamabad campus through an immersive virtual experience.',
          style: GoogleFonts.roboto(
            fontSize: 15,
            height: 1.6,
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 24),

        // Simple stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSimpleStat(Icons.view_in_ar_rounded, '3D Tour', isDark),
            _buildSimpleStat(Icons.location_city, '8+ Locations', isDark),
            _buildSimpleStat(Icons.explore, 'HD Quality', isDark),
          ],
        ),
        const SizedBox(height: 24),

        // Start tour button
        Center(
          child: ElevatedButton(
            onPressed: () => HomeScreen.navigateToCategories(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Start Virtual Tour',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStat(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCarouselSection(
    Size size,
    double cardHeight,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            physics: const BouncingScrollPhysics(),
            itemCount: AppConstants.locationCards.length,
            itemBuilder: (context, index) {
              final card = AppConstants.locationCards[index];
              final isSelected = index == _selectedIndex;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: isSelected ? 1.0 : 0.9),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: isSelected ? 1.0 : 0.6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildMobileCard(card, theme, isDark),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        SmoothPageIndicator(
          controller: _controller,
          count: AppConstants.locationCards.length,
          effect: WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            spacing: 10,
            activeDotColor: theme.primaryColor,
            dotColor: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 12),
        PageCounter(
          currentIndex: _selectedIndex,
          totalCount: AppConstants.locationCards.length,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMobileCard(LocationCardData card, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LocationDetailScreen(
                  locationName: card.title,
                  imagePath: card.imagePath,
                  locationData: card,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ResponsiveImageLoader.loadOptimizedImage(
                imagePath: card.imagePath,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.tag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          card.tag.toUpperCase(),
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    Text(
                      card.title,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.threesixty_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '360°',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(bool isDark, ThemeData theme) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      top: _isHeaderVisible ? 0 : -100,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HeaderBadge(
                isDark: isDark,
                text: 'IQRA Virtual Tour',
                icon: Icons.school,
              ),
              ThemeToggleButton(
                isDark: isDark,
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
