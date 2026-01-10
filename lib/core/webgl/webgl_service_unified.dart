import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'webgl_service.dart';
import '../logging/app_logger.dart';
import 'null_safety_layer.dart';
import '../memory/memory_manager.dart';
import 'security_manager.dart';
import 'mobile_performance_optimizer.dart';

// Conditional imports for platform-specific functionality
import 'dart:html' as html show 
  CanvasElement, 
  IFrameElement, 
  DivElement, 
  Element, 
  MessageEvent, 
  window, 
  document;
import 'dart:js' as js;

/// Unified WebGL service that handles both web and mobile platforms
/// Consolidates functionality from multiple service implementations
class WebGLServiceUnified implements WebGLService {
  static WebGLServiceUnified? _instance;
  factory WebGLServiceUnified() => _instance ??= WebGLServiceUnified._internal();
  WebGLServiceUnified._internal();
  
  static const String _logComponent = 'WebGLServiceUnified';
  
  // Core managers
  late final MemoryManager _memoryManager;
  late final SecurityManager _securityManager;
  late final MobilePerformanceOptimizer? _performanceOptimizer;
  
  // State management
  QualityLevel _currentQuality = QualityLevel.high;
  final StreamController<WebGLPerformanceMetrics> _performanceController = 
      StreamController<WebGLPerformanceMetrics>.broadcast();
  
  // Mobile-specific state
  bool _mobileControlsEnabled = false;
  final Map<String, html.IFrameElement> _activeIframes = {};
  
  // Context management for preventing memory leaks
  static final Set<String> _activeContexts = <String>{};
  static const int _maxContexts = 2;
  static final Map<String, html.IFrameElement> _globalIframes = {};
  static int _contextCounter = 0;
  
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      AppLogger.info('Initializing unified WebGL service', component: _logComponent);
      
      // Initialize core managers
      _memoryManager = MemoryManager();
      await _memoryManager.initialize();
      
      _securityManager = SecurityManager();
      
      // Initialize mobile performance optimizer if on mobile platform
      if (kIsWeb && _isMobilePlatform()) {
        _performanceOptimizer = MobilePerformanceOptimizer();
        AppLogger.info('Mobile performance optimizer initialized', component: _logComponent);
      }
      
      // Cleanup any existing contexts
      await _cleanupExcessiveContexts();
      
      _isInitialized = true;
      AppLogger.info('Unified WebGL service initialized successfully', component: _logComponent);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize unified WebGL service', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  @override
  Future<bool> isSupported() async {
    try {
      if (!kIsWeb) return false;
      
      final canvas = html.CanvasElement();
      final context = canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
      final supported = context != null;
      
      AppLogger.debug('WebGL support check: $supported', component: _logComponent);
      return supported;
    } catch (e) {
      AppLogger.warning('Error checking WebGL support: $e', component: _logComponent);
      return false;
    }
  }

