import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'webgl_service.dart';
import '../logging/app_logger.dart';

/// Web-specific implementation of WebGL service
class WebGLServiceWeb implements WebGLService {
  static final WebGLServiceWeb _instance = WebGLServiceWeb._internal();
  factory WebGLServiceWeb() => _instance;
  WebGLServiceWeb._internal();
  
  static final Set<String> _registeredViewTypes = {};
  bool _isInitialized = false;
  
  // Context recovery state
  bool _contextLost = false;
  int _recoveryAttempts = 0;
  static const int _maxRecoveryAttempts = 3;
  
  @override
  Future<bool> isSupported() async {
    try {
      AppLogger.info('Starting WebGL support detection',
        component: 'WebGLService');
      
      final canvas = html.CanvasElement();
      
      // Try WebGL 2.0 first
      var context = canvas.getContext('webgl2');
      if (context != null) {
        AppLogger.info('WebGL 2.0 context available', 
          component: 'WebGLService',
          metadata: {'contextType': 'webgl2'});
        return true;
      } else {
        AppLogger.debug('WebGL 2.0 context not available', 
          component: 'WebGLService');
      }
      
      // Try standard WebGL 1.0
      context = canvas.getContext('webgl');
      if (context != null) {
        AppLogger.info('WebGL 1.0 context available', 
          component: 'WebGLService',
          metadata: {'contextType': 'webgl'});
        return true;
      } else {
        AppLogger.debug('Standard WebGL context not available', 
          component: 'WebGLService');
      }
      
      // Try experimental WebGL (older browsers)
      context = canvas.getContext('experimental-webgl');
      if (context != null) {
        AppLogger.info('Experimental WebGL context available', 
          component: 'WebGLService',
          metadata: {'contextType': 'experimental-webgl'});
        return true;
      } else {
        AppLogger.debug('Experimental WebGL context not available', 
          component: 'WebGLService');
      }
      
      AppLogger.warning('No WebGL context available - all detection methods failed', 
        component: 'WebGLService',
        metadata: {
          'userAgent': html.window.navigator.userAgent,
          'platform': html.window.navigator.platform,
        });
      return false;
    } catch (e) {
      AppLogger.error('WebGL support check failed with exception',
        component: 'WebGLService',
        error: e,
        metadata: {
          'userAgent': html.window.navigator.userAgent,
          'platform': html.window.navigator.platform,
        });
      // CRITICAL FIX: Don't fail completely - let Three.js attempt to initialize
      AppLogger.info('Allowing Three.js fallback despite WebGL detection failure', 
        component: 'WebGLService');
      return true; // Return true to allow Three.js fallback
    }
  }
  
