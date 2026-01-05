import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'webgl_service.dart';
import '../logging/app_logger.dart';

/// Creates the web implementation for web platforms
WebGLService createWebGLService() {
  return WebGLServiceWebSimple();
}

/// Simple web-specific implementation of WebGL service
class WebGLServiceWebSimple implements WebGLService {
  @override
  Future<bool> isSupported() async {
    try {
      final canvas = html.CanvasElement();
      var context = canvas.getContext('webgl2') ?? canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
      return context != null;
    } catch (e) {
      return true; // Optimistic fallback
    }
  }
  
  @override
  Future<WebGLCapabilities> detectCapabilities() async {
    return const WebGLCapabilities(
      webgl2Support: false,
      webgl1Support: true,
      supportedExtensions: [],
      maxTextureSize: 2048,
      maxVertexAttributes: 16,
      renderer: 'Unknown',
      vendor: 'Unknown',
      instancingSupport: false,
      floatTextureSupport: false,
      compressedTextureSupport: false,
    );
  }
  
  @override
  Future<bool> supportsExtension(String extension) async => false;
  
  @override
  Stream<WebGLPerformanceMetrics> get performanceStream => 
    Stream.periodic(const Duration(seconds: 1), (_) => WebGLPerformanceMetrics(
      triangleCount: 0,
      drawCalls: 0,
      textureCount: 0,
      memoryUsageMB: 0.0,
      currentFPS: 60.0,
      isOptimized: true,
      timestamp: DateTime.now(),
    ));
  
  QualityLevel _currentQuality = QualityLevel.high;
  
  @override
  void setQualityLevel(QualityLevel level) {
    _currentQuality = level;
  }
  
  @override
  QualityLevel get currentQuality => _currentQuality;
  
  @override
  Future<bool> canRenderGLB() async => true;
  
