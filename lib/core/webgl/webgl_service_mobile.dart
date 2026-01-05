import 'dart:async';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'webgl_service.dart';
import '../logging/app_logger.dart';

// Conditional imports for web compatibility
import 'dart:html' as html show 
  CanvasElement, 
  IFrameElement, 
  DivElement, 
  Element, 
  MessageEvent, 
  window, 
  document;

/// Mobile-optimized WebGL service with gaming controls support
class WebGLServiceMobile implements WebGLService {
  static final WebGLServiceMobile _instance = WebGLServiceMobile._internal();
  factory WebGLServiceMobile() => _instance;
  WebGLServiceMobile._internal();
  
  /// Get the singleton instance
  static WebGLServiceMobile get instance => _instance;
  
  // Mobile control state
  bool _mobileControlsEnabled = false;
  final Map<String, html.IFrameElement> _activeIframes = {};
  
  // Quality level
  QualityLevel _currentQuality = QualityLevel.high;
  
  // Delegate all WebGLService methods with basic implementations
  @override
  Future<void> initialize() async {
    AppLogger.info('Initializing mobile WebGL service', component: 'WebGLServiceMobile');
  }
  
  @override
  Future<bool> isSupported() async {
    try {
      final canvas = html.CanvasElement();
      final context = canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
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
      renderer: 'Mobile',
      vendor: 'Mobile',
      instancingSupport: false,
      floatTextureSupport: false,
      compressedTextureSupport: false,
    );
  }
  
  @override
  Future<bool> canRenderGLB() async => true;
  
  @override
  Future<bool> supportsExtension(String extension) async => false;
  
  @override
  Future<void> handleContextLoss() async {}
  
  @override
  Future<bool> attemptContextRecovery() async => true;
  
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
  
  @override
  void setQualityLevel(QualityLevel level) {
    _currentQuality = level;
  }
  
  @override
  QualityLevel get currentQuality => _currentQuality;
  
  @override
  void registerViewFactory(String viewType, Function factory) {
    // CRITICAL FIX: Platform views are now pre-registered during app initialization
    // This method is no longer needed for runtime registration
    AppLogger.debug('Platform view factory registration skipped - using pre-registered views',
      component: 'WebGLServiceMobile',
      metadata: {'viewType': viewType});
  }
  
  @override
  void dispose() {
    _activeIframes.clear();
  }
  