  @override
  Future<WebGLCapabilities> detectCapabilities() async {
    try {
      final canvas = html.CanvasElement();
      
      // Try WebGL 2.0 first
      var gl2Context = canvas.getContext('webgl2');
      if (gl2Context != null) {
        final capabilities = await _analyzeWebGL2Context(gl2Context);
        AppLogger.debug('WebGL 2.0 capabilities detected', 
          component: 'WebGLService',
          metadata: capabilities.toMap());
        return capabilities;
      }
      
      // Try WebGL 1.0
      var gl1Context = canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
      if (gl1Context != null) {
        final capabilities = await _analyzeWebGL1Context(gl1Context);
        AppLogger.debug('WebGL 1.0 capabilities detected',
          component: 'WebGLService', 
          metadata: capabilities.toMap());
        return capabilities;
      }
      
      // No WebGL support
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
    } catch (e) {
      AppLogger.warning('WebGL capability detection failed',
        component: 'WebGLService',
        error: e);
      
      // Return optimistic fallback capabilities
      return const WebGLCapabilities(
        webgl2Support: false,
        webgl1Support: true, // Assume basic WebGL 1.0 support
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
  }
  
  Future<WebGLCapabilities> _analyzeWebGL2Context(dynamic gl) async {
    try {
      final extensions = <String>[];
      final supportedExtensions = gl.getSupportedExtensions();
      if (supportedExtensions != null) {
        extensions.addAll(List<String>.from(supportedExtensions));
      }
      
      return WebGLCapabilities(
        webgl2Support: true,
        webgl1Support: true,
        supportedExtensions: extensions,
        maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE) ?? 2048,
        maxVertexAttributes: gl.getParameter(gl.MAX_VERTEX_ATTRIBS) ?? 16,
        renderer: gl.getParameter(gl.RENDERER)?.toString() ?? 'Unknown',
        vendor: gl.getParameter(gl.VENDOR)?.toString() ?? 'Unknown',
        instancingSupport: extensions.contains('ANGLE_instanced_arrays') || 
                          extensions.contains('WEBGL_draw_instanced'),
        floatTextureSupport: extensions.contains('OES_texture_float') ||
                            extensions.contains('EXT_color_buffer_float'),
        compressedTextureSupport: extensions.any((ext) => 
          ext.contains('compressed_texture')),
        additionalInfo: {
          'webglVersion': '2.0',
          'maxDrawBuffers': gl.getParameter(gl.MAX_DRAW_BUFFERS) ?? 1,
          'maxColorAttachments': gl.getParameter(gl.MAX_COLOR_ATTACHMENTS) ?? 1,
        },
      );
    } catch (e) {
      AppLogger.warning('Error analyzing WebGL 2.0 context', 
        component: 'WebGLService', error: e);
      return const WebGLCapabilities(
        webgl2Support: true,
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
  }
  
  Future<WebGLCapabilities> _analyzeWebGL1Context(dynamic gl) async {
    try {
      final extensions = <String>[];
      final supportedExtensions = gl.getSupportedExtensions();
      if (supportedExtensions != null) {
        extensions.addAll(List<String>.from(supportedExtensions));
      }
      
      return WebGLCapabilities(
        webgl2Support: false,
        webgl1Support: true,
        supportedExtensions: extensions,
        maxTextureSize: gl.getParameter(gl.MAX_TEXTURE_SIZE) ?? 2048,
        maxVertexAttributes: gl.getParameter(gl.MAX_VERTEX_ATTRIBS) ?? 8,
        renderer: gl.getParameter(gl.RENDERER)?.toString() ?? 'Unknown',
        vendor: gl.getParameter(gl.VENDOR)?.toString() ?? 'Unknown',
        instancingSupport: extensions.contains('ANGLE_instanced_arrays'),
        floatTextureSupport: extensions.contains('OES_texture_float'),
        compressedTextureSupport: extensions.any((ext) => 
          ext.contains('compressed_texture')),
        additionalInfo: {
          'webglVersion': '1.0',
        },
      );
    } catch (e) {
      AppLogger.warning('Error analyzing WebGL 1.0 context',
        component: 'WebGLService', error: e);
      return const WebGLCapabilities(
        webgl2Support: false,
        webgl1Support: true,
        supportedExtensions: [],
        maxTextureSize: 2048,
        maxVertexAttributes: 8,
        renderer: 'Unknown',
        vendor: 'Unknown',
        instancingSupport: false,
        floatTextureSupport: false,
        compressedTextureSupport: false,
      );
    }
  }
  
  @override
  Future<bool> supportsExtension(String extension) async {
    try {
      final capabilities = await detectCapabilities();
      return capabilities.supportedExtensions.contains(extension);
    } catch (e) {
      AppLogger.warning('Extension support check failed',
        component: 'WebGLService',
        error: e,
        metadata: {'extension': extension});
      return false;
    }
  }
  
  // Placeholder implementations for interface compliance
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
    AppLogger.info('Quality level changed',
      component: 'WebGLService',
      metadata: {'level': level.displayName, 'multiplier': level.multiplier});
    
    // Notify viewers about quality change
    postMessageToFrames({
      'type': 'qualityChange',
      'level': level.displayName,
      'multiplier': level.multiplier,
    });
  }
  
  @override
  QualityLevel get currentQuality => _currentQuality;
  
  /// Check if GLB files can be rendered
  @override
  Future<bool> canRenderGLB() async {
    try {
      AppLogger.info('Starting GLB rendering capability test',
        component: 'WebGLService');
      
      // First check basic WebGL support
      final hasWebGL = await isSupported();
      if (hasWebGL) {
        AppLogger.info('Basic WebGL support confirmed for GLB rendering', 
          component: 'WebGLService');
        
        // Test Three.js specific capability if possible
        final capabilities = await detectCapabilities();
        AppLogger.info('GLB rendering capability assessment completed',
          component: 'WebGLService',
          metadata: {
            'webglSupport': hasWebGL,
            'webgl2Support': capabilities.webgl2Support,
            'webgl1Support': capabilities.webgl1Support,
            'renderer': capabilities.renderer,
            'vendor': capabilities.vendor,
          });
        return true;
      }
      
      // Even if WebGL detection fails, Three.js might still work
      AppLogger.warning('WebGL detection failed, but allowing Three.js to attempt GLB rendering', 
        component: 'WebGLService',
        metadata: {
          'fallbackStrategy': 'optimistic',
          'reason': 'Three.js may have better WebGL detection than basic canvas tests'
        });
      return true; // Optimistic fallback
    } catch (e) {
      AppLogger.error('GLB capability check failed with exception',
        component: 'WebGLService',
        error: e,
        metadata: {
          'fallbackStrategy': 'optimistic',
          'userAgent': html.window.navigator.userAgent,
        });
      return true; // Let Three.js try anyway
    }
  }
  
  @override
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  }) {
    return WebGLViewerWidget(
      url: url,
      title: title,
      onLoaded: onLoaded,
      onError: onError,
    );
  }
  
