import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../memory/memory_manager.dart';
import '../logging/app_logger.dart';

/// Safe navigation service to prevent mobile crashes during screen transitions
class SafeNavigation {
  static final Map<String, bool> _screenReadyStates = {};
  static final Map<String, Completer<void>> _initializationCompleters = {};

  /// Navigate to a screen with proper preloading and safety checks
  static Future<void> navigateToScreen({
    required BuildContext context,
    required Widget screen,
    required String screenName,
    String? routeName,
    bool showLoadingDialog = true,
    Duration minLoadingTime = const Duration(milliseconds: 1500),
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    // Increase loading time for mobile devices to prevent crashes
    final adjustedLoadingTime = isMobile 
        ? Duration(milliseconds: minLoadingTime.inMilliseconds + 1500) // Extra 1.5s for mobile
        : minLoadingTime;
    
    // Show loading dialog if requested
    if (showLoadingDialog) {
      _showLoadingDialog(context, isDark, screenName);
    }

    try {
      // Preload the screen with mobile-specific optimizations
      await _preloadScreen(screenName, isMobile: isMobile);
      
      // Ensure minimum loading time for UX and stability
      await Future.delayed(adjustedLoadingTime);
      
      // Additional mobile stability check
      if (isMobile) {
        await _performMobileStabilityCheck();
      }
      
      if (context.mounted) {
        // Close loading dialog
        if (showLoadingDialog) {
          Navigator.of(context).pop();
        }
        
        // Navigate to the screen with mobile-optimized transition
        if (isMobile) {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, _) => FadeTransition(
                opacity: animation,
                child: screen,
              ),
              transitionDuration: const Duration(milliseconds: 500), // Slower for mobile
              settings: RouteSettings(name: routeName ?? '/$screenName'),
            ),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => screen,
              settings: RouteSettings(name: routeName ?? '/$screenName'),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Navigation failed',
        component: 'SafeNavigation',
        error: e,
        metadata: {'screenName': screenName, 'isMobile': isMobile});
      
      if (context.mounted) {
        // Close loading dialog
        if (showLoadingDialog) {
          Navigator.of(context).pop();
        }
        
        // Show error message
        _showErrorMessage(context, 'Failed to load $screenName: ${e.toString()}');
      }
    }
  }

  /// Preload essential data for a screen
  static Future<void> _preloadScreen(String screenName, {bool isMobile = false}) async {
    // Check if already initialized
    if (_screenReadyStates[screenName] == true) {
      return;
    }

    // Check if initialization is in progress
    if (_initializationCompleters.containsKey(screenName)) {
      return _initializationCompleters[screenName]!.future;
    }

    // Start initialization
    final completer = Completer<void>();
    _initializationCompleters[screenName] = completer;

    try {
      AppLogger.info('Preloading screen',
        component: 'SafeNavigation',
        metadata: {'screenName': screenName, 'isMobile': isMobile});

      // Common preloading tasks with mobile optimizations
      await _performCommonPreloading(isMobile: isMobile);

      // Screen-specific preloading
      switch (screenName.toLowerCase()) {
        case 'categories':
          await _preloadCategoriesScreen(isMobile: isMobile);
          break;
        case 'location_detail':
          await _preloadLocationDetailScreen(isMobile: isMobile);
          break;
        default:
          // Generic preloading with mobile consideration
          await Future.delayed(Duration(milliseconds: isMobile ? 800 : 500));
      }

      _screenReadyStates[screenName] = true;
      completer.complete();
      
      AppLogger.info('Screen preloading completed',
        component: 'SafeNavigation',
        metadata: {'screenName': screenName, 'isMobile': isMobile});
        
    } catch (e) {
      AppLogger.error('Screen preloading failed',
        component: 'SafeNavigation',
        error: e,
        metadata: {'screenName': screenName, 'isMobile': isMobile});
      
      completer.completeError(e);
    } finally {
      _initializationCompleters.remove(screenName);
    }
  }

  /// Common preloading tasks for all screens
  static Future<void> _performCommonPreloading({bool isMobile = false}) async {
    try {
      // Ensure AppConstants are initialized
      await AppConstants.initialize();
      
      // Initialize memory manager with mobile-specific optimizations
      await MemoryManager().initialize();
      
      // Optimize for mobile if needed
      if (isMobile) {
        MemoryManager().optimizeForMobile();
        
        // Additional mobile optimizations
        await _optimizeForMobile();
      }
      
      // Longer delay for mobile to ensure everything is ready
      await Future.delayed(Duration(milliseconds: isMobile ? 600 : 300));
      
    } catch (e) {
      AppLogger.warning('Common preloading failed',
        component: 'SafeNavigation',
        error: e);
    }
  }

  /// Additional mobile-specific optimizations
  static Future<void> _optimizeForMobile() async {
    try {
      // Reduce image cache size for mobile
      PaintingBinding.instance.imageCache.maximumSize = 50;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 30 << 20; // 30MB
      
      // Clear any existing cached images to free memory
      PaintingBinding.instance.imageCache.clear();
      
      // Force garbage collection
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      AppLogger.warning('Mobile optimization failed',
        component: 'SafeNavigation',
        error: e);
    }
  }

