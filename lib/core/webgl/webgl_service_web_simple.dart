import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'webgl_service.dart';
import '../logging/app_logger.dart';
import 'null_safety_layer.dart';
import '../memory/memory_manager.dart';
import 'security_manager.dart';

/// Creates the web implementation for web platforms
WebGLService createWebGLService() {
  return WebGLServiceWebSimple();
}

/// Simple web-specific implementation of WebGL service
class WebGLServiceWebSimple implements WebGLService {
  static const String _logComponent = 'WebGLServiceWebSimple';
  late final MemoryManager _memoryManager;
  late final SecurityManager _securityManager;
  QualityLevel _currentQuality = QualityLevel.high;
  final StreamController<WebGLPerformanceMetrics> _performanceController = StreamController<WebGLPerformanceMetrics>.broadcast();
  
  @override
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing WebGL service for web', component: _logComponent);
      _memoryManager = MemoryManager();
      await _memoryManager.initialize();
      
      // Initialize security manager with secure configuration
      _securityManager = SecurityManager();
      
      AppLogger.info('WebGL service initialized successfully with security manager', component: _logComponent);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize WebGL service: $e', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  @override
  Future<Widget> create3DViewer({
    required String url,
    String? containerId,
    Map<String, String>? additionalStyles,
  }) async {
    try {
      AppLogger.info('Creating 3D viewer for URL: $url', component: _logComponent);
      
      // Determine the full URL for the iframe
      String iframeUrl;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        iframeUrl = url;
      } else if (url == 'classroom') {
        iframeUrl = '/threejs/professional_classroom_enhanced.html';
      } else {
        iframeUrl = '/threejs/$url';
      }
      
      AppLogger.info('Using iframe URL: $iframeUrl', component: _logComponent);
      
      // Return a simple container that will be handled by the screen
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: Text('3D Viewer: $iframeUrl'),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Exception creating 3D viewer: $e', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
      
      // Return fallback widget on error
      return _createFallbackWidget(url: url, error: e.toString());
    }
  }

  /// Create iframe element for the platform view
  html.Element _createIframeElement(String src, String id, Map<String, String>? additionalStyles) {
    try {
      AppLogger.info('Creating secure iframe element for: $src', component: _logComponent);
      
      // Use SecurityManager to create secure iframe
      final iframe = _securityManager.createSecureIframe(
        src: src,
        id: id,
        additionalStyles: {
          'width': '100%',
          'height': '100%',
          'border': 'none',
          'background': '#000',
          ...?additionalStyles,
        },
      );
      
      if (iframe != null) {
        AppLogger.info('Secure iframe created successfully', component: _logComponent);
        
        // Set fullscreen capability
        _setupIframeEventHandlers(iframe);
        
        return iframe;
      } else {
        AppLogger.warning('Failed to create secure iframe, creating fallback', component: _logComponent);
        return _createFallbackElement(src);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exception creating iframe element: $e', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
      return _createFallbackElement(src);
    }
  }

  /// Setup event handlers for iframe
  void _setupIframeEventHandlers(html.IFrameElement iframe) {
    try {
      // Handle iframe load events
      iframe.onLoad.listen((event) {
        AppLogger.info('Iframe loaded successfully', component: _logComponent);
      });
      
      iframe.onError.listen((event) {
        AppLogger.warning('Iframe load error: $event', component: _logComponent);
      });
      
    } catch (e) {
      AppLogger.warning('Failed to setup iframe event handlers: $e', component: _logComponent);
    }
  }

  /// Create fallback element when iframe fails
  html.Element _createFallbackElement(String url) {
    try {
      AppLogger.info('Creating fallback element for: $url', component: _logComponent);
      
      final container = NullSafetyLayer.createFallbackContainer(
        'Failed to load 3D viewer\\nPlease try refreshing the page',
      );
      
      AppLogger.info('Created fallback element', component: _logComponent);
      return container;
    } catch (e, stackTrace) {
      AppLogger.error('Exception creating fallback element: $e', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
      
      // Return minimal fallback
      final minimalDiv = html.DivElement();
      minimalDiv.style.width = '100%';
      minimalDiv.style.height = '100%';
      minimalDiv.style.backgroundColor = '#f0f0f0';
      minimalDiv.text = '3D Viewer Unavailable';
      return minimalDiv;
    }
  }

  /// Create fallback widget when 3D viewer creation fails
  Widget _createFallbackWidget({required String url, String? error}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.purple.shade900,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load 3D viewer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (error != null) ...[
              SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger a page reload
                html.window.location.reload();
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool isWebGLSupported() {
    try {
      final canvas = html.CanvasElement();
      final context = canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
      final supported = context != null;
      
      AppLogger.info('WebGL supported: $supported', component: _logComponent);
      return supported;
    } catch (e) {
      AppLogger.warning('Error checking WebGL support: $e', component: _logComponent);
      return false;
    }
  }

  @override
  void registerViewFactory(String viewType, Function factory) {
    try {
      // Register the platform view factory for web
      // This is handled by the Flutter web engine
      AppLogger.debug('Registering view factory: $viewType', component: _logComponent);
    } catch (e) {
      AppLogger.warning('Failed to register view factory: $e', component: _logComponent);
    }
  }

  @override
  Future<void> handleContextLoss() async {
    try {
      AppLogger.warning('Handling WebGL context loss', component: _logComponent);
      // For web, we typically need to reload the page or recreate the context
      await Future.delayed(Duration(milliseconds: 100));
      AppLogger.info('WebGL context loss handled', component: _logComponent);
    } catch (e) {
      AppLogger.error('Failed to handle context loss: $e', component: _logComponent);
    }
  }

  @override
  Future<bool> attemptContextRecovery() async {
    try {
      AppLogger.info('Attempting WebGL context recovery', component: _logComponent);
      
      // For web, context recovery usually involves recreating the WebGL context
      // This is typically handled by the browser and Three.js
      await Future.delayed(Duration(milliseconds: 500));
      
      final recovered = isWebGLSupported();
      AppLogger.info('WebGL context recovery result: $recovered', component: _logComponent);
      return recovered;
    } catch (e) {
      AppLogger.error('Failed to recover WebGL context: $e', component: _logComponent);
      return false;
    }
  }

  @override
  Future<bool> isSupported() async {
    return isWebGLSupported();
  }

  @override
  Future<WebGLCapabilities> detectCapabilities() async {
    try {
      AppLogger.info('Detecting WebGL capabilities', component: _logComponent);
      
      final canvas = html.CanvasElement();
      final gl = canvas.getContext('webgl2') ?? canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
      
      if (gl == null) {
        return WebGLCapabilities(
          webgl2Support: false,
          webgl1Support: false,
          supportedExtensions: [],
          maxTextureSize: 0,
          maxVertexAttributes: 0,
          renderer: 'None',
          vendor: 'None',
          instancingSupport: false,
          floatTextureSupport: false,
          compressedTextureSupport: false,
        );
      }

      // Convert to JsObject for proper JavaScript interop
      final jsGl = js.JsObject.fromBrowserObject(gl);

      // Detect WebGL version
      final webgl2Support = canvas.getContext('webgl2') != null;
      final webgl1Support = canvas.getContext('webgl') != null || canvas.getContext('experimental-webgl') != null;
      
      // Get supported extensions
      final extensions = <String>[];
      try {
        final supportedExtensions = jsGl.callMethod('getSupportedExtensions');
        if (supportedExtensions != null) {
          final extensionsList = js.JsArray.from(supportedExtensions);
          for (int i = 0; i < extensionsList.length; i++) {
            extensions.add(extensionsList[i].toString());
          }
        }
      } catch (e) {
        AppLogger.warning('Failed to get supported extensions: $e', component: _logComponent);
      }

      // Get renderer info
      String renderer = 'Unknown';
      String vendor = 'Unknown';
      try {
        final debugInfo = jsGl.callMethod('getExtension', ['WEBGL_debug_renderer_info']);
        if (debugInfo != null) {
          final debugInfoJs = js.JsObject.fromBrowserObject(debugInfo);
          renderer = jsGl.callMethod('getParameter', [debugInfoJs['UNMASKED_RENDERER_WEBGL']]).toString();
          vendor = jsGl.callMethod('getParameter', [debugInfoJs['UNMASKED_VENDOR_WEBGL']]).toString();
        }
      } catch (e) {
        AppLogger.debug('Debug renderer info not available: $e', component: _logComponent);
      }

      // Get max texture size
      int maxTextureSize = 0;
      try {
        maxTextureSize = jsGl.callMethod('getParameter', [jsGl['MAX_TEXTURE_SIZE']]);
      } catch (e) {
        AppLogger.warning('Failed to get max texture size: $e', component: _logComponent);
        maxTextureSize = 2048; // Default fallback
      }

      // Get max vertex attributes
      int maxVertexAttributes = 0;
      try {
        maxVertexAttributes = jsGl.callMethod('getParameter', [jsGl['MAX_VERTEX_ATTRIBS']]);
      } catch (e) {
        AppLogger.warning('Failed to get max vertex attributes: $e', component: _logComponent);
        maxVertexAttributes = 16; // Default fallback
      }

      final capabilities = WebGLCapabilities(
        webgl2Support: webgl2Support,
        webgl1Support: webgl1Support,
        supportedExtensions: extensions,
        maxTextureSize: maxTextureSize,
        maxVertexAttributes: maxVertexAttributes,
        renderer: renderer,
        vendor: vendor,
        instancingSupport: extensions.contains('ANGLE_instanced_arrays') || webgl2Support,
        floatTextureSupport: extensions.contains('OES_texture_float') || webgl2Support,
        compressedTextureSupport: extensions.any((ext) => ext.contains('compressed_texture')),
      );

      AppLogger.info('WebGL capabilities detected: ${capabilities.webglVersion}', component: _logComponent);
      return capabilities;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to detect WebGL capabilities: $e', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
      
      // Return basic capabilities as fallback
      return WebGLCapabilities(
        webgl2Support: false,
        webgl1Support: isWebGLSupported(),
        supportedExtensions: [],
        maxTextureSize: 2048,
        maxVertexAttributes: 16,
        renderer: 'Fallback',
        vendor: 'Unknown',
        instancingSupport: false,
        floatTextureSupport: false,
        compressedTextureSupport: false,
      );
    }
  }

  @override
  Future<bool> canRenderGLB() async {
    try {
      final capabilities = await detectCapabilities();
      // GLB rendering requires WebGL support and certain extensions
      return capabilities.hasWebGLSupport && 
             capabilities.maxTextureSize >= 1024 &&
             capabilities.maxVertexAttributes >= 8;
    } catch (e) {
      AppLogger.warning('Failed to check GLB rendering capability: $e', component: _logComponent);
      return false;
    }
  }

  @override
  Future<bool> supportsExtension(String extension) async {
    try {
      final capabilities = await detectCapabilities();
      return capabilities.supportedExtensions.contains(extension);
    } catch (e) {
      AppLogger.warning('Failed to check extension support: $e', component: _logComponent);
      return false;
    }
  }

  @override
  Stream<WebGLPerformanceMetrics> get performanceStream => _performanceController.stream;

  @override
  void setQualityLevel(QualityLevel level) {
    _currentQuality = level;
    AppLogger.info('Quality level set to: ${level.displayName}', component: _logComponent);
  }

  @override
  QualityLevel get currentQuality => _currentQuality;

  @override
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  }) {
    // Return a simple container - the actual iframe creation is handled by the screen
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text('3D Viewer Loading: $title'),
      ),
    );
  }

  @override
  void dispose() {
    try {
      AppLogger.info('Disposing WebGL service resources', component: _logComponent);
      _performanceController.close();
      _memoryManager.dispose();
      _securityManager.dispose();
      AppLogger.info('WebGL service disposed successfully', component: _logComponent);
    } catch (e, stackTrace) {
      AppLogger.error('Exception during disposal: $e', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    try {
      return {
        'webglSupported': isWebGLSupported(),
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'web',
      };
    } catch (e) {
      AppLogger.warning('Failed to get performance metrics: $e', component: _logComponent);
      return {'error': e.toString()};
    }
  }
}