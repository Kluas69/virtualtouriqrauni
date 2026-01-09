// lib/core/routing/app_routes.dart
/// Centralized route management for the Virtual Tour application
/// This file contains all route definitions, navigation methods, and route handling logic

import 'package:flutter/material.dart';
import 'package:virtualtouriu/Screens/home_screen.dart';
import 'package:virtualtouriu/Screens/categories.dart';
import 'package:virtualtouriu/Screens/location_detail_screen.dart';
import 'package:virtualtouriu/Screens/panorama_screen.dart';
import 'package:virtualtouriu/Screens/webgl_room_screen.dart';
import 'package:virtualtouriu/Screens/about_university_screen.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/logging/app_logger.dart';
import 'package:virtualtouriu/core/error/error_boundary.dart';

/// Route names as constants to avoid typos and enable refactoring
class AppRoutes {
  // Main routes
  static const String home = '/';
  static const String categories = '/categories';
  static const String about = '/about';
  
  // Location routes
  static const String locationDetail = '/location';
  static const String panorama = '/panorama';
  static const String webgl = '/webgl';
  
  // Parameterized routes
  static const String locationDetailWithId = '/location/:locationId';
  static const String panoramaWithId = '/panorama/:locationId';
  static const String webglWithId = '/webgl/:locationId';
}

/// Route arguments for passing data between screens
class RouteArguments {
  static const String locationName = 'locationName';
  static const String locationData = 'locationData';
  static const String imagePath = 'imagePath';
  static const String url = 'url';
  static const String title = 'title';
}

/// Centralized route generator for the entire application
class AppRouteGenerator {
  static const String _logComponent = 'AppRouteGenerator';

  /// Generate routes based on route settings
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    AppLogger.info('Generating route: ${settings.name}',
        component: _logComponent,
        metadata: {'route': settings.name, 'arguments': settings.arguments});

    try {
      switch (settings.name) {
        case AppRoutes.home:
          return _createRoute(
            const HomeScreen(),
            settings,
            transitionType: RouteTransitionType.fade,
          );

        case AppRoutes.categories:
          return _createRoute(
            const CategoriesScreen(),
            settings,
            transitionType: RouteTransitionType.slideFromRight,
          );

        case AppRoutes.about:
          return _createRoute(
            const AboutUniversityScreen(),
            settings,
            transitionType: RouteTransitionType.slideFromBottom,
          );

        case AppRoutes.locationDetail:
          return _handleLocationDetailRoute(settings);

        case AppRoutes.panorama:
          return _handlePanoramaRoute(settings);

        case AppRoutes.webgl:
          return _handleWebGLRoute(settings);

        default:
          // Handle parameterized routes
          if (settings.name?.startsWith('/location/') == true) {
            return _handleLocationDetailRoute(settings);
          } else if (settings.name?.startsWith('/panorama/') == true) {
            return _handlePanoramaRoute(settings);
          } else if (settings.name?.startsWith('/webgl/') == true) {
            return _handleWebGLRoute(settings);
          }
          
          return _handleUnknownRoute(settings);
      }
    } catch (e) {
      AppLogger.error('Error generating route: ${settings.name}',
          component: _logComponent,
          error: e,
          metadata: {'route': settings.name});
      
      return _createErrorRoute(settings, e.toString());
    }
  }

  /// Handle location detail routes
  static Route<dynamic> _handleLocationDetailRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    
    if (args == null) {
      AppLogger.warning('Missing arguments for location detail route',
          component: _logComponent,
          metadata: {'route': settings.name});
      return _createErrorRoute(settings, 'Missing location data');
    }

    final locationData = args[RouteArguments.locationData] as LocationCardData?;
    final locationName = args[RouteArguments.locationName] as String?;
    final imagePath = args[RouteArguments.imagePath] as String?;

    if (locationData == null || locationName == null || imagePath == null) {
      AppLogger.warning('Invalid arguments for location detail route',
          component: _logComponent,
          metadata: {'route': settings.name, 'args': args});
      return _createErrorRoute(settings, 'Invalid location data');
    }

    return _createRoute(
      LocationDetailScreen(
        locationName: locationName,
        imagePath: imagePath,
        locationData: locationData,
      ),
      settings,
      transitionType: RouteTransitionType.fade,
    );
  }

  /// Handle panorama routes
  static Route<dynamic> _handlePanoramaRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    final locationName = args?[RouteArguments.locationName] as String?;

    if (locationName == null) {
      // Try to extract from URL path
      final pathSegments = settings.name?.split('/');
      if (pathSegments != null && pathSegments.length > 2) {
        final extractedName = Uri.decodeComponent(pathSegments[2]);
        return _createRoute(
          PanoramaScreen(locationName: extractedName),
          settings,
          transitionType: RouteTransitionType.fade,
        );
      }
      
      AppLogger.warning('Missing location name for panorama route',
          component: _logComponent,
          metadata: {'route': settings.name});
      return _createErrorRoute(settings, 'Missing location name');
    }

    return _createRoute(
      PanoramaScreen(locationName: locationName),
      settings,
      transitionType: RouteTransitionType.fade,
    );
  }

  /// Handle WebGL routes
  static Route<dynamic> _handleWebGLRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    final url = args?[RouteArguments.url] as String?;
    final title = args?[RouteArguments.title] as String?;

    if (url == null || title == null) {
      AppLogger.warning('Missing arguments for WebGL route',
          component: _logComponent,
          metadata: {'route': settings.name, 'args': args});
      return _createErrorRoute(settings, 'Missing WebGL data');
    }

    return _createRoute(
      WebGLRoomScreen(url: url, title: title),
      settings,
      transitionType: RouteTransitionType.fade,
    );
  }

  /// Handle unknown routes
  static Route<dynamic> _handleUnknownRoute(RouteSettings settings) {
    AppLogger.warning('Unknown route requested: ${settings.name}',
        component: _logComponent,
        metadata: {'route': settings.name});

    return _createRoute(
      const HomeScreen(),
      RouteSettings(name: AppRoutes.home),
      transitionType: RouteTransitionType.fade,
    );
  }

  /// Create error route
  static Route<dynamic> _createErrorRoute(RouteSettings settings, String error) {
    return _createRoute(
      ErrorBoundary(
        errorMessage: 'Route Error: $error',
        child: const HomeScreen(),
      ),
      RouteSettings(name: AppRoutes.home),
      transitionType: RouteTransitionType.fade,
    );
  }

  /// Create route with specified transition
  static Route<dynamic> _createRoute(
    Widget page,
    RouteSettings settings, {
    RouteTransitionType transitionType = RouteTransitionType.fade,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => ErrorBoundary(
        errorMessage: 'Failed to load ${settings.name}',
        child: page,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(transitionType, animation, child);
      },
      transitionDuration: duration,
    );
  }

  /// Build transition animation based on type
  static Widget _buildTransition(
    RouteTransitionType type,
    Animation<double> animation,
    Widget child,
  ) {
    switch (type) {
      case RouteTransitionType.fade:
        return FadeTransition(opacity: animation, child: child);
      
      case RouteTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: child,
        );
      
      case RouteTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: child,
        );
      
      case RouteTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          )),
          child: child,
        );
      
      case RouteTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
          child: child,
        );
    }
  }
}

