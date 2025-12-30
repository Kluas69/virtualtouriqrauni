// lib/Screens/location_detail_screen.dart - OPTIMIZED FOR MOBILE
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/Screens/PanoramaScreen.dart';
import 'package:virtualtouriu/Screens/webgl_room_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/custom_button.dart';
import 'package:virtualtouriu/core/widgets/tag_badge.dart';
import 'package:virtualtouriu/core/widgets/theme_toggle_button.dart';
import 'package:virtualtouriu/core/utils/image_utils.dart';
import 'package:virtualtouriu/core/utils/memory_manager.dart';
import 'package:virtualtouriu/themes/Themes.dart';

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
        MemoryManager.optimizeForDevice(context);
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
        _showSnackBar(
          'Virtual tour is not available for this location',
          isError: true,
        );
        return;
      }

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (_, __, ___) =>
                  WebGlRoomScreen(title: widget.locationData.name, url: url),
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.roboto(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor:
            isError ? Colors.red.shade400 : Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
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
              ? const Color(0xFF1A1A1A).withOpacity(_isScrolled ? 0.95 : 0)
              : Colors.white.withOpacity(_isScrolled ? 0.95 : 0),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87,
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                          color: Colors.black.withOpacity(0.4),
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
              child: _buildAboutSection(theme, isMobile),
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

  Widget _buildAboutSection(ThemeData theme, bool isMobile) {
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
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
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
            color: theme.textTheme.headlineMedium?.color,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What makes this location special',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 14 : 16,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            feature['icon'] ?? Icons.star_outline,
                            color: theme.primaryColor,
                            size: isMobile ? 24 : 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          feature['title'] ?? 'Feature',
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature['description'] ?? 'Description',
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 13 : 14,
                            height: 1.5,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
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