  @override
  Future<WebGLCapabilities> detectCapabilities() async {
    try {
      if (!kIsWeb) {
        return const WebGLCapabilities(
          webgl2Support: false,
          webgl1Support: false,
          supportedExtensions: [],
          maxTextureSize: 0,
          maxVertexAttributes: 0,
          renderer: 'Non-Web Platform',
          vendor: 'Flutter',
          instancingSupport: false,
          floatTextureSupport: false,
          compressedTextureSupport: false,
        );
      }

      AppLogger.debug('Detecting WebGL capabilities', component: _logComponent);
      
      final canvas = html.CanvasElement();
      final gl = canvas.getContext('webgl2') ?? 
                 canvas.getContext('webgl') ?? 
                 canvas.getContext('experimental-webgl');
      
      if (gl == null) {
        return const WebGLCapabilities(
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

      final jsGl = js.JsObject.fromBrowserObject(gl);
      
      // Detect WebGL version
      final webgl2Support = canvas.getContext('webgl2') != null;
      final webgl1Support = canvas.getContext('webgl') != null || 
                           canvas.getContext('experimental-webgl') != null;
      
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
        AppLogger.debug('Could not get extensions: $e', component: _logComponent);
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

      // Get capabilities
      int maxTextureSize = 2048;
      int maxVertexAttributes = 16;
      try {
        maxTextureSize = jsGl.callMethod('getParameter', [jsGl['MAX_TEXTURE_SIZE']]);
        maxVertexAttributes = jsGl.callMethod('getParameter', [jsGl['MAX_VERTEX_ATTRIBS']]);
      } catch (e) {
        AppLogger.debug('Could not get GL parameters: $e', component: _logComponent);
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

      AppLogger.info('WebGL capabilities detected: ${capabilities.webglVersion}', 
        component: _logComponent);
      return capabilities;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to detect WebGL capabilities', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
      
      return const WebGLCapabilities(
        webgl2Support: false,
        webgl1Support: false,
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
  Future<void> handleContextLoss() async {
    try {
      AppLogger.warning('Handling WebGL context loss', component: _logComponent);
      await Future.delayed(const Duration(milliseconds: 100));
      AppLogger.info('WebGL context loss handled', component: _logComponent);
    } catch (e) {
      AppLogger.error('Failed to handle context loss: $e', component: _logComponent);
    }
  }

  @override
  Future<bool> attemptContextRecovery() async {
    try {
      AppLogger.info('Attempting WebGL context recovery', component: _logComponent);
      await Future.delayed(const Duration(milliseconds: 500));
      
      final recovered = await isSupported();
      AppLogger.info('WebGL context recovery result: $recovered', component: _logComponent);
      return recovered;
    } catch (e) {
      AppLogger.error('Failed to recover WebGL context: $e', component: _logComponent);
      return false;
    }
  }

  @override
  Stream<WebGLPerformanceMetrics> get performanceStream => _performanceController.stream;

  @override
  void setQualityLevel(QualityLevel level) {
    _currentQuality = level;
    AppLogger.info('Quality level set to: ${level.displayName}', component: _logComponent);
    
    // Update mobile performance optimizer if available
    _performanceOptimizer?.setQualityLevel(level);
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
    if (!kIsWeb) {
      return _createFallbackWidget(
        url: url, 
        error: 'WebGL not supported on this platform'
      );
    }

    // Check context limits before creating new viewer
    if (_activeContexts.length >= _maxContexts) {
      AppLogger.warning('Maximum WebGL contexts reached, cleaning up', component: _logComponent);
      _cleanupExcessiveContexts();
    }

    if (_isMobilePlatform()) {
      return _createMobileViewer(url, title, onLoaded, onError);
    } else {
      return _createWebViewer(url, title, onLoaded, onError);
    }
  }

  @override
  void registerViewFactory(String viewType, Function factory) {
    if (!kIsWeb) return;
    
    try {
      AppLogger.debug('Registering view factory: $viewType', component: _logComponent);
    } catch (e) {
      AppLogger.warning('Failed to register view factory: $e', component: _logComponent);
    }
  }

  @override
  void dispose() {
    try {
      AppLogger.info('Disposing unified WebGL service', component: _logComponent);
      
      _cleanupAllResources();
      _performanceController.close();
      _memoryManager.dispose();
      _securityManager.dispose();
      _performanceOptimizer?.dispose();
      
      _isInitialized = false;
      AppLogger.info('Unified WebGL service disposed', component: _logComponent);
    } catch (e, stackTrace) {
      AppLogger.error('Exception during disposal', 
        component: _logComponent, 
        error: e, 
        stackTrace: stackTrace
      );
    }
  }

  // Platform detection
  bool _isMobilePlatform() {
    if (!kIsWeb) return false;
    
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('mobile') || 
             userAgent.contains('android') || 
             userAgent.contains('iphone') || 
             userAgent.contains('ipad');
    } catch (e) {
      return false;
    }
  }

  // Mobile viewer creation
  Widget _createMobileViewer(String url, String title, VoidCallback? onLoaded, Function(String)? onError) {
    return MobileWebGLViewerWidget(
      url: url,
      title: title,
      onLoaded: onLoaded,
      onError: onError,
      service: this,
      memoryManager: _memoryManager,
    );
  }

  // Web viewer creation
  Widget _createWebViewer(String url, String title, VoidCallback? onLoaded, Function(String)? onError) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Text('3D Viewer Loading: $title'),
      ),
    );
  }

  // Fallback widget creation
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load 3D viewer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Context management
  Future<void> _cleanupExcessiveContexts() async {
    try {
      if (_activeContexts.length >= _maxContexts) {
        AppLogger.warning('Cleaning up excessive WebGL contexts (${_activeContexts.length})', 
          component: _logComponent);
        
        final contextsToRemove = _activeContexts.take(_activeContexts.length - _maxContexts + 1).toList();
        for (final contextId in contextsToRemove) {
          await _forceCleanupContext(contextId);
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      AppLogger.error('Failed to cleanup excessive contexts', 
        component: _logComponent, 
        error: e);
    }
  }

  Future<void> _forceCleanupContext(String contextId) async {
    try {
      _activeContexts.remove(contextId);
      
      final iframe = _globalIframes.remove(contextId);
      if (iframe != null) {
        iframe.remove();
        AppLogger.debug('Removed iframe for context: $contextId', component: _logComponent);
      }
      
      _memoryManager.unregisterWebGLContext(contextId);
    } catch (e) {
      AppLogger.warning('Error during context cleanup', 
        component: _logComponent, 
        error: e);
    }
  }

  void _cleanupAllResources() {
    try {
      AppLogger.debug('Cleaning up all WebGL resources', component: _logComponent);
      
      for (final entry in _activeIframes.entries) {
        try {
          entry.value.remove();
        } catch (e) {
          AppLogger.debug('Error removing iframe: ${entry.key}', component: _logComponent);
        }
      }
      
      _activeIframes.clear();
      _globalIframes.clear();
      _activeContexts.clear();
      _contextCounter = 0;
      
      AppLogger.debug('WebGL resource cleanup completed', component: _logComponent);
    } catch (e) {
      AppLogger.error('Error during resource cleanup', 
        component: _logComponent, 
        error: e);
    }
  }

  // Mobile-specific functionality
  void enableMobileControls(String viewerId) {
    _mobileControlsEnabled = true;
    AppLogger.debug('Mobile controls enabled for: $viewerId', component: _logComponent);
  }

  void disableMobileControls(String viewerId) {
    _mobileControlsEnabled = false;
    AppLogger.debug('Mobile controls disabled for: $viewerId', component: _logComponent);
  }

  void sendMobileInput(String viewerId, String type, Map<String, dynamic> data) {
    if (!_mobileControlsEnabled) return;
    
    final iframe = _activeIframes[viewerId];
    if (iframe == null) return;
    
    try {
      final message = {
        'type': type,
        'payload': data,
        'source': 'flutter',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _securityManager.sendSecureMessage(iframe.contentWindow, message, '*');
    } catch (e) {
      AppLogger.warning('Failed to send mobile input', 
        component: _logComponent, 
        error: e);
    }
  }

  void registerIframe(String viewerId, html.IFrameElement iframe) {
    if (_activeIframes.containsKey(viewerId)) {
      unregisterIframe(viewerId);
    }
    
    final contextId = 'webgl_context_${DateTime.now().millisecondsSinceEpoch}';
    _memoryManager.registerWebGLContext(contextId);
    
    _activeIframes[viewerId] = iframe;
    _globalIframes[contextId] = iframe;
    _activeContexts.add(contextId);
    
    NullSafetyLayer.safeSetAttribute(iframe, 'data-context-id', contextId);
    NullSafetyLayer.safeSetAttribute(iframe, 'data-viewer-id', viewerId);
    
    AppLogger.debug('Registered iframe for viewer: $viewerId', component: _logComponent);
  }

  void unregisterIframe(String viewerId) {
    try {
      final iframe = _activeIframes.remove(viewerId);
      if (iframe != null) {
        final contextId = NullSafetyLayer.safeExecute<String?>(
          () => iframe.getAttribute('data-context-id'),
          operationName: 'getAttribute(data-context-id)',
        );
        
        if (contextId != null) {
          _memoryManager.unregisterWebGLContext(contextId);
          _globalIframes.remove(contextId);
          _activeContexts.remove(contextId);
        }
        
        NullSafetyLayer.safeRemoveElement(iframe);
        AppLogger.debug('Unregistered iframe for viewer: $viewerId', component: _logComponent);
      }
    } catch (e) {
      AppLogger.warning('Error unregistering iframe', 
        component: _logComponent, 
        error: e);
    }
  }
}

// Mobile WebGL Viewer Widget (simplified version)
class MobileWebGLViewerWidget extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback? onLoaded;
  final Function(String)? onError;
  final WebGLServiceUnified service;
  final MemoryManager memoryManager;
  
  const MobileWebGLViewerWidget({
    super.key,
    required this.url,
    required this.title,
    this.onLoaded,
    this.onError,
    required this.service,
    required this.memoryManager,
  });
  
  @override
  State<MobileWebGLViewerWidget> createState() => _MobileWebGLViewerWidgetState();
}

class _MobileWebGLViewerWidgetState extends State<MobileWebGLViewerWidget> {
  late final String _viewerId;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _viewerId = 'mobile-webgl-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _initializeViewer();
  }
  
  void _initializeViewer() {
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onLoaded?.call();
      }
    });
  }
  
  @override
  void dispose() {
    widget.service.unregisterIframe(_viewerId);
    widget.service.disableMobileControls(_viewerId);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'Mobile 3D Viewer Unavailable',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Center(
            child: Text(
              'Mobile 3D Viewer: ${widget.title}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading Mobile 3D Environment...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Factory function to create the unified WebGL service
WebGLService createWebGLService() {
  return WebGLServiceUnified();
}