import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import '../logging/app_logger.dart';

/// Platform view factory registration for WebGL viewers
/// 
/// This class handles the registration of all WebGL platform view factories
/// during app initialization to prevent runtime registration errors.
class WebGLPlatformViews {
  static bool _registered = false;
  
  /// Register all WebGL platform view factories
  /// 
  /// This must be called during app initialization in main.dart
  /// before the Flutter app starts.
  static void registerAll() {
    if (_registered) {
      AppLogger.debug('WebGL platform views already registered', 
        component: 'WebGLPlatformViews');
      return;
    }
    
    try {
      AppLogger.info('Registering WebGL platform view factories', 
        component: 'WebGLPlatformViews');
      
      // Register mobile WebGL viewer
      _registerMobileWebGLViewer();
      
      // Register desktop WebGL viewer
      _registerDesktopWebGLViewer();
      
      // Register fallback viewer
      _registerFallbackViewer();
      
      _registered = true;
      AppLogger.info('All WebGL platform view factories registered successfully', 
        component: 'WebGLPlatformViews');
        
    } catch (e) {
      AppLogger.error('Failed to register WebGL platform view factories',
        component: 'WebGLPlatformViews',
        error: e);
      
      // Continue anyway to prevent app crash
      _registered = true;
    }
  }
  