  @override
  void registerViewFactory(String viewType, Function factory) {
    try {
      if (!_registeredViewTypes.contains(viewType)) {
        ui.platformViewRegistry.registerViewFactory(viewType, factory);
        _registeredViewTypes.add(viewType);
        AppLogger.debug('Registered WebGL view factory: $viewType',
          component: 'WebGLService');
      }
    } catch (e) {
      AppLogger.error('Failed to register WebGL view factory',
        component: 'WebGLService',
        error: e,
        metadata: {'viewType': viewType});
    }
  }
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('WebGL service already initialized, skipping',
        component: 'WebGLService');
      return;
    }
    
    try {
      AppLogger.info('Initializing WebGL service',
        component: 'WebGLService',
        metadata: {
          'userAgent': html.window.navigator.userAgent,
          'platform': html.window.navigator.platform,
          'deviceMemory': html.window.navigator.deviceMemory,
          'hardwareConcurrency': html.window.navigator.hardwareConcurrency,
        });
      
      // Detect full WebGL capabilities
      final capabilities = await detectCapabilities();
      AppLogger.info('WebGL capabilities detected',
        component: 'WebGLService',
        metadata: capabilities.toMap());
      
      // Use the more lenient GLB capability check instead of strict WebGL support
      final canRender = await canRenderGLB();
      if (!canRender) {
        AppLogger.warning('GLB rendering may not be supported, but proceeding anyway',
          component: 'WebGLService');
      }
      
      // Setup context loss monitoring
      _setupContextLossMonitoring();
      AppLogger.debug('Context loss monitoring setup completed',
        component: 'WebGLService');
      
      _isInitialized = true;
      AppLogger.info('WebGL service initialized successfully',
        component: 'WebGLService',
        metadata: {
          'glbCapable': canRender,
          'webglVersion': capabilities.webglVersion,
          'renderer': capabilities.renderer,
          'vendor': capabilities.vendor,
          'contextLossMonitoring': true,
        });
    } catch (e) {
      AppLogger.error('Failed to initialize WebGL service',
        component: 'WebGLService',
        error: e,
        metadata: {
          'userAgent': html.window.navigator.userAgent,
          'platform': html.window.navigator.platform,
        });
      // Don't rethrow - allow the service to initialize in fallback mode
      _isInitialized = true;
      AppLogger.warning('WebGL service initialized in fallback mode',
        component: 'WebGLService',
        metadata: {
          'fallbackMode': true,
          'reason': 'Exception during initialization'
        });
    }
  }
  
  @override
  Future<void> handleContextLoss() async {
    _contextLost = true;
    AppLogger.warning('WebGL context loss detected',
      component: 'WebGLService',
      metadata: {'recoveryAttempts': _recoveryAttempts});
    
    // Notify all active viewers about context loss
    postMessageToFrames({
      'type': 'contextLoss',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Attempt automatic recovery
    if (_recoveryAttempts < _maxRecoveryAttempts) {
      await attemptContextRecovery();
    } else {
      AppLogger.error('Maximum context recovery attempts reached',
        component: 'WebGLService',
        metadata: {'maxAttempts': _maxRecoveryAttempts});
    }
  }
  
  @override
  Future<bool> attemptContextRecovery() async {
    if (!_contextLost) return true;
    
    _recoveryAttempts++;
    AppLogger.info('Attempting WebGL context recovery',
      component: 'WebGLService',
      metadata: {'attempt': _recoveryAttempts, 'maxAttempts': _maxRecoveryAttempts});
    
    try {
      // Wait before attempting recovery
      await Future.delayed(Duration(milliseconds: 1000 * _recoveryAttempts));
      
      // Test WebGL capability again
      final capabilities = await detectCapabilities();
      if (capabilities.hasWebGLSupport) {
        _contextLost = false;
        _recoveryAttempts = 0;
        
        // Notify viewers about successful recovery
        postMessageToFrames({
          'type': 'contextRecovered',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'capabilities': capabilities.toMap(),
        });
        
        AppLogger.info('WebGL context recovery successful',
          component: 'WebGLService');
        return true;
      } else {
        AppLogger.warning('WebGL context recovery failed - no WebGL support detected',
          component: 'WebGLService');
        return false;
      }
    } catch (e) {
      AppLogger.error('WebGL context recovery attempt failed',
        component: 'WebGLService',
        error: e,
        metadata: {'attempt': _recoveryAttempts});
      return false;
    }
  }
  
  void _setupContextLossMonitoring() {
    // Monitor for context loss events from iframes
    html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        if (data is Map && data['type'] == 'webglContextLost') {
          handleContextLoss();
        }
      } catch (e) {
        AppLogger.warning('Error processing context loss message',
          component: 'WebGLService',
          error: e);
      }
    });
  }
  
  @override
  void dispose() {
    _registeredViewTypes.clear();
    _isInitialized = false;
    AppLogger.debug('WebGL service disposed',
      component: 'WebGLService');
  }
  
  /// Create an iframe element for WebGL content
  html.IFrameElement createIFrame(String url, String viewType) {
    final iframe = html.IFrameElement()
      ..src = _buildThreeJsViewerUrl(url)
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;
    
    // Set up message listener
    html.window.onMessage.listen((event) {
      AppLogger.debug('Received WebGL message',
        component: 'WebGLService',
        metadata: {'data': event.data});
    });
    
    return iframe;
  }
  
  /// Build the Three.js viewer URL with the model
  String _buildThreeJsViewerUrl(String modelUrl) {
    // Build URL with model parameter and mobile optimization flags
    final uri = Uri.parse('/three_viewer.html');
    final params = <String, String>{
      'model': modelUrl,
    };
    
    // Add mobile optimization parameters
    if (html.window.navigator.userAgent.contains(RegExp(r'Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini', caseSensitive: false))) {
      params['mobile'] = 'true';
      params['optimize'] = 'true';
    }
    
    // Add device memory info if available
    final navigator = html.window.navigator;
    if (navigator.deviceMemory != null) {
      params['memory'] = navigator.deviceMemory.toString();
    }
    
    // Add hardware concurrency info
    if (navigator.hardwareConcurrency != null) {
      params['cores'] = navigator.hardwareConcurrency.toString();
    }
    
    return uri.replace(queryParameters: params).toString();
  }
  
  /// Post message to all WebGL iframes
  void postMessageToFrames(Map<String, dynamic> message) {
    try {
      final iframes = html.document.querySelectorAll('iframe');
      for (final iframe in iframes) {
        if (iframe is html.IFrameElement && iframe.contentWindow != null) {
          iframe.contentWindow!.postMessage(message, '*');
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to post message to WebGL frames',
        component: 'WebGLService',
        error: e);
    }
  }
}

