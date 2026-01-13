import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/utils/image_utils.dart';
import 'package:virtualtouriu/core/memory/memory_manager.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/core/widgets/header_badge.dart';
import 'package:virtualtouriu/core/widgets/theme_toggle_button.dart';
import 'package:virtualtouriu/core/widgets/page_counter.dart';
import 'package:virtualtouriu/core/widgets/google_style_page_indicator.dart';
import 'package:virtualtouriu/core/widgets/quick_actions_grid.dart';
import 'package:virtualtouriu/core/widgets/enhanced_explore_section.dart';
import 'package:virtualtouriu/core/widgets/section_divider.dart';
import 'package:virtualtouriu/core/design/app_spacing.dart';
import 'package:virtualtouriu/core/state/futuristic_ui_state.dart';
import 'package:virtualtouriu/core/widgets/developer_credit.dart';
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
    // Optimize memory only once
    if (!_memoryOptimized && mounted) {
      MemoryManager().optimizeForDevice(context);
      _memoryOptimized = true;
    }
  }

  void _initializeControllers() {
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_handleScroll);

    final middleIndex = AppConstants.locationCards.length ~/ 2;
    _controller = PageController(
      viewportFraction: 0.82, // Reduced from 0.85 to prevent overlapping
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

      // Removed snackbar feedback for cleaner UX
    } else {
      // Location not found - removed snackbar feedback for cleaner UX
    }
  }

  // Removed _showSnackBar method for cleaner UX

  void _handleQuickAction(QuickAction action) {
    // Handle quick action tap - removed snackbar feedback for cleaner UX
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    _futuristicUIState.dispose();
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

        return ChangeNotifierProvider.value(
          value: _futuristicUIState,
          child: Stack(
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
          ),
        );
      },
    );
  }

  // Simple background - Google Material Design 3 colors
  Widget _buildSimpleBackground(bool isDark) {
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
          // Hero section - simplified for mobile
          SizedBox(
            height: heroHeight,
            child: _buildMobileHeroSection(context, size, isDark),
          ),
          SizedBox(height: size.height * 0.04),

          // Enhanced Explore Section with button
          EnhancedExploreSection(
            isMobile: true,
            showButton: true, // Keep the button in this section
          ),
          SizedBox(height: AppSpacing.getSectionSpacing(size)),

          // Quick Actions Grid
          QuickActionsGrid(
            isDark: isDark,
            onActionTapped: _handleQuickAction,
          ),
          
          // Section Divider
          SectionDivider(
            isDark: isDark,
            subtitle: "Explore our beautiful campus locations",
            height: AppSpacing.getSectionSpacing(size) * 0.8,
            accentColor: theme.primaryColor,
          ),

          // Carousel section
          _buildCarouselSection(size, cardHeight, isDark, theme),
          SizedBox(height: AppSpacing.getSectionSpacing(size)),
          
          // Developer Credit
          DeveloperCredit(
            isDark: isDark,
            isMobile: true,
          ),
          SizedBox(height: AppSpacing.getSectionSpacing(size)),
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
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 80, // Leave margin for positioning
                ),
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
                    Flexible(
                      child: Text(
                        'H-9 Islamabad Campus',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                'Campus Gaming Experience',
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
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
        // Campus Locations Header - matching desktop/tablet style
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.5,
                    color: Colors.white, // This will be masked by the shader
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a virtual journey through our stunning campus facilities',
                style: GoogleFonts.roboto(
                  fontSize: 12,
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
        
        const SizedBox(height: 16),
        
        // Carousel with better spacing
        Container(
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
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12), // Increased margin
                        child: _buildMobileCard(card, theme, isDark),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // Enhanced Google-style Page Indicator
        GoogleStylePageIndicator(
          controller: _controller,
          count: AppConstants.locationCards.length,
          currentIndex: _selectedIndex,
          isDark: isDark,
          isMobile: true,
          primaryColor: theme.primaryColor,
          showCounter: false, // Mobile shows counter separately
        ),
        const SizedBox(height: 16),
        // Mobile Page Counter
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
      onTap: () async {
        // Direct navigation without loading dialog (loading only in categories screen)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationDetailScreen(
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
                        Icons.gamepad_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '3D',
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
              Flexible(
                flex: 1,
                child: HeaderBadge(
                  isDark: isDark,
                  text: 'IQRA Virtual Tour',
                  icon: Icons.school,
                ),
              ),
              const SizedBox(width: 8), // Add spacing between elements
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
