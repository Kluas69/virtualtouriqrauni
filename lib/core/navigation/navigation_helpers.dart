// lib/core/navigation/navigation_helpers.dart
/// Navigation helper widgets and utilities for consistent navigation patterns

import 'package:flutter/material.dart';
import 'package:virtualtouriu/core/routing/app_routes.dart';
import 'package:virtualtouriu/core/constants.dart';
import 'package:virtualtouriu/core/logging/app_logger.dart';

/// Navigation helper methods for common navigation patterns
class NavigationHelpers {
  static const String _logComponent = 'NavigationHelpers';

  /// Navigate to location with appropriate view type
  static Future<void> navigateToLocation(
    BuildContext context,
    LocationCardData locationData,
  ) async {
    try {
      AppLogger.info('Navigating to location: ${locationData.name}',
          component: _logComponent);

      await AppNavigator.toLocationDetail(
        context,
        locationData: locationData,
        locationName: locationData.name,
        imagePath: locationData.imagePath,
      );
    } catch (e) {
      AppLogger.error('Failed to navigate to location: ${locationData.name}',
          component: _logComponent,
          error: e);
      
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open ${locationData.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigate to virtual tour (panorama or WebGL)
  static Future<void> navigateToVirtualTour(
    BuildContext context,
    LocationCardData locationData,
  ) async {
    try {
      AppLogger.info('Starting virtual tour for: ${locationData.name}',
          component: _logComponent);

      await AppNavigator.toLocationView(context, locationData: locationData);
    } catch (e) {
      AppLogger.error('Failed to start virtual tour: ${locationData.name}',
          component: _logComponent,
          error: e);
      
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start tour for ${locationData.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Safe navigation with error handling
  static Future<void> safeNavigate(
    BuildContext context,
    Future<void> Function() navigationFunction, {
    String? errorMessage,
  }) async {
    try {
      await navigationFunction();
    } catch (e) {
      AppLogger.error('Navigation failed',
          component: _logComponent,
          error: e);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Navigation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Custom page route with enhanced error handling
class SafePageRoute<T> extends MaterialPageRoute<T> {
  final String routeName;
  final Map<String, dynamic>? routeArguments;

  SafePageRoute({
    required WidgetBuilder builder,
    required this.routeName,
    this.routeArguments,
    RouteSettings? settings,
  }) : super(
          builder: builder,
          settings: settings ?? RouteSettings(
            name: routeName,
            arguments: routeArguments,
          ),
        );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    try {
      return super.buildPage(context, animation, secondaryAnimation);
    } catch (e) {
      AppLogger.error('Error building page: $routeName',
          component: 'SafePageRoute',
          error: e);
      
      // Return error page instead of crashing
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load page',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Route: $routeName',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Navigation observer for logging and analytics
class AppNavigationObserver extends NavigatorObserver {
  static const String _logComponent = 'AppNavigationObserver';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    AppLogger.info('Navigation: Pushed route',
        component: _logComponent,
        metadata: {
          'route': route.settings.name,
          'previousRoute': previousRoute?.settings.name,
          'arguments': route.settings.arguments,
        });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    
    AppLogger.info('Navigation: Popped route',
        component: _logComponent,
        metadata: {
          'route': route.settings.name,
          'previousRoute': previousRoute?.settings.name,
        });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    
    AppLogger.info('Navigation: Replaced route',
        component: _logComponent,
        metadata: {
          'newRoute': newRoute?.settings.name,
          'oldRoute': oldRoute?.settings.name,
        });
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    
    AppLogger.info('Navigation: Removed route',
        component: _logComponent,
        metadata: {
          'route': route.settings.name,
          'previousRoute': previousRoute?.settings.name,
        });
  }
}

/// Navigation state management
class NavigationState extends ChangeNotifier {
  final List<String> _navigationHistory = [];
  String? _currentRoute;

  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  String? get currentRoute => _currentRoute;

  void pushRoute(String routeName) {
    _navigationHistory.add(routeName);
    _currentRoute = routeName;
    notifyListeners();
  }

  void popRoute() {
    if (_navigationHistory.isNotEmpty) {
      _navigationHistory.removeLast();
      _currentRoute = _navigationHistory.isNotEmpty ? _navigationHistory.last : null;
      notifyListeners();
    }
  }

  void replaceRoute(String routeName) {
    if (_navigationHistory.isNotEmpty) {
      _navigationHistory.removeLast();
    }
    _navigationHistory.add(routeName);
    _currentRoute = routeName;
    notifyListeners();
  }

  void clearHistory() {
    _navigationHistory.clear();
    _currentRoute = null;
    notifyListeners();
  }

  bool canGoBack() {
    return _navigationHistory.length > 1;
  }

  String? getPreviousRoute() {
    return _navigationHistory.length > 1 
        ? _navigationHistory[_navigationHistory.length - 2] 
        : null;
  }
}