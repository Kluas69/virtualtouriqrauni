import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility functions for platform detection and feature availability
/// 
/// This class provides convenient static methods for checking platform
/// capabilities and accessing platform-specific functionality.
class PlatformUtils {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;
  
  /// Check if running on mobile platform (iOS or Android)
  static bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  
  /// Check if running on desktop platform
  static bool get isDesktop => !kIsWeb && !isMobile;
  
  /// Get user agent string (web only, empty on other platforms)
  static String get userAgent {
    if (kIsWeb) {
      // This would need dart:html for actual implementation
      return 'Web Platform';
    }
    return '';
  }
  
  /// Check if WebGL is available (simplified)
  static Future<bool> get isWebGLAvailable async => kIsWeb;
  
  /// Check if a specific feature is available (simplified)
  static bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'webgl':
        return kIsWeb;
      case 'camera':
        return !kIsWeb;
      case 'sensors':
        return !kIsWeb;
      default:
        return false;
    }
  }
  
  /// Get screen dimensions
  static Size getScreenSize() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }
  
  /// Initialize WebGL (web only)
  static Future<bool> initializeWebGL() async => kIsWeb;
  
  /// Register web view (web only) - simplified
  static void registerWebView(String viewType, Function factory) {
    // Simplified implementation
  }
  
  /// Post message to web context (web only) - simplified
  static void postMessage(Map<String, dynamic> message) {
    // Simplified implementation
  }
  
  /// Get message stream from web context (web only) - simplified
  static Stream<Map<String, dynamic>> get messageStream => const Stream.empty();
  
  /// Check if device is likely mobile based on screen size
  static bool get isMobileScreen {
    final size = getScreenSize();
    return size.width < 768; // Common mobile breakpoint
  }
  
  /// Check if device is likely tablet based on screen size
  static bool get isTabletScreen {
    final size = getScreenSize();
    return size.width >= 768 && size.width < 1024;
  }
  
  /// Check if device is likely desktop based on screen size
  static bool get isDesktopScreen {
    final size = getScreenSize();
    return size.width >= 1024;
  }
  
  /// Get platform-appropriate color opacity method
  /// This helps transition from deprecated withOpacity to withValues
  static Color getColorWithOpacity(Color color, double opacity) {
    // Use the new withValues method instead of deprecated withOpacity
    return color.withValues(alpha: opacity);
  }
}