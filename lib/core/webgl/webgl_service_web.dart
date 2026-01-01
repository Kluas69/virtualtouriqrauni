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
  
  @override
  Future<bool> isSupported() async {
    try {
      final canvas = html.CanvasElement();
      
      // Try WebGL 2.0 first
      var context = canvas.getContext('webgl2');
      if (context != null) {
        AppLogger.debug('WebGL 2.0 context available', component: 'WebGLService');
        return true;
      }
      
      // Try standard WebGL 1.0
      context = canvas.getContext('webgl');
      if (context != null) {
        AppLogger.debug('WebGL 1.0 context available', component: 'WebGLService');
        return true;
      }
      
      // Try experimental WebGL (older browsers)
      context = canvas.getContext('experimental-webgl');
      if (context != null) {
        AppLogger.debug('Experimental WebGL context available', component: 'WebGLService');
        return true;
      }
      
      AppLogger.warning('No WebGL context available', component: 'WebGLService');
      return false;
    } catch (e) {
      AppLogger.warning('WebGL support check failed',
        component: 'WebGLService',
        error: e);
      // CRITICAL FIX: Don't fail completely - let Three.js attempt to initialize
      AppLogger.info('Allowing Three.js fallback despite WebGL detection failure', 
        component: 'WebGLService');
      return true; // Return true to allow Three.js fallback
    }
  }
  
  /// Check if GLB files can be rendered
  Future<bool> canRenderGLB() async {
    try {
      // If we have any WebGL context, we can likely render GLB files
      final hasWebGL = await isSupported();
      if (hasWebGL) {
        AppLogger.debug('GLB rendering capability confirmed', component: 'WebGLService');
        return true;
      }
      
      // Even if WebGL detection fails, Three.js might still work
      AppLogger.info('GLB rendering capability uncertain, allowing Three.js to attempt', 
        component: 'WebGLService');
      return true; // Optimistic fallback
    } catch (e) {
      AppLogger.warning('GLB capability check failed',
        component: 'WebGLService',
        error: e);
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
    if (_isInitialized) return;
    
    try {
      // Use the more lenient GLB capability check instead of strict WebGL support
      final canRender = await canRenderGLB();
      if (!canRender) {
        AppLogger.warning('GLB rendering may not be supported, but proceeding anyway',
          component: 'WebGLService');
      }
      
      _isInitialized = true;
      AppLogger.info('WebGL service initialized successfully',
        component: 'WebGLService',
        metadata: {'glbCapable': canRender});
    } catch (e) {
      AppLogger.error('Failed to initialize WebGL service',
        component: 'WebGLService',
        error: e);
      // Don't rethrow - allow the service to initialize in fallback mode
      _isInitialized = true;
      AppLogger.info('WebGL service initialized in fallback mode',
        component: 'WebGLService');
    }
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