  /// Register mobile-optimized WebGL viewer
  static void _registerMobileWebGLViewer() {
    const viewType = 'mobile-webgl-viewer-stable';
    
    try {
      ui.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => _createMobileWebGLIframe(viewId),
      );
      
      AppLogger.info('Registered mobile WebGL viewer: $viewType',
        component: 'WebGLPlatformViews');
    } catch (e) {
      AppLogger.error('Failed to register mobile WebGL viewer',
        component: 'WebGLPlatformViews',
        error: e);
    }
  }
  
  /// Register desktop WebGL viewer
  static void _registerDesktopWebGLViewer() {
    const viewType = 'desktop-webgl-viewer-stable';
    
    try {
      ui.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => _createDesktopWebGLIframe(viewId),
      );
      
      AppLogger.info('Registered desktop WebGL viewer: $viewType',
        component: 'WebGLPlatformViews');
    } catch (e) {
      AppLogger.error('Failed to register desktop WebGL viewer',
        component: 'WebGLPlatformViews',
        error: e);
    }
  }
  
  /// Register fallback viewer for unsupported platforms
  static void _registerFallbackViewer() {
    const viewType = 'webgl-fallback-viewer';
    
    try {
      ui.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) => _createFallbackElement(viewId),
      );
      
      AppLogger.info('Registered fallback WebGL viewer: $viewType',
        component: 'WebGLPlatformViews');
    } catch (e) {
      AppLogger.error('Failed to register fallback WebGL viewer',
        component: 'WebGLPlatformViews',
        error: e);
    }
  }
  
  /// Create mobile-optimized WebGL iframe
  static html.Element _createMobileWebGLIframe(int viewId) {
    AppLogger.info('Creating mobile WebGL iframe with viewId: $viewId',
      component: 'WebGLPlatformViews');
    
    try {
      // Create container div for mobile iframe
      final container = html.DivElement()
        ..id = 'mobile-webgl-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#000000';
      
      // Create loading indicator
      final loadingDiv = html.DivElement()
        ..id = 'mobile-webgl-loading-$viewId'
        ..style.cssText = '''
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          color: white;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          text-align: center;
          z-index: 1000;
        ''';
      
      // Create spinner container
      final spinnerContainer = html.DivElement()
        ..style.marginBottom = '16px';
      
      final spinner = html.DivElement()
        ..style.cssText = '''
          width: 40px;
          height: 40px;
          border: 4px solid rgba(255,255,255,0.3);
          border-top: 4px solid #00ffff;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 0 auto;
        ''';
      
      final titleDiv = html.DivElement()
        ..style.cssText = 'font-size: 16px; font-weight: 600; margin-bottom: 8px;'
        ..text = 'Loading Professional 3D Classroom';
      
      final subtitleDiv = html.DivElement()
        ..style.cssText = 'font-size: 12px; opacity: 0.8;'
        ..text = 'Optimizing for mobile gaming controls...';
      
      final styleElement = html.StyleElement()
        ..text = '''
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        ''';
      
      spinnerContainer.append(spinner);
      loadingDiv.append(spinnerContainer);
      loadingDiv.append(titleDiv);
      loadingDiv.append(subtitleDiv);
      loadingDiv.append(styleElement);
      
      container.append(loadingDiv);
      
      // Store container reference for later iframe creation
      container.setAttribute('data-view-id', viewId.toString());
      container.setAttribute('data-ready', 'true');
      
      AppLogger.info('Mobile WebGL iframe container created successfully',
        component: 'WebGLPlatformViews',
        metadata: {'viewId': viewId});
      
      return container;
      
    } catch (e) {
      AppLogger.error('Failed to create mobile WebGL iframe',
        component: 'WebGLPlatformViews',
        error: e,
        metadata: {'viewId': viewId});
      
      return _createErrorElement(viewId, 'Failed to create mobile WebGL viewer: ${e.toString()}');
    }
  }
  
  /// Create desktop WebGL iframe
  static html.Element _createDesktopWebGLIframe(int viewId) {
    AppLogger.info('Creating desktop WebGL iframe with viewId: $viewId',
      component: 'WebGLPlatformViews');
    
    try {
      // Create container div for desktop iframe
      final container = html.DivElement()
        ..id = 'desktop-webgl-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.backgroundColor = '#f0f8ff';
      
      // Create loading indicator
      final loadingDiv = html.DivElement()
        ..id = 'desktop-webgl-loading-$viewId'
        ..style.cssText = '''
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          color: #333;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          text-align: center;
          z-index: 1000;
        ''';
      
      // Create spinner container
      final spinnerContainer = html.DivElement()
        ..style.marginBottom = '16px';
      
      final spinner = html.DivElement()
        ..style.cssText = '''
          width: 50px;
          height: 50px;
          border: 4px solid rgba(66, 133, 244, 0.3);
          border-top: 4px solid #4285f4;
          border-radius: 50%;
          animation: spin 1s linear infinite;
          margin: 0 auto;
        ''';
      
      final titleDiv = html.DivElement()
        ..style.cssText = 'font-size: 18px; font-weight: 600; margin-bottom: 8px;'
        ..text = 'Loading Professional 3D Environment';
      
      final subtitleDiv = html.DivElement()
        ..style.cssText = 'font-size: 14px; opacity: 0.7;'
        ..text = 'Initializing advanced Three.js game engine...';
      
      final styleElement = html.StyleElement()
        ..text = '''
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        ''';
      
      spinnerContainer.append(spinner);
      loadingDiv.append(spinnerContainer);
      loadingDiv.append(titleDiv);
      loadingDiv.append(subtitleDiv);
      loadingDiv.append(styleElement);
      
      container.append(loadingDiv);
      
      AppLogger.info('Desktop WebGL iframe container created successfully',
        component: 'WebGLPlatformViews',
        metadata: {'viewId': viewId});
      
      return container;
      
    } catch (e) {
      AppLogger.error('Failed to create desktop WebGL iframe',
        component: 'WebGLPlatformViews',
        error: e,
        metadata: {'viewId': viewId});
      
      return _createErrorElement(viewId, 'Failed to create desktop WebGL viewer: ${e.toString()}');
    }
  }
  
  /// Create fallback element for unsupported platforms
  static html.Element _createFallbackElement(int viewId) {
    AppLogger.info('Creating fallback WebGL element with viewId: $viewId',
      component: 'WebGLPlatformViews');
    
    final fallbackDiv = html.DivElement()
      ..id = 'webgl-fallback-$viewId'
      ..style.cssText = '''
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        text-align: center;
        padding: 24px;
      ''';
    
    // Create content container
    final contentDiv = html.DivElement()
      ..style.maxWidth = '400px';
    
    final iconDiv = html.DivElement()
      ..style.cssText = 'font-size: 48px; margin-bottom: 24px;'
      ..text = '🎮';
    
    final titleDiv = html.HeadingElement.h2()
      ..style.cssText = 'font-size: 24px; font-weight: 700; margin-bottom: 16px;'
      ..text = '3D Viewer Not Available';
    
    final descriptionDiv = html.ParagraphElement()
      ..style.cssText = 'font-size: 16px; line-height: 1.6; margin-bottom: 24px; opacity: 0.9;'
      ..text = 'The professional 3D classroom experience requires WebGL support and is optimized for web browsers.';
    
    final tipContainer = html.DivElement()
      ..style.cssText = '''
        background: rgba(255,255,255,0.1);
        border-radius: 12px;
        padding: 16px;
        margin-bottom: 24px;
        border: 1px solid rgba(255,255,255,0.2);
      ''';
    
    final tipText = html.ParagraphElement()
      ..style.cssText = 'font-size: 14px; margin: 0;'
      ..text = '💡 Tip: For the best 3D experience, try using Chrome, Firefox, or Edge on a desktop computer.';
    
    final retryButton = html.ButtonElement()
      ..style.cssText = '''
        background: rgba(255,255,255,0.2);
        border: 2px solid rgba(255,255,255,0.3);
        color: white;
        padding: 12px 24px;
        border-radius: 8px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.3s ease;
      '''
      ..text = '🔄 Retry Loading'
      ..onClick.listen((_) => html.window.location.reload());
    
    tipContainer.append(tipText);
    contentDiv.append(iconDiv);
    contentDiv.append(titleDiv);
    contentDiv.append(descriptionDiv);
    contentDiv.append(tipContainer);
    contentDiv.append(retryButton);
    fallbackDiv.append(contentDiv);
    
    return fallbackDiv;
  }
  
  /// Create error element
  static html.Element _createErrorElement(int viewId, String errorMessage) {
    final errorDiv = html.DivElement()
      ..id = 'webgl-error-$viewId'
      ..style.cssText = '''
        width: 100%;
        height: 100%;
        display: flex;
        flex-direction: column;
        justify-content: center;
        align-items: center;
        background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
        color: white;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        text-align: center;
        padding: 24px;
      ''';
    
    // Create content container
    final contentDiv = html.DivElement()
      ..style.maxWidth = '400px';
    
    final iconDiv = html.DivElement()
      ..style.cssText = 'font-size: 48px; margin-bottom: 24px;'
      ..text = '⚠️';
    
    final titleDiv = html.HeadingElement.h2()
      ..style.cssText = 'font-size: 20px; font-weight: 700; margin-bottom: 16px;'
      ..text = 'WebGL Initialization Error';
    
    final errorContainer = html.DivElement()
      ..style.cssText = '''
        background: rgba(0,0,0,0.2);
        border-radius: 8px;
        padding: 16px;
        margin-bottom: 24px;
        font-size: 14px;
        line-height: 1.4;
        text-align: left;
        font-family: monospace;
      '''
      ..text = errorMessage;
    
    final reloadButton = html.ButtonElement()
      ..style.cssText = '''
        background: rgba(255,255,255,0.2);
        border: 2px solid rgba(255,255,255,0.3);
        color: white;
        padding: 12px 24px;
        border-radius: 8px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
      '''
      ..text = '🔄 Reload Page'
      ..onClick.listen((_) => html.window.location.reload());
    
    contentDiv.append(iconDiv);
    contentDiv.append(titleDiv);
    contentDiv.append(errorContainer);
    contentDiv.append(reloadButton);
    errorDiv.append(contentDiv);
    
    return errorDiv;
  }
  
  /// Check if platform views are registered
  static bool get isRegistered => _registered;
  
  /// Get the appropriate view type for the current platform
  static String getViewTypeForPlatform({bool isMobile = false}) {
    if (isMobile) {
      return 'mobile-webgl-viewer-stable';
    } else {
      return 'desktop-webgl-viewer-stable';
    }
  }
  
  /// Get fallback view type
  static String get fallbackViewType => 'webgl-fallback-viewer';
}