/// Web-specific WebGL viewer widget
class WebGLViewerWidget extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback? onLoaded;
  final Function(String)? onError;
  
  const WebGLViewerWidget({
    super.key,
    required this.url,
    required this.title,
    this.onLoaded,
    this.onError,
  });
  
  @override
  State<WebGLViewerWidget> createState() => _WebGLViewerWidgetState();
}

class _WebGLViewerWidgetState extends State<WebGLViewerWidget> {
  late final String _viewType;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _viewType = 'webgl-viewer-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _registerViewer();
  }
  
  void _registerViewer() {
    final service = WebGLServiceWeb();
    
    service.registerViewFactory(_viewType, (int viewId) {
      try {
        final iframe = service.createIFrame(widget.url, _viewType);
        
        // Set up load handlers
        iframe.onLoad.listen((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            widget.onLoaded?.call();
          }
        });
        
        iframe.onError.listen((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load WebGL content';
            });
            widget.onError?.call(_errorMessage!);
          }
        });
        
        return iframe;
      } catch (e) {
        AppLogger.error('Failed to create WebGL iframe',
          component: 'WebGLViewer',
          error: e);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'WebGL initialization failed: ${e.toString()}';
          });
          widget.onError?.call(_errorMessage!);
        }
        
        // Return a fallback div
        return html.DivElement()..text = 'WebGL not available';
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'WebGL Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}