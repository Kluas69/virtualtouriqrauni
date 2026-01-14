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
import 'package:virtualtouriu/core/memory/memory_manager.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:virtualtouriu/core/responsive/adaptive_layout.dart';
import 'package:virtualtouriu/core/performance/performance_monitor.dart';
import 'package:virtualtouriu/core/assets/asset_manager.dart';
import 'package:virtualtouriu/core/logging/app_logger.dart';

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
    with AutomaticKeepAliveClientMixin, PerformanceOptimizedWidget {
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

    // SPAWN SYSTEM: Get spawn configuration for this location
    final spawnConfig = AppConstants.getSpawnConfigFor(widget.locationData.name);
    
    // Log spawn configuration for debugging
    AppLogger.info('Opening tour with spawn config',
      component: 'LocationDetailScreen',
      metadata: {
        'location': widget.locationData.name,
        'spawnX': spawnConfig.position.x,
        'spawnY': spawnConfig.position.y,
        'spawnZ': spawnConfig.position.z,
        'hasCustomConfig': AppConstants.hasSpawnConfig(widget.locationData.name),
      });

    final viewType = AppConstants.viewTypeFor(widget.locationData.name);

    if (viewType == 'webgl') {
      // All locations now use the classroom 3D model with location-specific spawn points
      
      // For mobile devices, show a warning about 3D performance
      if (MediaQuery.of(context).size.width < 600) {
        _showMobile3DWarningDialog(() {
          // CRITICAL FIX: Use Navigator.of(context).push instead of Navigator.push
          // to prevent page refresh issues in Flutter web
          Navigator.of(context, rootNavigator: false).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => WebGLRoomScreen(
                title: widget.locationData.name, 
                url: 'classroom', // Use 'classroom' as room ID for Three.js
                spawnConfig: spawnConfig, // Pass spawn configuration
              ),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
              settings: RouteSettings(
                name: '/webgl/${widget.locationData.name}',
                arguments: {
                  'url': 'classroom',
                  'title': widget.locationData.name,
                  'spawnConfig': spawnConfig.toJson(),
                },
              ),
            ),
          );
        });
        return;
      }
      
      // For desktop/tablet, proceed directly
      Navigator.of(context, rootNavigator: false).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => WebGLRoomScreen(
            title: widget.locationData.name, 
            url: 'classroom', // Use 'classroom' as room ID for Three.js
            spawnConfig: spawnConfig, // Pass spawn configuration
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
          settings: RouteSettings(
            name: '/webgl/${widget.locationData.name}',
            arguments: {
              'url': 'classroom',
              'title': widget.locationData.name,
              'spawnConfig': spawnConfig.toJson(),
            },
          ),
        ),
      );
      return;
    }

    // Fallback to panorama for non-WebGL locations
    Navigator.of(context, rootNavigator: false).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PanoramaScreen(
          locationName: widget.locationData.name
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
        settings: RouteSettings(
          name: '/panorama/${widget.locationData.name}',
          arguments: {'locationName': widget.locationData.name},
        ),
      ),
    );
  }

  void _showMobile3DWarningDialog(VoidCallback onProceed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.view_in_ar, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text(' 3D Classroom'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              'You\'re about to enter a professional 3D classroom environment powered by our advanced Three.js game engine.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.engineering, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text('Professional Features:', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Advanced game engine with ECS architecture'),
                  const Text('• Professional rendering with PBR & post-processing'),
                  const Text('• Mobile-optimized controls & gyroscope support'),
                  const Text('• Real-time physics and collision detection'),
                  const Text('• Multiple character sizes (Normal, Bee, Ant)'),
                  const Text('• Quality scaling for optimal performance'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      const Text('Mobile Controls:', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Virtual joysticks for movement & camera'),
                  const Text('• Touch gestures for interaction'),
                  const Text('• Gyroscope support for immersive look-around'),
                  const Text('• Professional game-style HUD'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: This professional 3D environment requires WebGL support and will automatically optimize graphics quality based on your device capabilities.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onProceed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enter Professional 3D Tour'),
          ),
        ],
      ),
    );
  }

  void _showMobileWebGLUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('3D Tour Unavailable'),
          ],
        ),
        content: const Text(
          'The 3D virtual tour is not available for this location on mobile devices. '
          'Please try using a desktop browser for the full 3D experience, or explore other available content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Removed _showSnackBar method for cleaner UX

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AdaptiveLayout(
        builder: (context, config) {
          return Stack(
            children: [
              _buildBackground(isDark),
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(isDark, theme, config),
                  _buildContent(theme, isDark, config),
                ],
              ),
            ],
          );
        },
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

  Widget _buildAppBar(bool isDark, ThemeData theme, AdaptiveConfig config) {
    return SliverAppBar(
      expandedHeight: config.isMobile ? 350 : 500,
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
            // Made transparent for better theme integration
            color: Colors.transparent,
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
            // Use optimized image loader
            config.isMobile
                ? OptimizedImage(
                    path: widget.locationData.imagePath,
                    fit: BoxFit.cover,
                    targetSize: Size(
                      config.width,
                      config.isMobile ? 350 : 500,
                    ),
                  )
                : OptimizedImage(
                    path: widget.locationData.imagePath,
                    fit: BoxFit.cover,
                    targetSize: Size(
                      config.width,
                      config.isMobile ? 350 : 500,
                    ),
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
              left: ResponsiveSpacing.medium(config),
              right: ResponsiveSpacing.medium(config),
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
                  ResponsiveText(
                    widget.locationData.name,
                    fontSizeBuilder: (config) => config.isMobile ? 32 : 48,
                    style: GoogleFonts.roboto(
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
    AdaptiveConfig config,
  ) {
    return SliverToBoxAdapter(
      child: ResponsiveContainer(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSpacing.medium(config),
          vertical: config.isMobile ? 32 : 48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Center(
                child: CustomButton(
                  text: AppConstants.viewTypeFor(widget.locationData.name) == 'webgl'
                      ? 'Start Professional 3D Tour'
                      : 'Start Virtual Tour',
                  onPressed: _openTour,
                  fontSize: 16,
                  isMobile: config.isMobile,
                  width: config.isMobile ? double.infinity : null,
                ),
              ),
            ),
            SizedBox(height: ResponsiveSpacing.extraLarge(config)),
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 100),
              child: _buildAboutSection(theme, config, isDark),
            ),
            SizedBox(height: ResponsiveSpacing.extraLarge(config)),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 200),
              child: _buildFeaturesSection(theme, config, isDark),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme, AdaptiveConfig config, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagBadge(text: 'ABOUT THIS LOCATION', fontSize: 11),
        const SizedBox(height: 16),
        ResponsiveText(
          widget.locationData.description.isNotEmpty
              ? widget.locationData.description
              : 'Experience the vibrant and modern atmosphere of ${widget.locationData.name} at Iqra University Islamabad Campus. This space is designed to inspire learning, collaboration, and community engagement.',
          fontSizeBuilder: (config) => config.isMobile ? 15 : 18,
          style: GoogleFonts.roboto(
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
    AdaptiveConfig config,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Key Features',
          fontSizeBuilder: (config) => config.isMobile ? 24 : 36,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w900,
            color: isDark 
                ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                : const Color(0xFF1C1B1F),
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        ResponsiveText(
          'What makes this location special',
          fontSizeBuilder: (config) => config.isMobile ? 14 : 16,
          style: GoogleFonts.roboto(
            color: isDark 
                ? const Color(0xFF938F99) // Material Design 3 on-surface-variant
                : const Color(0xFF49454F),
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: ResponsiveSpacing.large(config)),
        _buildFeatureGrid(config, isDark, theme),
      ],
    );
  }

  Widget _buildFeatureGrid(
    AdaptiveConfig config,
    bool isDark,
    ThemeData theme,
  ) {
    return ResponsiveGrid(
      spacing: ResponsiveSpacing.small(config),
      runSpacing: ResponsiveSpacing.small(config),
      forceColumns: config.gridColumns.clamp(1, 3),
      children: _features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;

        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 300 + (index * 100)),
          child: Container(
            padding: EdgeInsets.all(ResponsiveSpacing.medium(config)),
            decoration: BoxDecoration(
              // Made transparent for better theme integration
              color: Colors.transparent,
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
                    color: Colors.transparent, // Made transparent for better theme integration
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.3), // Google Blue border
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    feature['icon'] ?? Icons.star_outline,
                    color: const Color(0xFF4285F4), // Google Blue matching chatbot
                    size: config.isMobile ? 24 : 28,
                  ),
                ),
                const SizedBox(height: 16),
                ResponsiveText(
                  feature['title'] ?? 'Feature',
                  fontSizeBuilder: (config) => config.isMobile ? 16 : 18,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    color: isDark 
                        ? const Color(0xFFE6E1E5) // Material Design 3 on-surface
                        : const Color(0xFF1C1B1F),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                ResponsiveText(
                  feature['description'] ?? 'Description',
                  fontSizeBuilder: (config) => config.isMobile ? 13 : 14,
                  style: GoogleFonts.roboto(
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
  }
}