  @override
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  }) {
    // CRITICAL FIX: Use pre-registered platform view for desktop
    final viewType = 'desktop-webgl-viewer-stable';
    
    // Determine which HTML file to use based on the URL
    String htmlFile;
    if (url == 'classroom' || url.contains('classroom')) {
      // Use the professional Three.js system for classroom
      htmlFile = './threejs/professional_classroom_enhanced.html';
    } else {
      // Use the professional viewer for other content too
      htmlFile = './threejs/professional_classroom_enhanced.html';
    }
    
    // Initialize the iframe content in the pre-registered platform view
    _initializeDesktopIframeContent(htmlFile, url, title, onLoaded, onError);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
  
  /// Initialize iframe content in the pre-registered desktop platform view
  void _initializeDesktopIframeContent(
    String htmlFile, 
    String url, 
    String title, 
    VoidCallback? onLoaded, 
    Function(String)? onError
  ) {
    Timer(const Duration(milliseconds: 500), () {
      try {
        // Find any desktop WebGL container that's ready
        final containers = html.document.querySelectorAll('[id*="desktop-webgl-container"]');
        
        if (containers.isNotEmpty) {
          final container = containers.first as html.Element;
          AppLogger.info('Found desktop WebGL container: ${container.id}',
            component: 'WebGLServiceWebSimple');
          
          _createDesktopIframeInContainer(container, htmlFile, url, title, onLoaded, onError);
        } else {
          AppLogger.warning('No desktop WebGL container found, retrying...',
            component: 'WebGLServiceWebSimple');
          
          // Retry after a longer delay
          Timer(const Duration(seconds: 1), () {
            _initializeDesktopIframeContent(htmlFile, url, title, onLoaded, onError);
          });
        }
      } catch (e) {
        AppLogger.error('Failed to initialize desktop iframe content',
          component: 'WebGLServiceWebSimple',
          error: e);
        onError?.call('Failed to initialize desktop 3D viewer: ${e.toString()}');
      }
    });
  }
  
  /// Create iframe in the desktop container
  void _createDesktopIframeInContainer(
    html.Element container,
    String htmlFile,
    String url,
    String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  ) {
    try {
      // Remove loading indicator
      final loadingDiv = container.querySelector('[id*="loading"]');
      loadingDiv?.remove();
      
      // Create the actual iframe
      final iframe = html.IFrameElement()
        ..src = htmlFile
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.overflow = 'hidden'
        ..allow = 'accelerometer; gyroscope; magnetometer; fullscreen'
        ..allowFullscreen = true
        ..setAttribute('loading', 'eager')
        ..setAttribute('importance', 'high');
      
      // Enhanced iframe configuration for professional Three.js viewer
      iframe.style.setProperty('border-radius', '8px');
      iframe.style.setProperty('box-shadow', '0 4px 20px rgba(0,0,0,0.1)');
      
      // Add iframe to container
      container.append(iframe);
      
      // Handle iframe load events
      iframe.onLoad.listen((_) {
        AppLogger.info('Professional 3D classroom viewer loaded successfully',
          component: 'WebGLServiceWebSimple',
          metadata: {
            'htmlFile': htmlFile, 
            'url': url, 
            'title': title,
            'engine': 'Three.js Game Engine'
          });
        
        // Send configuration to the professional viewer
        Timer(const Duration(milliseconds: 500), () {
          try {
            iframe.contentWindow?.postMessage({
              'type': 'configure',
              'roomId': url,
              'title': title,
              'mobile': _isMobileDevice(),
              'quality': _getQualityForDevice(),
              'features': {
                'shadows': true,
                'postProcessing': true,
                'physics': true,
                'mobileControls': _isMobileDevice(),
                'gyroscope': _isMobileDevice(),
              }
            }, '*');
          } catch (e) {
            AppLogger.warning('Failed to send configuration to professional viewer',
              component: 'WebGLServiceWebSimple', error: e);
          }
        });
        
        onLoaded?.call();
      });
      
      iframe.onError.listen((event) {
        AppLogger.error('Professional 3D classroom viewer failed to load',
          component: 'WebGLServiceWebSimple',
          error: event,
          metadata: {'htmlFile': htmlFile, 'url': url});
        onError?.call('Failed to load professional 3D classroom viewer');
      });
      
      // Listen for messages from the professional iframe
      html.window.onMessage.listen((event) {
        if (event.data is Map) {
          final data = event.data as Map;
          
          switch (data['type']) {
            case 'professionalClassroomLoaded':
              AppLogger.info('Professional classroom model loaded successfully',
                component: 'WebGLServiceWebSimple',
                metadata: {
                  'success': data['success'], 
                  'engine': data['engine'],
                  'systems': data['systems'],
                  'quality': data['quality']
                });
              onLoaded?.call();
              break;
              
            case 'professionalClassroomError':
              AppLogger.error('Professional classroom viewer error',
                component: 'WebGLServiceWebSimple',
                error: data['error']);
              onError?.call(data['error'] ?? 'Professional viewer error');
              break;
              
            case 'professionalEngineReady':
              AppLogger.info('Professional game engine initialized',
                component: 'WebGLServiceWebSimple',
                metadata: {
                  'fps': data['fps'],
                  'quality': data['quality'],
                  'systems': data['systems']
                });
              break;
              
            case 'professionalPerformanceUpdate':
              // Handle performance updates from the professional engine
              AppLogger.debug('Professional engine performance update',
                component: 'WebGLServiceWebSimple',
                metadata: {
                  'fps': data['fps'],
                  'triangles': data['triangles'],
                  'drawCalls': data['drawCalls']
                });
              break;
          }
        }
      });
      
      AppLogger.info('Desktop WebGL iframe created successfully',
        component: 'WebGLServiceWebSimple',
        metadata: {'url': htmlFile});
        
    } catch (e) {
      AppLogger.error('Failed to create desktop iframe',
        component: 'WebGLServiceWebSimple',
        error: e);
      onError?.call('Failed to create desktop 3D viewer: ${e.toString()}');
    }
  }
  
  /// Detect if running on mobile device
  bool _isMobileDevice() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('mobile') || 
           userAgent.contains('android') || 
           userAgent.contains('iphone') || 
           userAgent.contains('ipad');
  }
  
  /// Get optimal quality level for current device
  String _getQualityForDevice() {
    if (_isMobileDevice()) {
      return 'medium'; // Optimized for mobile
    }
    
    // Check for high-end desktop features
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    if (userAgent.contains('chrome') || userAgent.contains('firefox')) {
      return 'high'; // Modern browsers can handle high quality
    }
    
    return 'medium'; // Safe default
  }
  
  @override
  void registerViewFactory(String viewType, Function factory) {
    // No-op for simple implementation
  }
  
  @override
  Future<void> initialize() async {
    // Simple initialization
  }
  
  @override
  Future<void> handleContextLoss() async {
    // No-op
  }
  
  @override
  Future<bool> attemptContextRecovery() async => true;
  
  @override
  void dispose() {
    // No-op
  }
}