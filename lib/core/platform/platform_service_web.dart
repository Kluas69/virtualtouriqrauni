import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'platform_service.dart';
import '../logging/app_logger.dart';

/// Factory function for creating platform service
PlatformService createPlatformService() => WebPlatformService();

/// Web-specific implementation of PlatformService
/// 
/// This implementation uses dart:html and dart:ui_web to provide
/// web-specific functionality like WebGL, iframe management, and
/// browser API access.
class WebPlatformService implements PlatformService {
  static final WebPlatformService _instance = WebPlatformService._internal();
  factory WebPlatformService() => _instance;
  WebPlatformService._internal();
  
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  @override
  bool get isWebPlatform => true;
  
  @override
  bool get isMobilePlatform {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      // Check for mobile device indicators in user agent
      return userAgent.contains('mobile') ||
             userAgent.contains('android') ||
             userAgent.contains('iphone') ||
             userAgent.contains('ipad') ||
             userAgent.contains('ipod') ||
             userAgent.contains('blackberry') ||
             userAgent.contains('windows phone') ||
             userAgent.contains('opera mini');
    } catch (e) {
      // If user agent detection fails, check screen size as fallback
      try {
        final screen = html.window.screen;
        final width = screen?.width ?? 1920;
        return width < 768; // Common mobile breakpoint
      } catch (e) {
        return false; // Conservative fallback
      }
    }
  }
  
  @override
  bool get isDesktopPlatform => !isMobilePlatform;
  
  @override
  String get userAgent {
    try {
      return html.window.navigator.userAgent.toLowerCase();
    } catch (e) {
      return '';
    }
  }
  
  @override
  Future<bool> initializeWebGL() async {
    try {
      // Enhanced WebGL detection with multiple fallback methods
      final canvas = html.CanvasElement();
      
      // Method 1: Try WebGL 2.0 first (best performance)
      var context = canvas.getContext('webgl2');
      if (context != null) {
        AppLogger.debug('WebGL 2.0 context created successfully',
          component: 'PlatformServiceWeb');
        return true;
      }
      
      // Method 2: Try standard WebGL 1.0
      context = canvas.getContext('webgl');
      if (context != null) {
        AppLogger.debug('WebGL 1.0 context created successfully',
          component: 'PlatformServiceWeb');
        return true;
      }
      
      // Method 3: Try experimental WebGL (older browsers)
      context = canvas.getContext('experimental-webgl');
      if (context != null) {
        AppLogger.debug('Experimental WebGL context created successfully',
          component: 'PlatformServiceWeb');
        return true;
      }
      
      AppLogger.warning('No WebGL context could be created',
        component: 'PlatformServiceWeb');
      return false;
    } catch (e) {
      // CRITICAL FIX: Don't fail completely - let Three.js attempt to initialize
      AppLogger.warning('WebGL detection failed with error',
        component: 'PlatformServiceWeb',
        error: e);
      AppLogger.info('Allowing Three.js to attempt initialization anyway...',
        component: 'PlatformServiceWeb');
      return true; // Return true to allow Three.js fallback
    }
  }
  
  @override
  void registerWebView(String viewType, Function factory) {
    try {
      ui.platformViewRegistry.registerViewFactory(viewType, factory);
    } catch (e) {
      // Silently fail if registration is not possible
    }
  }
  
  @override
  void postMessage(Map<String, dynamic> message) {
    try {
      // Find all iframes and post message to them
      final iframes = html.document.querySelectorAll('iframe');
      for (final iframe in iframes) {
        if (iframe is html.IFrameElement && iframe.contentWindow != null) {
          iframe.contentWindow!.postMessage(message, '*');
        }
      }
    } catch (e) {
      // Silently fail if posting message is not possible
    }
  }
  
  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  @override
  Size getScreenSize() {
    try {
      final screen = html.window.screen;
      return Size(
        screen?.width?.toDouble() ?? 1920.0,
        screen?.height?.toDouble() ?? 1080.0,
      );
    } catch (e) {
      return const Size(1920.0, 1080.0);
    }
  }
  
  @override
  bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'webgl':
        try {
          final canvas = html.CanvasElement();
          // Try multiple WebGL context types
          return canvas.getContext('webgl2') != null || 
                 canvas.getContext('webgl') != null || 
                 canvas.getContext('experimental-webgl') != null;
        } catch (e) {
          // If detection fails, assume WebGL might still work
          AppLogger.warning('WebGL feature detection failed, assuming available',
            component: 'PlatformServiceWeb',
            error: e);
          return true;
        }
      case 'glb_support':
        // New feature check specifically for GLB file support
        try {
          // If we can create any WebGL context, we can likely load GLB files
          final canvas = html.CanvasElement();
          final hasWebGL = canvas.getContext('webgl2') != null || 
                          canvas.getContext('webgl') != null || 
                          canvas.getContext('experimental-webgl') != null;
          return hasWebGL;
        } catch (e) {
          // Optimistic fallback - let Three.js try
          return true;
        }
      case 'iframe':
        return true;
      case 'local_storage':
        try {
          return html.window.localStorage.isNotEmpty || html.window.localStorage.isEmpty;
        } catch (e) {
          return false;
        }
      case 'session_storage':
        try {
          return html.window.sessionStorage.isNotEmpty || html.window.sessionStorage.isEmpty;
        } catch (e) {
          return false;
        }
      default:
        return false;
    }
  }
  
  /// Initialize message listening for web platform
  void initializeMessageListener() {
    try {
      html.window.onMessage.listen((event) {
        if (event.data is Map) {
          _messageController.add(Map<String, dynamic>.from(event.data));
        }
      });
    } catch (e) {
      // Silently fail if message listening setup fails
    }
  }
}