  /// Perform mobile stability check before navigation
  static Future<void> _performMobileStabilityCheck() async {
    try {
      // Give the system time to stabilize
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Check memory pressure and optimize if needed
      MemoryManager().optimizeForMobile();
      
      // Final stability delay
      await Future.delayed(const Duration(milliseconds: 200));
      
    } catch (e) {
      AppLogger.warning('Mobile stability check failed',
        component: 'SafeNavigation',
        error: e);
    }
  }

  /// Preload data specific to CategoriesScreen
  static Future<void> _preloadCategoriesScreen({bool isMobile = false}) async {
    try {
      // Ensure location data is loaded
      if (AppConstants.locationCards.isEmpty) {
        await AppConstants.initialize();
      }
      
      // Pre-warm image cache with first few images
      await _preloadImages(isMobile: isMobile);
      
      // Additional delay for mobile stability - categories screen is heavy
      await Future.delayed(Duration(milliseconds: isMobile ? 1200 : 500));
      
      // Mobile-specific optimizations for categories screen
      if (isMobile) {
        await _optimizeCategoriesForMobile();
      }
      
    } catch (e) {
      AppLogger.warning('Categories screen preloading failed',
        component: 'SafeNavigation',
        error: e);
    }
  }

  /// Optimize categories screen specifically for mobile
  static Future<void> _optimizeCategoriesForMobile() async {
    try {
      // Reduce the number of images to preload on mobile
      final imagesToPreload = AppConstants.locationCards
          .take(2) // Only preload first 2 images on mobile
          .map((card) => card.imagePath)
          .toList();

      // Preload with smaller cache sizes
      for (final imagePath in imagesToPreload) {
        try {
          // Use smaller cache dimensions for mobile
          await precacheImage(
            ResizeImage(
              AssetImage(imagePath),
              width: 400, // Smaller width for mobile
              height: 400,
            ),
            NavigatorState().context ?? 
            WidgetsBinding.instance.rootElement as BuildContext,
          );
        } catch (e) {
          // Continue with other images if one fails
          AppLogger.debug('Failed to preload mobile image',
            component: 'SafeNavigation',
            metadata: {'imagePath': imagePath});
        }
      }
      
      // Give time for images to settle in cache
      await Future.delayed(const Duration(milliseconds: 300));
      
    } catch (e) {
      AppLogger.warning('Categories mobile optimization failed',
        component: 'SafeNavigation',
        error: e);
    }
  }

  /// Preload data specific to LocationDetailScreen
  static Future<void> _preloadLocationDetailScreen({bool isMobile = false}) async {
    try {
      // Ensure location data is loaded
      await AppConstants.initialize();
      
      // Additional delay for 3D content preparation, longer for mobile
      await Future.delayed(Duration(milliseconds: isMobile ? 1000 : 800));
      
    } catch (e) {
      AppLogger.warning('Location detail screen preloading failed',
        component: 'SafeNavigation',
        error: e);
    }
  }

  /// Preload critical images to prevent loading delays
  static Future<void> _preloadImages({bool isMobile = false}) async {
    try {
      // Preload different number of images based on device type
      final imagesToPreload = AppConstants.locationCards
          .take(isMobile ? 2 : 3) // Fewer images for mobile
          .map((card) => card.imagePath)
          .toList();

      for (final imagePath in imagesToPreload) {
        try {
          // Use different cache sizes for mobile vs desktop
          if (isMobile) {
            await precacheImage(
              ResizeImage(
                AssetImage(imagePath),
                width: 400,
                height: 400,
              ),
              NavigatorState().context ?? 
              WidgetsBinding.instance.rootElement as BuildContext,
            );
          } else {
            await precacheImage(
              AssetImage(imagePath), 
              NavigatorState().context ?? 
              WidgetsBinding.instance.rootElement as BuildContext,
            );
          }
          
          // Small delay between images to prevent overwhelming mobile devices
          if (isMobile) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        } catch (e) {
          // Continue with other images if one fails
          AppLogger.debug('Failed to preload image',
            component: 'SafeNavigation',
            metadata: {'imagePath': imagePath, 'isMobile': isMobile});
        }
      }
    } catch (e) {
      AppLogger.warning('Image preloading failed',
        component: 'SafeNavigation',
        error: e);
    }
  }

  /// Show loading dialog
  static void _showLoadingDialog(BuildContext context, bool isDark, String screenName) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading ${_getScreenDisplayName(screenName)}...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMobile 
                        ? 'Optimizing for mobile device...\nThis may take a moment'
                        : 'Please wait while we prepare the content',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Mobile Optimization Active',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show error message
  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Get display name for screen
  static String _getScreenDisplayName(String screenName) {
    switch (screenName.toLowerCase()) {
      case 'categories':
        return 'locations';
      case 'location_detail':
        return 'location details';
      default:
        return screenName;
    }
  }

  /// Clear screen ready states (useful for testing or reset)
  static void clearScreenStates() {
    _screenReadyStates.clear();
    _initializationCompleters.clear();
  }

  /// Check if a screen is ready
  static bool isScreenReady(String screenName) {
    return _screenReadyStates[screenName] == true;
  }
}