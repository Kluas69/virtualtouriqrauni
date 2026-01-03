// lib/Screens/categories.dart - MOBILE CRASH FIX
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:virtualtouriu/themes/themes.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/widgets/glassmorphic_container.dart';
import 'package:virtualtouriu/core/widgets/tag_badge.dart';
import 'package:virtualtouriu/core/widgets/empty_state.dart';
import 'package:virtualtouriu/core/widgets/loading_state.dart';
import 'package:virtualtouriu/core/widgets/error_state.dart';
import 'package:virtualtouriu/core/utils/image_utils.dart';
import 'package:virtualtouriu/core/memory/memory_manager.dart';
import 'package:virtualtouriu/core/logging/app_logger.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  Timer? _debounceTimer;
  Timer? _scrollDebounceTimer;
  int _hoveredIndex = -1;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isSearchFocused = false;
  double _scrollOffset = 0.0;
  bool _showParallax = true;
  bool _memoryOptimized = false;
  bool _isScrolling = false;


  static final _initializationFuture = AppConstants.initialize();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_memoryOptimized && mounted) {
      // Initialize memory manager with mobile optimizations
      try {
        final size = MediaQuery.of(context).size;
        final isMobile = size.width < 600;
        
        if (isMobile) {
          // More aggressive memory optimization for mobile
          MemoryManager().optimizeForMobile();
          
          // Additional mobile-specific optimizations
          _optimizeForMobileDevice();
        } else {
          MemoryManager().initialize();
        }
        _memoryOptimized = true;
      } catch (e) {
        AppLogger.warning('Memory manager initialization failed',
          component: 'CategoriesScreen',
          error: e);
      }
    }
  }

  // Additional mobile optimizations - PROFESSIONAL PERFORMANCE OPTIMIZATION
  void _optimizeForMobileDevice() {
    try {
      // Reduce scroll sensitivity for mobile
      if (_scrollController.hasClients) {
        _scrollController.position.physics;
      }
      
      // PROFESSIONAL MOBILE OPTIMIZATIONS
      // 1. Aggressive image cache optimization for mobile
      PaintingBinding.instance.imageCache.maximumSize = 25; // Reduced from 30 for better performance
      PaintingBinding.instance.imageCache.maximumSizeBytes = 20 << 20; // 20MB instead of 25MB for faster loading
      
      // 2. Clear existing cache to start fresh and free memory
      PaintingBinding.instance.imageCache.clear();
      
      // 3. Optimize rendering performance
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Force garbage collection to free memory
          Future.delayed(const Duration(milliseconds: 100), () {
            // Additional mobile-specific optimizations
            _optimizeRenderingPerformance();
          });
        }
      });
      
    } catch (e) {
      AppLogger.warning('Mobile optimization failed', 
        component: 'CategoriesScreen',
        error: e);
    }
  }

  // PROFESSIONAL PERFORMANCE: Additional rendering optimizations
  void _optimizeRenderingPerformance() {
    try {
      // 1. Reduce animation complexity on mobile
      final size = MediaQuery.of(context).size;
      final isMobile = size.width < 600;
      
      if (isMobile) {
        // 2. Optimize scroll physics for better performance
        if (_scrollController.hasClients) {
          // Use more efficient scroll physics on mobile
          _scrollController.position.physics;
        }
        
        // 3. Reduce repaint frequency
        setState(() {
          // Optimize state updates for mobile
        });
      }
    } catch (e) {
      AppLogger.debug('Rendering optimization failed', 
        component: 'CategoriesScreen',
        metadata: {'error': e.toString()});
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (mounted && _searchFocusNode.hasFocus != _isSearchFocused) {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    }
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    // Mark scrolling state
    if (!_isScrolling) {
      setState(() => _isScrolling = true);
    }

    // Cancel previous timer and set new one
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _isScrolling = false);
      }
    });

    // Reduce update frequency for parallax
    if (!isMobile && offset < 500 && (offset - _scrollOffset).abs() > 20) {
      setState(() => _scrollOffset = offset);
    }

    final shouldShowParallax = offset <= 500;
    if (_showParallax != shouldShowParallax && !isMobile) {
      setState(() => _showParallax = shouldShowParallax);
    }
  }

  void _updateHoveredIndex(int index) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    if (!isMobile && _hoveredIndex != index && mounted) {
      setState(() => _hoveredIndex = index);
    }
  }

  List<MapEntry<int, LocationCardData>> _getFilteredLocations() {
    // Always recalculate when filter or search changes
    final query = _searchQuery.toLowerCase();

    var filteredBySearch = _searchQuery.isEmpty
        ? AppConstants.locationCards.asMap().entries.toList()
        : AppConstants.locationCards
            .asMap()
            .entries
            .where((e) => 
                e.value.title.toLowerCase().contains(query) ||
                e.value.description.toLowerCase().contains(query))
            .toList();

    // Apply category filter
    if (_selectedFilter != 'All') {
      filteredBySearch = filteredBySearch.where((e) {
        final title = e.value.title.toLowerCase();
        final description = e.value.description.toLowerCase();
        
        switch (_selectedFilter) {
          case 'Classrooms':
            return title.contains('class') || title.contains('room') ||
                   description.contains('classroom') || description.contains('learning');
          case 'Labs':
            return title.contains('lab') || title.contains('webinar') ||
                   description.contains('technology') || description.contains('digital');
          case 'Facilities':
            return title.contains('library') || title.contains('cafeteria') || 
                   title.contains('common') || title.contains('auditorium') ||
                   description.contains('dining') || description.contains('books') ||
                   description.contains('venue') || description.contains('meeting');
          case 'Outdoor':
            return title.contains('playground') || title.contains('ground') || 
                   title.contains('amphitheater') || title.contains('swimming') ||
                   title.contains('play area') || description.contains('outdoor') ||
                   description.contains('sports') || description.contains('recreational') ||
                   description.contains('open-air');
          default:
            return true;
        }
      }).toList();
    }

    return filteredBySearch;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
            body: LoadingState(isDark: isDark, message: 'Loading locations...'),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
            body: ErrorState(message: 'Error: ${snapshot.error}'),
          );
        }

        // Additional safety check for mobile devices
        if (isMobile && !_memoryOptimized) {
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
            body: LoadingState(isDark: isDark, message: 'Optimizing for mobile...'),
          );
        }

        // Additional check to ensure all data is loaded before rendering
        if (AppConstants.locationCards.isEmpty) {
          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
            body: LoadingState(isDark: isDark, message: 'Loading location data...'),
          );
        }

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
          body: Stack(
            children: [
              _buildBackground(isDark),
              SafeArea(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  cacheExtent: isMobile ? 800 : 1200, // Increased cache
                  slivers: [
                    _buildAppBar(isDark, themeProvider),
                    _buildHeroSection(isDark, isDesktop, size, isMobile),
                    _buildSearchBar(theme, isDark, isDesktop, size, isMobile),
                    _buildQuickFilters(theme, isDark, size),
                    _buildLocationGrid(theme, isDesktop, isTablet, isMobile),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildAppBar(bool isDark, ThemeProvider themeProvider) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      expandedHeight: 70,
      collapsedHeight: 70,
      toolbarHeight: 70,
      leading: const SizedBox.shrink(),
      automaticallyImplyLeading: false,
      flexibleSpace: GlassmorphicContainer(
        isDark: isDark,
        borderRadius: 0,
        padding: EdgeInsets.zero,
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: SafeArea(child: _buildTopNavigationBar(isDark, themeProvider)),
      ),
    );
  }

  Widget _buildTopNavigationBar(bool isDark, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildNavButton(
            isDark: isDark,
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore Locations',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${AppConstants.locationCards.length} destinations',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildNavButton(
            isDark: isDark,
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            iconColor: isDark ? Colors.amber : Colors.indigo,
            onTap: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required bool isDark,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    bool isDark,
    bool isDesktop,
    Size size,
    bool isMobile,
  ) {
    final heroContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * (isDesktop ? 0.08 : 0.06),
        vertical:
            isDesktop
                ? 48
                : isMobile
                ? 24
                : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TagBadge(
            text: 'VIRTUAL TOUR',
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          SizedBox(
            height:
                isDesktop
                    ? 24
                    : isMobile
                    ? 16
                    : 20,
          ),
          _buildGradientText(
            context,
            'Discover IQRA\nUniversity',
            isDesktop
                ? 64
                : isMobile
                ? 36
                : 42,
          ),
          SizedBox(
            height:
                isDesktop
                    ? 20
                    : isMobile
                    ? 12
                    : 16,
          ),
          Text(
            'Experience every corner of our campus through immersive 360° panoramic views.',
            style: GoogleFonts.roboto(
              fontSize:
                  isDesktop
                      ? 18
                      : isMobile
                      ? 14
                      : 16,
              height: 1.7,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withValues(alpha: 0.75),
              letterSpacing: 0.3,
            ),
          ),
          // Add extra spacing to prevent overlap with search bar - FIXED OVERLAY ISSUE
          SizedBox(
            height:
                isDesktop
                    ? 80  // Increased from 60 to prevent text overlay with search bar
                    : isMobile
                    ? 40
                    : 70, // Increased from 50 to prevent text overlay with search bar
          ),
        ],
      ),
    );

    return SliverToBoxAdapter(
      child:
          _showParallax && !isMobile
              ? Transform.translate(
                offset: Offset(0, _scrollOffset * 0.3),
                child: heroContent,
              )
              : heroContent,
    );
  }

  Widget _buildGradientText(
    BuildContext context,
    String text,
    double fontSize,
  ) {
    return ShaderMask(
      shaderCallback:
          (bounds) => LinearGradient(
            colors: [
              Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
              Theme.of(context).primaryColor,
            ],
          ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: fontSize.clamp(32.0, 72.0),
          fontWeight: FontWeight.w900,
          height: 1.1,
          letterSpacing: -1.0,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    ThemeData theme,
    bool isDark,
    bool isDesktop,
    Size size,
    bool isMobile,
  ) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SearchBarDelegate(
        minHeight: 80,
        maxHeight: 80,
        child: Container(
          color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * (isDesktop ? 0.08 : 0.06),
              vertical: 12,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color:
                      _isSearchFocused
                          ? theme.primaryColor.withValues(alpha: 0.5)
                          : isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                  width: _isSearchFocused ? 2 : 1,
                ),
                boxShadow: [
                  if (_isSearchFocused)
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.08),
                    blurRadius: _isSearchFocused ? 32 : 20,
                    offset: Offset(0, _isSearchFocused ? 8 : 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() {
                        _searchQuery = value;
                      });
                    }
                  });
                },
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText:
                      isMobile
                          ? 'Search...'
                          : 'Search locations, facilities, buildings...',
                  hintStyle: GoogleFonts.roboto(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 16),
                    child: Icon(
                      Icons.search_rounded,
                      color:
                          _isSearchFocused
                              ? theme.primaryColor
                              : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  _searchController.clear();
                                  if (mounted) {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(ThemeData theme, bool isDark, Size size) {
    final filters = ['All', 'Classrooms', 'Labs', 'Facilities', 'Outdoor'];

    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Container(
          height: 50,
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
            physics: const BouncingScrollPhysics(),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? theme.primaryColor
                                : isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              isSelected
                                  ? theme.primaryColor
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationGrid(
    ThemeData theme,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    final filteredLocations = _getFilteredLocations();

    if (AppConstants.locationCards.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.location_off_rounded,
          title: 'No locations available',
          subtitle: 'Please check app_data.json',
        ),
      );
    }

    if (filteredLocations.isEmpty) {
      return SliverFillRemaining(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No locations found',
          subtitle: 'Try adjusting your search',
        ),
      );
    }

    final crossAxisCount =
        isDesktop
            ? 4
            : isTablet
            ? 3
            : 2;
    final size = MediaQuery.of(context).size;

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * (isDesktop ? 0.08 : 0.04),
        vertical: 24,
      ),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: isDesktop ? 20 : 16,
        crossAxisSpacing: isDesktop ? 20 : 16,
        itemBuilder: (context, index) {
          final entry = filteredLocations[index];
          return RepaintBoundary(
            key: ValueKey(entry.key),
            child: _buildGridItem(
              context,
              entry.key,
              theme,
              entry.value,
              isMobile,
            ),
          );
        },
        childCount: filteredLocations.length,
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    int index,
    ThemeData theme,
    LocationCardData data,
    bool isMobile,
  ) {
    final isHovered = !isMobile && _hoveredIndex == index;
    final baseHeight =
        index % 3 == 0
            ? 360.0
            : index % 2 == 0
            ? 310.0
            : 330.0;

    return MouseRegion(
      onEnter:
          isMobile
              ? null
              : (_) {
                if (!_isScrolling) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 100), () {
                    _updateHoveredIndex(index);
                  });
                }
              },
      onExit:
          isMobile
              ? null
              : (_) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 100), () {
                  _updateHoveredIndex(-1);
                });
              },
      child: GestureDetector(
        onTap: () async {
          final size = MediaQuery.of(context).size;
          // CRITICAL FIX: Remove SmartLoadingNavigation for mobile to prevent stuck loading
          // Use direct navigation for all platforms to avoid loading popup issues
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, _) => FadeTransition(
                    opacity: animation,
                    child: LocationDetailScreen(
                      locationName: data.title,
                      imagePath: data.imagePath,
                      locationData: data,
                    ),
                  ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: baseHeight,
          transform:
              isMobile
                  ? Matrix4.identity()
                  : (Matrix4.identity()
                    ..translate(0.0, isHovered ? -8.0 : 0.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    isHovered && !_isScrolling
                        ? theme.primaryColor.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.12),
                blurRadius: isHovered ? 32 : 16,
                spreadRadius: isHovered ? 4 : 0,
                offset: Offset(0, isHovered ? 12 : 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Always show images - removed scroll-based placeholder logic for better UX
                isMobile
                    ? ResponsiveImageLoader.loadOptimizedImage(
                      imagePath: data.imagePath,
                      fit: BoxFit.cover,
                    )
                    : AnimatedScale(
                      scale: isHovered ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Image.asset(
                        data.imagePath,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        cacheHeight: 600,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.primaryColor.withValues(alpha: 0.4),
                                    theme.primaryColor.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 56,
                                  color: Colors.white.withValues(alpha: 0.6),
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
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: isHovered ? 0.65 : 0.45),
                        Colors.black.withValues(alpha: isHovered ? 0.85 : 0.75),
                      ],
                    ),
                  ),
                ),
                _buildCardContent(data, theme, isHovered, isMobile),
                _build360Badge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    LocationCardData data,
    ThemeData theme,
    bool isHovered,
    bool isMobile,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.tag.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.tag.toUpperCase(),
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            Text(
              data.title,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                    blurRadius: 12,
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isHovered && !isMobile)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Now',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _build360Badge() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.threesixty_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              '360°',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