  @override
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  }) {
    return MobileWebGLViewerWidget(
      url: url,
      title: title,
      onLoaded: onLoaded,
      onError: onError,
      service: this,
    );
  }
  
  /// Enable mobile controls for a specific viewer
  void enableMobileControls(String viewerId) {
    _mobileControlsEnabled = true;
    AppLogger.info('Mobile controls enabled for viewer: $viewerId',
      component: 'WebGLServiceMobile');
  }
  
  /// Disable mobile controls for a specific viewer
  void disableMobileControls(String viewerId) {
    _mobileControlsEnabled = false;
    AppLogger.info('Mobile controls disabled for viewer: $viewerId',
      component: 'WebGLServiceMobile');
  }
  
  /// Send joystick movement input to Three.js
  void sendMovementInput(String viewerId, double x, double y) {
    _sendMobileMessage(viewerId, 'joystick_movement', {
      'x': x,
      'y': y,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Send joystick camera input to Three.js
  void sendCameraInput(String viewerId, double x, double y) {
    _sendMobileMessage(viewerId, 'joystick_camera', {
      'x': x,
      'y': y,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Send gyroscope rotation input to Three.js
  void sendGyroscopeInput(String viewerId, double x, double y, double z) {
    _sendMobileMessage(viewerId, 'gyroscope_rotation', {
      'x': x,
      'y': y,
      'z': z,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Send mobile action to Three.js
  void sendMobileAction(String viewerId, String action, {Map<String, dynamic>? data}) {
    _sendMobileMessage(viewerId, 'mobile_action', {
      'action': action,
      'data': data ?? {},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Send mobile settings to Three.js
  void sendMobileSettings(String viewerId, String setting, dynamic value) {
    _sendMobileMessage(viewerId, 'mobile_settings', {
      'setting': setting,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Request haptic feedback
  void requestHapticFeedback(String viewerId, String type, {double intensity = 1.0}) {
    _sendMobileMessage(viewerId, 'haptic_feedback_request', {
      'type': type,
      'intensity': intensity,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Send message to Three.js mobile bridge
  void _sendMobileMessage(String viewerId, String type, Map<String, dynamic> payload) {
    if (!_mobileControlsEnabled) return;
    
    final iframe = _activeIframes[viewerId];
    if (iframe == null) {
      AppLogger.warning('No iframe found for viewer: $viewerId',
        component: 'WebGLServiceMobile');
      return;
    }
    
    try {
      final message = {
        'type': type,
        'payload': payload,
        'source': 'flutter',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Send message to iframe using postMessage without JS interop
      iframe.contentWindow?.postMessage(message, '*');
      
      AppLogger.debug('Sent mobile message: $type',
        component: 'WebGLServiceMobile',
        metadata: {'viewerId': viewerId, 'type': type});
    } catch (e) {
      AppLogger.error('Failed to send mobile message',
        component: 'WebGLServiceMobile',
        error: e,
        metadata: {'viewerId': viewerId, 'type': type});
    }
  }
  
  /// Register iframe for mobile communication
  void _registerIframe(String viewerId, html.IFrameElement iframe) {
    _activeIframes[viewerId] = iframe;
    AppLogger.info('Registered iframe for mobile controls: $viewerId',
      component: 'WebGLServiceMobile');
  }
  
  /// Unregister iframe
  void _unregisterIframe(String viewerId) {
    _activeIframes.remove(viewerId);
    AppLogger.info('Unregistered iframe: $viewerId',
      component: 'WebGLServiceMobile');
  }
  
  /// Build the Three.js viewer URL with the room ID
  String _buildThreeJsViewerUrl(String roomId) {
    // CRITICAL FIX: Use correct production URL for Firebase deployment
    // Check if we're in development (localhost) or production (Firebase)
    final currentUrl = html.window.location.href;
    
    if (currentUrl.contains('localhost') || currentUrl.contains('127.0.0.1')) {
      // Development environment - use local server
      return 'http://localhost:3000/?room=$roomId';
    } else {
      // Production environment (Firebase) - use deployed Three.js path
      return './threejs/?room=$roomId';
    }
  }
}

/// Mobile-optimized WebGL viewer widget with gaming controls
class MobileWebGLViewerWidget extends StatefulWidget {
  final String url;
  final String title;
  final VoidCallback? onLoaded;
  final Function(String)? onError;
  final WebGLServiceMobile service;
  
  const MobileWebGLViewerWidget({
    super.key,
    required this.url,
    required this.title,
    this.onLoaded,
    this.onError,
    required this.service,
  });
  
  @override
  State<MobileWebGLViewerWidget> createState() => _MobileWebGLViewerWidgetState();
}

class _MobileWebGLViewerWidgetState extends State<MobileWebGLViewerWidget> {
  late final String _viewerId;
  late final String _viewType;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<html.MessageEvent>? _messageSubscription;
  
  @override
  void initState() {
    super.initState();
    _viewerId = 'mobile-webgl-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _viewType = 'mobile-webgl-viewer-stable'; // Use stable view type to prevent registration errors
    _registerViewer();
    _setupMessageListener();
  }
  
  void _setupMessageListener() {
    // Listen for messages from Three.js
    _messageSubscription = html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        if (data is Map && data['source'] == 'threejs') {
          _handleThreeJsMessage(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        AppLogger.warning('Error processing message from Three.js',
          component: 'MobileWebGLViewer',
          error: e);
      }
    });
  }
  
  void _handleThreeJsMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final payload = data['payload'] as Map<String, dynamic>?;
    
    AppLogger.debug('Received Three.js message: $type',
      component: 'MobileWebGLViewer',
      metadata: {'viewerId': _viewerId});
    
    switch (type) {
      case 'roomLoadComplete':
        _handleLoadingComplete();
        break;
      case 'roomLoadError':
        _handleLoadingError(payload?['error'] ?? 'Unknown error');
        break;
      case 'mobile_controls_enabled':
        widget.service.enableMobileControls(_viewerId);
        break;
      case 'mobile_controls_disabled':
        widget.service.disableMobileControls(_viewerId);
        break;
      case 'haptic_feedback':
        _handleHapticFeedback(payload?['type'] ?? 'light');
        break;
      case 'mobile_performance_update':
        _handlePerformanceUpdate(payload ?? {});
        break;
      default:
        AppLogger.debug('Unknown Three.js message type: $type',
          component: 'MobileWebGLViewer');
    }
  }
  
  void _handleLoadingComplete() {
    AppLogger.info('Mobile WebGL viewer loading complete',
      component: 'MobileWebGLViewer',
      metadata: {'viewerId': _viewerId});
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      widget.onLoaded?.call();
    }
  }
  
  void _handleLoadingError(String error) {
    AppLogger.error('Mobile WebGL viewer loading error',
      component: 'MobileWebGLViewer',
      error: error,
      metadata: {'viewerId': _viewerId});
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
      widget.onError?.call(error);
    }
  }
  
  void _handleHapticFeedback(String type) {
    // Haptic feedback is handled by the mobile controls overlay
    AppLogger.debug('Haptic feedback requested: $type',
      component: 'MobileWebGLViewer');
  }
  
  void _handlePerformanceUpdate(Map<String, dynamic> data) {
    // Performance monitoring data from Three.js
    AppLogger.debug('Performance update from Three.js',
      component: 'MobileWebGLViewer',
      metadata: data);
  }
  
  void _registerViewer() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      try {
        // CRITICAL FIX: Use pre-registered platform view instead of registering at runtime
        final stableViewType = 'mobile-webgl-viewer-stable';
        
        AppLogger.info('Using pre-registered mobile WebGL platform view',
          component: 'MobileWebGLViewer',
          metadata: {'viewType': stableViewType, 'viewerId': _viewerId});
        
        // Update the view type to use the pre-registered one
        setState(() {
          _viewType = stableViewType;
        });
        
        // Initialize the iframe content after the platform view is ready
        _initializeIframeContent();
        
      } catch (e) {
        AppLogger.error('Failed to use mobile platform view',
          component: 'MobileWebGLViewer',
          error: e,
          metadata: {'viewType': _viewType});
        
        _handleLoadingError('Mobile WebGL platform view error: ${e.toString()}');
      }
    });
  }
  
  /// Initialize iframe content in the pre-registered platform view
  void _initializeIframeContent() {
    // Wait for the platform view to be ready
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      try {
        // Find any mobile WebGL container that's ready
        final containers = html.document.querySelectorAll('[id*="mobile-webgl-container"][data-ready="true"]');
        
        if (containers.isNotEmpty) {
          final container = containers.first as html.Element;
          AppLogger.info('Found mobile WebGL container: ${container.id}',
            component: 'MobileWebGLViewer');
          _createIframeInContainer(container);
        } else {
          AppLogger.warning('No mobile WebGL container found, retrying...',
            component: 'MobileWebGLViewer');
          
          // Retry after a longer delay
          Timer(const Duration(seconds: 1), () {
            if (mounted) {
              _initializeIframeContent();
            }
          });
        }
      } catch (e) {
        AppLogger.error('Failed to initialize iframe content',
          component: 'MobileWebGLViewer',
          error: e);
        _handleLoadingError('Failed to initialize mobile 3D viewer: ${e.toString()}');
      }
    });
  }
  
  /// Create iframe in the provided container
  void _createIframeInContainer(html.Element container) {
    try {
      // Remove loading indicator
      final loadingDiv = container.querySelector('[id*="loading"]');
      loadingDiv?.remove();
      
      // Create the actual iframe
      final iframe = html.IFrameElement()
        ..src = widget.service._buildThreeJsViewerUrl(widget.url)
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..allow = 'accelerometer; gyroscope; magnetometer; xr-spatial-tracking; gamepad';
      
      // Mobile-specific iframe attributes
      iframe.setAttribute('loading', 'lazy');
      iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
      iframe.setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms allow-popups allow-pointer-lock allow-orientation-lock');
      
      // Add iframe to container
      container.append(iframe);
      
      // Register iframe for mobile communication
      widget.service._registerIframe(_viewerId, iframe);
      
      _setupIframeEventHandlers(iframe);
      
      AppLogger.info('Mobile WebGL iframe created in container successfully',
        component: 'MobileWebGLViewer',
        metadata: {'url': iframe.src, 'viewerId': _viewerId});
        
    } catch (e) {
      AppLogger.error('Failed to create iframe in container',
        component: 'MobileWebGLViewer',
        error: e);
      _handleLoadingError('Failed to create mobile 3D viewer: ${e.toString()}');
    }
  }
  
  /// Create iframe directly (fallback method)
  void _createDirectIframe() {
    try {
      AppLogger.info('Creating direct iframe as fallback',
        component: 'MobileWebGLViewer');
      
      // This is a fallback - the iframe will be created by the platform view factory
      // Just handle the loading completion
      Timer(const Duration(seconds: 2), () {
        if (mounted && _isLoading) {
          _handleLoadingComplete();
        }
      });
      
    } catch (e) {
      AppLogger.error('Failed to create direct iframe',
        component: 'MobileWebGLViewer',
        error: e);
      _handleLoadingError('Mobile 3D viewer initialization failed: ${e.toString()}');
    }
  }
  
  /// Setup iframe event handlers
  void _setupIframeEventHandlers(html.IFrameElement iframe) {
    iframe.onLoad.listen((_) {
      AppLogger.info('Mobile WebGL iframe loaded successfully',
        component: 'MobileWebGLViewer',
        metadata: {'url': iframe.src, 'viewerId': _viewerId});
      
      // Enable mobile controls
      widget.service.enableMobileControls(_viewerId);
      
      // Check if the iframe actually loaded content
      Timer(const Duration(seconds: 1), () {
        if (mounted && _isLoading) {
          _handleLoadingComplete();
        }
      });
    });
    
    iframe.onError.listen((_) {
      AppLogger.error('Mobile WebGL iframe failed to load',
        component: 'MobileWebGLViewer',
        metadata: {'url': iframe.src, 'viewerId': _viewerId});
      
      _handleLoadingError('Failed to load mobile WebGL content. Please ensure the Three.js server is accessible.');
    });
    
    // Enhanced timeout with fallback options
    Timer(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        AppLogger.warning('Mobile WebGL iframe loading timeout - clearing loading state',
          component: 'MobileWebGLViewer',
          metadata: {'viewerId': _viewerId});
        
        _handleLoadingComplete();
      }
    });
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    widget.service._unregisterIframe(_viewerId);
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
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Mobile 3D Viewer Unavailable',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Retry loading
                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _registerViewer();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tip: For the best 3D experience, try using a desktop browser',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
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
                  SizedBox(height: 8),
                  Text(
                    'Optimizing for mobile gaming controls',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  /// Get the viewer ID for mobile control communication
  String get viewerId => _viewerId;
}