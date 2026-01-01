import 'package:flutter/material.dart';
import 'platform_factory.dart';
import 'platform_service.dart';

/// Utility functions for platform detection and feature availability
/// 
/// This class provides convenient static methods for checking platform
/// capabilities and accessing platform-specific functionality.
class PlatformUtils {
  static PlatformService get _service => PlatformFactory.instance;
  
  /// Check if running on web platform
  static bool get isWeb => _service.isWebPlatform;
  
  /// Check if running on mobile platform
  static bool get isMobile => _service.isMobilePlatform;
  
  /// Check if running on desktop platform
  static bool get isDesktop => _service.isDesktopPlatform;
  
  /// Get user agent string (web only, empty on other platforms)
  static String get userAgent => _service.userAgent;
  
  /// Check if WebGL is available
  static Future<bool> get isWebGLAvailable => _service.initializeWebGL();
  
  /// Check if a specific feature is available
  static bool isFeatureAvailable(String feature) => _service.isFeatureAvailable(feature);
  
  /// Get screen dimensions
  static Size getScreenSize() => _service.getScreenSize();
  
  /// Initialize WebGL (web only)
  static Future<bool> initializeWebGL() => _service.initializeWebGL();
  
  /// Register web view (web only)
  static void registerWebView(String viewType, Function factory) {
    _service.registerWebView(viewType, factory);
  }
  
  /// Post message to web context (web only)
  static void postMessage(Map<String, dynamic> message) {
    _service.postMessage(message);
  }
  
  /// Get message stream from web context (web only)
  static Stream<Map<String, dynamic>> get messageStream => _service.messageStream;
  
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