// lib/Screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:virtualtouriu/Screens/categories.dart';
import 'package:virtualtouriu/Screens/desktop_home_screen.dart';
import 'package:virtualtouriu/Screens/mobile_home_screen.dart';
import 'package:virtualtouriu/Screens/tablet_home_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/logging/app_logger.dart';
import 'package:virtualtouriu/core/widgets/location_card.dart';
import 'package:virtualtouriu/core/widgets/stat_card.dart';
import 'package:virtualtouriu/core/widgets/tag_badge.dart';
import 'package:virtualtouriu/responsive/Responsive_Layout.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:virtualtouriu/core/routing/app_routes.dart';
import 'package:virtualtouriu/core/navigation/navigation_helpers.dart';
import 'package:virtualtouriu/core/widgets/google_style_tour_button.dart';
import 'package:virtualtouriu/core/responsive/adaptive_layout.dart';
import 'package:virtualtouriu/core/performance/performance_optimizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  // Static methods that can be accessed from other classes
  static void navigateToCategories(BuildContext context) {
    AppNavigator.toCategories(context);
  }

  static Widget buildHeroSection({
    required BuildContext context,
    required double fontSize,
    required double heightFactor,
  }) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      height: size.height * heightFactor,
      width: double.infinity,
      child: Stack(
        children: [
          ShaderMask(
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
              errorBuilder:
                  (context, error, stackTrace) => Container(
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
          ),
          Container(
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
          ),
          Positioned(
            bottom: size.height * 0.12,
            left: size.width * 0.08,
            right: size.width * 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
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
                ),
                const SizedBox(height: 20),
                FadeInUp(
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
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
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
                ),
                const SizedBox(height: 24),
                FadeInUp(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildInfoSection({
    required BuildContext context,
    required bool isMobile,
  }) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.08,
        vertical: isMobile ? 32 : 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: TagBadge(
              text: '360° VIRTUAL TOUR',
              fontSize: isMobile ? 11 : 13,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          FadeInUp(
            duration: const Duration(milliseconds: 700),
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Explore Iqra University',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 32 : 52,
                fontWeight: FontWeight.w900,
                color: theme.textTheme.headlineMedium?.color,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Discover our state-of-the-art H-9 Islamabad campus through an immersive virtual experience. Explore facilities, classrooms, and vibrant campus life.',
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 20,
                height: 1.7,
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 32 : 40),
          FadeInUp(
            duration: const Duration(milliseconds: 850),
            delay: const Duration(milliseconds: 250),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.15),
                    theme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      size: isMobile ? 40 : 56,
                      color: theme.primaryColor,
                    ),
                  ),
                  SizedBox(width: isMobile ? 16 : 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Immersive 3D Experience',
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Navigate through our campus in stunning 360-degree panoramic views',
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 14 : 16,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            delay: const Duration(milliseconds: 300),
            child: Wrap(
              spacing: isMobile ? 16 : 32,
              runSpacing: 16,
              children: [
                StatCard(
                  icon: Icons.view_in_ar_rounded,
                  value: '3D',
                  label: 'Virtual Tour',
                  isDark: isDark,
                ),
                StatCard(
                  icon: Icons.location_city,
                  value: '8+',
                  label: 'Locations',
                  isDark: isDark,
                ),
                StatCard(
                  icon: Icons.explore,
                  value: 'HD',
                  label: 'Quality Tours',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 32 : 40),
          FadeInUp(
            duration: const Duration(milliseconds: 950),
            delay: const Duration(milliseconds: 350),
            child: Center(
              child: GoogleStyleTourButton(
                isMobile: isMobile,
                onPressed: () => navigateToCategories(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCarousel({
    required BuildContext context,
    required double cardHeight,
    required PageController controller,
    required int selectedIndex,
    required bool isInteracting,
    required Function(int) onPageChanged,
    required bool isDesktop,
    List<LocationCardData> cards = const [],
    required Null Function(dynamic index) onTap,
    required Null Function(dynamic value) setInteracting,
  }) {
    final effectiveCards =
        cards.isNotEmpty ? cards : AppConstants.locationCards;
    final size = MediaQuery.of(context).size;

    return PageView.builder(
      controller: controller,
      onPageChanged: (index) => onPageChanged(index % effectiveCards.length),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final cardIndex = index % effectiveCards.length;
        final isSelected = cardIndex == selectedIndex;
        final cardWidth = size.width * (isDesktop ? 0.22 : 0.80);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: isSelected ? 1.0 : 0.92),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.7,
                child: Center(
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    margin: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 8,
                    ),
                    child: LocationCard(
                      data: effectiveCards[cardIndex],
                      isHovered: isSelected,
                      onTap: () {
                        NavigationHelpers.navigateToLocation(
                          context,
                          effectiveCards[cardIndex],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin, PerformanceOptimizedWidget {
  // Static future to prevent recreation on rebuilds
  static final Future<void> _initializationFuture = AppConstants.initializationFuture.timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      AppLogger.warning('AppConstants initialization timed out, continuing anyway',
        component: 'HomeScreen');
    },
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      child: const Text('Preparing your virtual tour...'),
                    ),
                    const SizedBox(height: 16),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                      child: const Text('Loading assets and initializing services'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // If there's an error or timeout, still show the app
        if (snapshot.hasError) {
          AppLogger.error('Error in AppConstants initialization',
            component: 'HomeScreen',
            error: snapshot.error);
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: isDark ? Colors.red.shade300 : Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.red.shade300 : Colors.red,
                        ),
                        textAlign: TextAlign.center,
                        child: const Text('Oops! Something went wrong'),
                      ),
                      const SizedBox(height: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        child: Text('Error: ${snapshot.error}'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
          body: AdaptiveLayout(
            builder: (context, config) {
              // Use new responsive system instead of old ResponsiveLayout
              if (config.isMobile) {
                return RepaintBoundary(
                  key: const ValueKey('mobile_home'),
                  child: MobileHomeScreenOptimized(),
                );
              } else if (config.isTablet) {
                return RepaintBoundary(
                  key: const ValueKey('tablet_home'),
                  child: TabletHomeScreen(),
                );
              } else {
                return RepaintBoundary(
                  key: const ValueKey('desktop_home'),
                  child: DesktopHomeScreen(),
                );
              }
            },
          ),
        );
      },
    );
  }

  static void navigateToCategories(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const CategoriesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  static Widget buildHeroSection({
    required BuildContext context,
    required double fontSize,
    required double heightFactor,
  }) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      height: size.height * heightFactor,
      width: double.infinity,
      child: Stack(
        children: [
          ShaderMask(
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
              errorBuilder:
                  (context, error, stackTrace) => Container(
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
          ),
          Container(
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
          ),
          Positioned(
            bottom: size.height * 0.12,
            left: size.width * 0.08,
            right: size.width * 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
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
                ),
                const SizedBox(height: 20),
                FadeInUp(
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
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
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
                ),
                const SizedBox(height: 24),
                FadeInUp(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
