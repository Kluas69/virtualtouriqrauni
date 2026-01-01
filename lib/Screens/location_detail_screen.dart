// lib/Screens/location_detail_screen.dart - OPTIMIZED FOR MOBILE
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/Screens/panorama_screen.dart';
import 'package:virtualtouriu/Screens/webgl_room_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/custom_button.dart';
import 'package:virtualtouriu/core/widgets/tag_badge.dart';
import 'package:virtualtouriu/core/widgets/theme_toggle_button.dart';
import 'package:virtualtouriu/core/utils/image_utils.dart';
import 'package:virtualtouriu/core/memory/memory_manager.dart';
import 'package:virtualtouriu/themes/themes.dart';

class LocationDetailScreen extends StatefulWidget {
  final String locationName;
  final String imagePath;
  final LocationCardData locationData;

  const LocationDetailScreen({
    super.key,
    required this.locationName,
    required this.imagePath,
    required this.locationData,
  });

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  late final List<Map<String, dynamic>> _features;

  bool _isScrolled = false;
  bool _memoryOptimized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _features = _getLocationFeatures();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.addListener(_onScroll);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_memoryOptimized && mounted) {
      final size = MediaQuery.of(context).size;
      final isMobile = size.width < 600;
      if (isMobile) {
        MemoryManager().optimizeForDevice(context);
        _memoryOptimized = true;
      }
    }
  }

  List<Map<String, dynamic>> _getLocationFeatures() {
    return AppConstants.locationFeatures[widget.locationData.name] ??
        [
          {
            'icon': Icons.wb_sunny_outlined,
            'title': 'Modern Facilities',
            'description': 'State-of-the-art amenities designed for excellence',
          },
          {
            'icon': Icons.location_on_outlined,
            'title': 'Prime Location',
            'description': 'Strategically positioned within campus grounds',
          },
          {
            'icon': Icons.groups_outlined,
            'title': 'Community Hub',
            'description': 'Perfect space for collaboration and growth',
          },
        ];
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final shouldScroll = _scrollController.offset > 100;
    if (_isScrolled != shouldScroll) {
      setState(() => _isScrolled = shouldScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openTour() {
    if (!mounted) return;

    final viewType = AppConstants.viewTypeFor(widget.locationData.name);

    if (viewType == 'webgl') {
      final url = AppConstants.webglUrlFor(widget.locationData.name);
      if (url == null || url.isEmpty) {
        // Virtual tour not available - removed snackbar feedback for cleaner UX
        return;
      }

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (_, __, ___) =>
                  WebGLRoomScreen(title: widget.locationData.name, url: url),
          transitionsBuilder:
              (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) =>
                PanoramaScreen(locationName: widget.locationData.name),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // Removed _showSnackBar method for cleaner UX

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(isDark),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDark, theme, isMobile),
              _buildContent(theme, isDark, size, isMobile, isTablet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            // Material Design 3 surface colors matching chatbot
            isDark ? const Color(0xFF000000) : const Color(0xFFFFFBFE),
            isDark ? const Color(0xFF000000) : const Color(0xFFFFFBFE),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark, ThemeData theme, bool isMobile) {
    return SliverAppBar(
      expandedHeight: isMobile ? 350 : 500,
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark
              ? const Color(0xFF000000).withValues(alpha: _isScrolled ? 0.95 : 0) // Material Design 3 dark surface
              : const Color(0xFFFFFBFE).withValues(alpha: _isScrolled ? 0.95 : 0), // Material Design 3 light surface
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            // Material Design 3 surface container colors
            color:
                isDark
                    ? const Color(0xFF2D2D30).withValues(alpha: 0.8) // Dark surface variant
                    : const Color(0xFFFFFBFE).withValues(alpha: 0.95), // Light surface
            shape: BoxShape.circle,
            // Material Design 3 shadows
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            // Material Design 3 border
            border: Border.all(
              color: isDark 
                  ? const Color(0xFF49454F).withValues(alpha: 0.12)
                  : const Color(0xFF79747E).withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark 
                  ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                  : const Color(0xFF1C1B1F),
              size: 20,
            ),
            onPressed: () => mounted ? Navigator.pop(context) : null,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: ThemeToggleButton(
            isDark: isDark,
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Use optimized image loader on mobile
            isMobile
                ? ResponsiveImageLoader.loadOptimizedImage(
                  imagePath: widget.locationData.imagePath,
                  fit: BoxFit.cover,
                )
                : Image.asset(
                  widget.locationData.imagePath,
                  fit: BoxFit.cover,
                  cacheWidth: 1200,
                  cacheHeight: 800,
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
              bottom: 32,
              left: isMobile ? 20 : 32,
              right: isMobile ? 20 : 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TagBadge(
                    text:
                        widget.locationData.tag.isNotEmpty
                            ? widget.locationData.tag
                            : 'CAMPUS',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.locationData.name,
                    style: GoogleFonts.roboto(
                      fontSize: isMobile ? 32 : 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    bool isDark,
    Size size,
    bool isMobile,
    bool isTablet,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal:
              isMobile
                  ? 20
                  : isTablet
                  ? 32
                  : 48,
          vertical: isMobile ? 32 : 48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Center(
                child: CustomButton(
                  text: 'Start Virtual Tour',
                  onPressed: _openTour,
                  fontSize: 16,
                  isMobile: isMobile,
                  width: isMobile ? double.infinity : null,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 40 : 48),
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 100),
              child: _buildAboutSection(theme, isMobile, isDark),
            ),
            SizedBox(height: isMobile ? 48 : 56),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 200),
              child: _buildFeaturesSection(theme, isMobile, isTablet, isDark),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme, bool isMobile, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagBadge(text: 'ABOUT THIS LOCATION', fontSize: 11),
        const SizedBox(height: 16),
        Text(
          widget.locationData.description.isNotEmpty
              ? widget.locationData.description
              : 'Experience the vibrant and modern atmosphere of ${widget.locationData.name} at Iqra University Islamabad Campus. This space is designed to inspire learning, collaboration, and community engagement.',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 15 : 18,
            height: 1.7,
            color: isDark 
                ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                : const Color(0xFF49454F),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(
    ThemeData theme,
    bool isMobile,
    bool isTablet,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 24 : 36,
            fontWeight: FontWeight.w900,
            color: isDark 
                ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                : const Color(0xFF1C1B1F),
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What makes this location special',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 14 : 16,
            color: isDark 
                ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                : const Color(0xFF49454F),
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: isMobile ? 24 : 32),
        _buildFeatureGrid(isMobile, isTablet, isDark, theme),
      ],
    );
  }

  Widget _buildFeatureGrid(
    bool isMobile,
    bool isTablet,
    bool isDark,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            isMobile
                ? 1
                : isTablet
                ? 2
                : 3;
        final spacing = isMobile ? 16.0 : 20.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              _features.asMap().entries.map((entry) {
                final index = entry.key;
                final feature = entry.value;

                return FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: Duration(milliseconds: 300 + (index * 100)),
                  child: Container(
                    width:
                        isMobile
                            ? constraints.maxWidth
                            : (constraints.maxWidth -
                                    spacing * (crossAxisCount - 1)) /
                                crossAxisCount,
                    padding: EdgeInsets.all(isMobile ? 20 : 24),
                    decoration: BoxDecoration(
                      // Material Design 3 surface container colors
                      color:
                          isDark
                              ? const Color(0xFF2D2D30) // Dark surface variant
                              : const Color(0xFFF7F2FA), // Light surface variant
                      borderRadius: BorderRadius.circular(20),
                      // Material Design 3 border
                      border: Border.all(
                        color:
                            isDark
                                ? const Color(0xFF49454F).withValues(alpha: 0.12)
                                : const Color(0xFF79747E).withValues(alpha: 0.12),
                        width: 1,
                      ),
                      // Material Design 3 shadows
                      boxShadow: [
                        BoxShadow(
                          color: isDark 
                              ? Colors.black.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4285F4).withValues(alpha: 0.1), // Google Blue matching chatbot
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            feature['icon'] ?? Icons.star_outline,
                            color: const Color(0xFF4285F4), // Google Blue matching chatbot
                            size: isMobile ? 24 : 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feature['title'] ?? 'Feature',
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: isDark 
                                ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                                : const Color(0xFF1C1B1F),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature['description'] ?? 'Description',
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 13 : 14,
                            height: 1.5,
                            color: isDark 
                                ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                                : const Color(0xFF49454F),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
