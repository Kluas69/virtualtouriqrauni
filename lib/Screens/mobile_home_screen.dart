import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:virtualtouriu/Screens/HomeScreen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/chatbot_widget.dart';
import 'package:virtualtouriu/themes/Themes.dart';
import 'package:animate_do/animate_do.dart';

class MobileHomeScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const MobileHomeScreen({super.key, this.scrollController});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  late final PageController _controller;
  late final ScrollController _scrollController;

  int _selectedIndex = 0;
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
    _controller = PageController(
      viewportFraction: 0.85,
      initialPage: middleIndex,
    )..addListener(_onPageScroll);

    _selectedIndex = middleIndex;
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final heroHeight = (size.height * 0.50).clamp(400.0, 550.0);
        final cardHeight = size.height * 0.42;

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
                fontSize: (size.width * 0.10).clamp(32.0, 48.0),
                heightFactor: 1.0,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.04),
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            child: HomeScreen.buildInfoSection(
              context: context,
              isMobile: true,
            ),
          ),
          SizedBox(height: size.height * 0.05),
          FadeInUp(
            duration: const Duration(milliseconds: 900),
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
    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: HomeScreen.buildCarousel(
            context: context,
            cardHeight: cardHeight,
            controller: _controller,
            selectedIndex: _selectedIndex,
            isInteracting: false,
            onPageChanged: (index) => setState(() => _selectedIndex = index),
            isDesktop: false,
            onTap: (_) {},
            setInteracting: (_) {},
          ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader(bool isDark, ThemeData theme) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
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
      ),
      child: IconButton(
        icon: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          color: isDark ? Colors.amber : Colors.indigo,
        ),
        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
      ),
    );
  }
}