/// Route transition types
enum RouteTransitionType {
  fade,
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  scale,
}

/// Navigation helper methods
class AppNavigator {
  static const String _logComponent = 'AppNavigator';

  /// Navigate to home screen
  static Future<void> toHome(BuildContext context) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  /// Navigate to categories screen
  static Future<void> toCategories(BuildContext context) {
    return Navigator.pushNamed(context, AppRoutes.categories);
  }

  /// Navigate to about screen
  static Future<void> toAbout(BuildContext context) {
    return Navigator.pushNamed(context, AppRoutes.about);
  }

  /// Navigate to location detail
  static Future<void> toLocationDetail(
    BuildContext context, {
    required LocationCardData locationData,
    required String locationName,
    required String imagePath,
  }) {
    return Navigator.pushNamed(
      context,
      AppRoutes.locationDetail,
      arguments: {
        RouteArguments.locationData: locationData,
        RouteArguments.locationName: locationName,
        RouteArguments.imagePath: imagePath,
      },
    );
  }

  /// Navigate to panorama view
  static Future<void> toPanorama(
    BuildContext context, {
    required String locationName,
  }) {
    return Navigator.pushNamed(
      context,
      AppRoutes.panorama,
      arguments: {
        RouteArguments.locationName: locationName,
      },
    );
  }

  /// Navigate to WebGL view
  static Future<void> toWebGL(
    BuildContext context, {
    required String url,
    required String title,
  }) {
    return Navigator.pushNamed(
      context,
      AppRoutes.webgl,
      arguments: {
        RouteArguments.url: url,
        RouteArguments.title: title,
      },
    );
  }

  /// Smart navigation to appropriate view based on location
  static Future<void> toLocationView(
    BuildContext context, {
    required LocationCardData locationData,
  }) {
    final viewType = AppConstants.viewTypeFor(locationData.name);
    
    AppLogger.info('Navigating to location view',
        component: _logComponent,
        metadata: {
          'location': locationData.name,
          'viewType': viewType,
        });

    if (viewType == 'webgl') {
      final url = AppConstants.webglUrlFor(locationData.name);
      if (url != null && url.isNotEmpty) {
        return toWebGL(context, url: url, title: locationData.name);
      }
    }

    return toPanorama(context, locationName: locationData.name);
  }

  /// Pop current route
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}