import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:virtualtouriu/Screens/categories.dart';
import 'package:virtualtouriu/Screens/desktop_home_screen.dart';
import 'package:virtualtouriu/Screens/mobile_home_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/location_card.dart';
import 'package:virtualtouriu/responsive/Responsive_Layout.dart';
import 'package:virtualtouriu/themes/Themes.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return FutureBuilder<void>(
      future: AppConstants.initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Preparing your virtual tour...',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // Premium background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFFAFAFA),
                      isDark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFFFFFFF),
                    ],
                  ),
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isDark ? 10.0 : 6.0,
                      sigmaY: isDark ? 10.0 : 6.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.white.withOpacity(0.5),
                            isDark
                                ? Colors.black.withOpacity(0.1)
                                : Colors.white.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Responsive body - NO HEADER HERE, each screen has its own
              const ResponsiveLayout(
                mobileBody: MobileHomeScreen(),
                tabletBody: MobileHomeScreen(),
                desktopBody: DesktopHomeScreen(),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          Theme.of(context).primaryColor.withOpacity(0.1),
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
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Image unavailable',
                            style: GoogleFonts.roboto(
                              color: Colors.white.withOpacity(0.7),
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
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.8),
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
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
                          ).primaryColor.withOpacity(0.5),
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
                          color: Colors.white.withOpacity(0.95),
                          fontSize: (fontSize * 0.4).clamp(18.0, 36.0),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                      TyperAnimatedText(
                        'Explore Excellence',
                        textStyle: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: (fontSize * 0.4).clamp(18.0, 36.0),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                        speed: const Duration(milliseconds: 100),
                      ),
                      TyperAnimatedText(
                        'Virtual Campus Tour',
                        textStyle: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.95),
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
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scroll to explore',
                        style: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.6),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                '360° VIRTUAL TOUR',
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 11 : 13,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
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
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 32 : 40),

          // 3D Tour Feature Block
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
                    theme.primaryColor.withOpacity(0.15),
                    theme.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
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
                      color: theme.primaryColor.withOpacity(0.2),
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
                                ?.withOpacity(0.7),
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

          // Stats
          FadeInUp(
            duration: const Duration(milliseconds: 900),
            delay: const Duration(milliseconds: 300),
            child: Wrap(
              spacing: isMobile ? 16 : 32,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  icon: Icons.view_in_ar_rounded,
                  value: '3D',
                  label: 'Virtual Tour',
                  isDark: isDark,
                  primaryColor: theme.primaryColor,
                ),
                _buildStatCard(
                  icon: Icons.location_city,
                  value: '8+',
                  label: 'Locations',
                  isDark: isDark,
                  primaryColor: theme.primaryColor,
                ),
                _buildStatCard(
                  icon: Icons.explore,
                  value: 'HD',
                  label: 'Quality Tours',
                  isDark: isDark,
                  primaryColor: theme.primaryColor,
                ),
              ],
            ),
          ),

          // Start Tour Button (Futuristic & Animated)
          SizedBox(height: isMobile ? 32 : 40),
          FadeInUp(
            duration: const Duration(milliseconds: 950),
            delay: const Duration(milliseconds: 350),
            child: Center(
              child: _FuturisticTourButton(
                isMobile: isMobile,
                onPressed: () => navigateToCategories(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
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
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    LocationDetailScreen(
                                      locationData: effectiveCards[cardIndex],
                                      locationName: '',
                                      imagePath: '',
                                    ),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
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

// Futuristic Animated Tour Button
class _FuturisticTourButton extends StatefulWidget {
  final bool isMobile;
  final VoidCallback onPressed;

  const _FuturisticTourButton({
    required this.isMobile,
    required this.onPressed,
  });

  @override
  State<_FuturisticTourButton> createState() => _FuturisticTourButtonState();
}

class _FuturisticTourButtonState extends State<_FuturisticTourButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _isHovered ? 1.08 : _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(_glowAnimation.value),
                    blurRadius: _isHovered ? 40 : 30,
                    spreadRadius: _isHovered ? 8 : 4,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.2),
                    blurRadius: 60,
                    spreadRadius: 10,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isMobile ? 36 : 56,
                      vertical: widget.isMobile ? 18 : 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.explore_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start Virtual Tour',
                              style: GoogleFonts.roboto(
                                fontSize: widget.isMobile ? 18 : 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.0,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              'Explore in 360°',
                              style: GoogleFonts.roboto(
                                fontSize: widget.isMobile ? 11 : 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0.0,
                            end: _isHovered ? 10.0 : 0.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(value, 0),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
