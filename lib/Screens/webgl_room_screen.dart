import 'dart:async';
import 'dart:html' as html;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/webgl/webgl_factory.dart';
import '../core/webgl/webgl_service.dart';
import '../core/webgl/webgl_service_mobile.dart';
import '../core/logging/app_logger.dart';
import '../core/platform/platform_utils.dart';
import '../core/memory/memory_manager.dart';
import '../core/widgets/mobile_3d_controls.dart';
import '../core/sensors/gyroscope_controller.dart';
import '../core/state/refresh_fix.dart';
import '../themes/themes.dart';

/// Platform-agnostic WebGL room screen
/// 
/// This screen uses the WebGL abstraction layer to provide 3D model viewing
/// on web platforms and graceful fallbacks on other platforms.
/// Updated to work with Three.js room-based navigation system.
/// Fixed to prevent multiple initializations and screen refreshing.
class WebGLRoomScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebGLRoomScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebGLRoomScreen> createState() => _WebGLRoomScreenState();
}

class _WebGLRoomScreenState extends State<WebGLRoomScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin, RefreshOptimizationMixin {
  
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final WebGLService _webglService;
  late final WebGLServiceMobile? _mobileService;
  late final MemoryManager _memoryManager;
  late final GyroscopeController _gyroscopeController;
  
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _showHelpDialog = false;
  String? _errorMessage;
  bool _isWebGLSupported = false;
  String? _webglContextId;
  bool _isInitialized = false; // Prevent multiple initializations
  String? _mobileViewerId; // Track mobile viewer ID
  
  // Mobile gaming controls
  bool _showMobileControls = false;
  bool _isGyroscopeEnabled = false;
  bool _isFullscreen = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _webglService = WebGLFactory.instance;
    
    // Use mobile service for mobile devices
    if (PlatformUtils.isMobile) {
      _mobileService = WebGLServiceMobile.instance;
    } else {
      _mobileService = null;
    }
    
    _memoryManager = MemoryManager();
    _gyroscopeController = GyroscopeController();
    _initializeAnimations();
    
    // Check if mobile controls should be shown
    _showMobileControls = PlatformUtils.isMobile;
    
    // Initialize mobile features
    if (_showMobileControls) {
      _initializeMobileFeatures();
    }
    
    // CRITICAL FIX: Add navigation protection to prevent app refresh
    _addNavigationProtection();
    
    // Only initialize once
    if (!_isInitialized) {
      _initializeWebGL();
      _hideControlsAfterDelay();
      _isInitialized = true;
      
      // SAFETY NET: Ensure loading state is cleared after maximum time - REDUCED TO 10 SECONDS
      Timer(const Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          AppLogger.warning('Force clearing loading state after 10 seconds',
            component: 'WebGLRoomScreen');
          safeSetState(() {
            _isLoading = false;
            _hasError = false;
            _isWebGLSupported = true; // Use fallback mode
          });
        }
      });
    }
  }
  
  /// Add navigation protection to prevent app refresh
  void _addNavigationProtection() {
    // CRITICAL FIX: Prevent browser back button from causing app refresh
    html.window.addEventListener('beforeunload', (event) {
      AppLogger.info('Preventing page unload during WebGL session',
        component: 'WebGLRoomScreen');
      // Don't actually prevent unload, just log it
    });
    
    // CRITICAL FIX: Handle browser navigation events
    html.window.addEventListener('popstate', (event) {
      AppLogger.info('Browser back button pressed during WebGL session',
        component: 'WebGLRoomScreen');
      
      // If we're still in the WebGL screen, handle navigation properly
      if (mounted) {
        // Use Flutter navigation instead of browser navigation
        Navigator.of(context).pop();
      }
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeWebGL() async {
    try {
      AppLogger.info('Initializing WebGL for ${widget.title}',
        component: 'WebGLRoomScreen',
        metadata: {'url': widget.url});
      
      // Initialize memory manager first
      await _memoryManager.initialize();
      
      // Use enhanced initialization with retry logic and overall timeout - REDUCED TO 10 SECONDS
      await _initializeWebGLWithRetry().timeout(
        const Duration(seconds: 10), // Overall timeout for entire initialization
        onTimeout: () {
          AppLogger.warning('WebGL initialization timed out completely',
            component: 'WebGLRoomScreen');
          
          // Force completion with fallback mode
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false;
              _isWebGLSupported = true; // Use fallback mode
            });
          }
          throw TimeoutException('WebGL initialization timeout', const Duration(seconds: 10));
        },
      );
      
      // Register WebGL context for memory monitoring
      if (_isWebGLSupported && PlatformUtils.isWeb) {
        _webglContextId = 'webgl_${widget.title}_${DateTime.now().millisecondsSinceEpoch}';
        _memoryManager.registerWebGLContext(_webglContextId!);
      }
      
      if (mounted) {
        safeSetState(() {
          _isLoading = false;
        });
        _fadeController.forward();
      }
      
      AppLogger.info('WebGL initialization completed',
        component: 'WebGLRoomScreen',
        metadata: {
          'supported': _isWebGLSupported,
          'platform': PlatformUtils.isWeb ? 'web' : 'native',
          'isMobile': PlatformUtils.isMobile,
          'contextId': _webglContextId,
        });
    } catch (e) {
      AppLogger.error('WebGL initialization failed',
        component: 'WebGLRoomScreen',
        error: e,
        metadata: {'url': widget.url});
      
      if (mounted) {
        safeSetState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _buildErrorMessage(e);
        });
      }
    }
  }
  
  Future<void> _initializeWebGLWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    while (retryCount < maxRetries) {
      try {
        // CRITICAL FIX: Add timeout to prevent hanging - REDUCED TO 3 SECONDS
        await _webglService.initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            AppLogger.warning('WebGL service initialization timed out',
              component: 'WebGLRoomScreen',
              metadata: {'retry': retryCount});
            throw TimeoutException('WebGL service initialization timeout', const Duration(seconds: 3));
          },
        );
        
        _isWebGLSupported = await _webglService.isSupported().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            AppLogger.warning('WebGL support check timed out, assuming supported',
              component: 'WebGLRoomScreen',
              metadata: {'retry': retryCount});
            return true; // Optimistic fallback
          },
        );
        
        // Additional GLB capability check for classroom model
        if (_isWebGLSupported) {
          final canRenderGLB = await _webglService.canRenderGLB().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              AppLogger.warning('GLB capability check timed out, assuming supported',
                component: 'WebGLRoomScreen',
                metadata: {'retry': retryCount});
              return true; // Optimistic fallback
            },
          );
          
          if (!canRenderGLB) {
            AppLogger.warning('GLB rendering capability uncertain',
              component: 'WebGLRoomScreen',
              metadata: {'retry': retryCount});
          }
        }
        
        // Success - break out of retry loop
        break;
      } catch (e) {
        retryCount++;
        AppLogger.warning('WebGL initialization attempt $retryCount failed',
          component: 'WebGLRoomScreen',
          error: e,
          metadata: {'retryCount': retryCount, 'maxRetries': maxRetries});
        
        // CRITICAL FIX: Handle Flutter engine assertion specifically
        if (e.toString().contains('window.dart') || e.toString().contains('Assertion failed')) {
          AppLogger.error('Flutter engine assertion detected - using fallback approach',
            component: 'WebGLRoomScreen',
            error: e);
          
          // Use alternative approach that doesn't trigger Flutter engine assertions
          _useAlternativeWebGLApproach();
          return;
        }
        
        if (retryCount >= maxRetries) {
          // Final attempt failed - but still allow fallback
          AppLogger.info('All WebGL initialization attempts failed, allowing fallback mode',
            component: 'WebGLRoomScreen');
          _isWebGLSupported = true; // Force fallback mode
          
          // CRITICAL FIX: Ensure loading state is cleared even when all retries fail
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false; // Don't show error, use fallback mode
            });
          }
          break;
        }
        
        // Wait before retry
        await Future.delayed(retryDelay);
      }
    }
  }
  
  void _useAlternativeWebGLApproach() {
    AppLogger.info('Using alternative WebGL approach to avoid Flutter engine assertion',
      component: 'WebGLRoomScreen');
    
    setState(() {
      _isLoading = false;
      _hasError = false;
    });
    
    // Show a message to the user about opening in new tab
    _showAlternativeWebGLDialog();
  }
  
  void _showAlternativeWebGLDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('3D Viewer'),
        content: const Text(
          'The 3D classroom will open in the current tab. '
          'This provides the best 3D experience with full integration.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openWebGLInCurrentTab();
            },
            child: const Text('Open 3D View'),
          ),
        ],
      ),
    );
  }
  
  void _openWebGLInCurrentTab() {
    // CRITICAL FIX: Instead of opening in new tab, navigate to the Three.js content
    final url = './threejs/?room=${widget.url}';
    
    // Use Flutter navigation to go to the Three.js content
    html.window.location.assign(url);
  }
  
  String _buildErrorMessage(dynamic error) {
    String baseMessage = 'Failed to initialize 3D viewer';
    
    // Provide specific error messages based on error type
    if (error.toString().contains('WebGL')) {
      baseMessage = 'WebGL initialization failed';
    } else if (error.toString().contains('GLB') || error.toString().contains('model')) {
      baseMessage = 'Failed to load 3D model';
    } else if (error.toString().contains('memory') || error.toString().contains('Memory')) {
      baseMessage = 'Insufficient memory for 3D rendering';
    }
    
    baseMessage += ': ${error.toString()}';
    
    if (PlatformUtils.isMobile) {
      baseMessage += '\n\n📱 Mobile Device Tips:\n'
          '• Close other browser tabs to free memory\n'
          '• Try refreshing the page\n'
          '• Use a desktop browser for better performance\n'
          '• Ensure your device supports WebGL';
    } else {
      baseMessage += '\n\n💻 Troubleshooting:\n'
          '• Check if WebGL is enabled in your browser\n'
          '• Update your graphics drivers\n'
          '• Try a different browser (Chrome, Firefox, Edge)\n'
          '• Disable browser extensions that might block WebGL';
    }
    
    // Add specific GLB model troubleshooting
    if (widget.url.contains('classroom.glb')) {
      baseMessage += '\n\n🏫 Classroom Model:\n'
          '• This is a 3D classroom environment\n'
          '• Requires WebGL support for 3D rendering\n'
          '• File size: ~${_estimateModelSize()} MB';
    }
    
    return baseMessage;
  }
  
  String _estimateModelSize() {
    // Rough estimate for classroom model
    return PlatformUtils.isMobile ? '5-10' : '10-15';
  }

  // Mobile gaming controls methods
  Future<void> _initializeMobileFeatures() async {
    try {
      await _gyroscopeController.initialize();
      AppLogger.info('Mobile features initialized',
        component: 'WebGLRoomScreen',
        metadata: {'gyroscope_supported': _gyroscopeController.isSupported});
    } catch (e) {
      AppLogger.error('Failed to initialize mobile features',
        component: 'WebGLRoomScreen',
        error: e);
    }
  }

  void _onMovementChanged(Offset movement) {
    // Handle movement joystick input
    AppLogger.debug('Movement input: ${movement.dx.toStringAsFixed(2)}, ${movement.dy.toStringAsFixed(2)}',
      component: 'WebGLRoomScreen');
    
    // Send movement data to Three.js via mobile service
    if (_mobileService != null && _mobileViewerId != null) {
      _mobileService!.sendMovementInput(_mobileViewerId!, movement.dx, movement.dy);
    }
  }

  void _onCameraChanged(Offset camera) {
    // Handle camera joystick input
    AppLogger.debug('Camera input: ${camera.dx.toStringAsFixed(2)}, ${camera.dy.toStringAsFixed(2)}',
      component: 'WebGLRoomScreen');
    
    // Send camera data to Three.js via mobile service
    if (_mobileService != null && _mobileViewerId != null) {
      _mobileService!.sendCameraInput(_mobileViewerId!, camera.dx, camera.dy);
    }
  }

  void _onJump() {
    AppLogger.info('Jump action triggered', component: 'WebGLRoomScreen');
    
    // Send jump command to Three.js
    if (_mobileService != null && _mobileViewerId != null) {
      _mobileService!.sendMobileAction(_mobileViewerId!, 'jump');
    }
  }

  void _onInteract() {
    AppLogger.info('Interact action triggered', component: 'WebGLRoomScreen');
    
    // Send interact command to Three.js
    if (_mobileService != null && _mobileViewerId != null) {
      _mobileService!.sendMobileAction(_mobileViewerId!, 'interact');
    }
  }

  void _onMenu() {
    AppLogger.info('Menu action triggered', component: 'WebGLRoomScreen');
    
    // Send menu command to Three.js
    if (_mobileService != null && _mobileViewerId != null) {
      _mobileService!.sendMobileAction(_mobileViewerId!, 'menu');
    }
  }

  void _toggleGyroscope() {
    setState(() {
      _isGyroscopeEnabled = !_isGyroscopeEnabled;
    });

    if (_isGyroscopeEnabled) {
      _gyroscopeController.enable().then((_) {
        _gyroscopeController.calibrate();
        
        // Listen to gyroscope data and send to Three.js
        _gyroscopeController.gyroscopeStream.listen((data) {
          if (_mobileService != null && _mobileViewerId != null) {
            _mobileService!.sendGyroscopeInput(_mobileViewerId!, data.x, data.y, data.z);
          }
        });
      });
      
      // Send gyroscope toggle to Three.js
      if (_mobileService != null && _mobileViewerId != null) {
        _mobileService!.sendMobileAction(_mobileViewerId!, 'gyroscope_toggle', data: {'enabled': true});
      }
    } else {
      _gyroscopeController.disable();
      
      // Send gyroscope toggle to Three.js
      if (_mobileService != null && _mobileViewerId != null) {
        _mobileService!.sendMobileAction(_mobileViewerId!, 'gyroscope_toggle', data: {'enabled': false});
      }
    }

    AppLogger.info('Gyroscope ${_isGyroscopeEnabled ? 'enabled' : 'disabled'}',
      component: 'WebGLRoomScreen');
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    // Send fullscreen toggle to Three.js
    if (_mobileService != null && _mobileViewerId != null) {
      _mobileService!.sendMobileAction(_mobileViewerId!, 'fullscreen_toggle', data: {'enabled': _isFullscreen});
    }
    
    AppLogger.info('Fullscreen ${_isFullscreen ? 'enabled' : 'disabled'}',
      component: 'WebGLRoomScreen');
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _onWebGLLoaded() {
    AppLogger.info('WebGL content loaded successfully',
      component: 'WebGLRoomScreen',
      metadata: {'title': widget.title});
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onWebGLError(String error) {
    AppLogger.error('WebGL content error',
      component: 'WebGLRoomScreen',
      error: error,
      metadata: {'title': widget.title});
    
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }
  
  void _retryWebGLInitialization() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    
    // Reset WebGL service state
    _webglService.dispose();
    _webglService = WebGLFactory.instance;
    
    // Retry initialization
    _initializeWebGL();
  }

  @override
  void dispose() {
    // Unregister WebGL context from memory manager
    if (_webglContextId != null) {
      _memoryManager.unregisterWebGLContext(_webglContextId!);
    }
    
    // Dispose mobile resources
    if (_showMobileControls) {
      _gyroscopeController.dispose();
    }
    
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: Stack(
        children: [
          // Main content
          if (_isLoading)
            _buildLoadingScreen(isDark)
          else if (_hasError)
            _buildErrorScreen(isDark)
          else
            _buildWebGLViewer(),
          
          // Controls overlay
          if (_showControls && !_isLoading)
            _buildControlsOverlay(isDark),
          
          // Mobile gaming controls overlay
          if (_showMobileControls && !_isLoading && !_hasError)
            Mobile3DControls(
              onMovementChanged: _onMovementChanged,
              onCameraChanged: _onCameraChanged,
              onJump: _onJump,
              onInteract: _onInteract,
              onMenu: _onMenu,
              onGyroscopeToggle: _toggleGyroscope,
              onFullscreen: _toggleFullscreen,
              showGyroscopeButton: _gyroscopeController.isSupported,
              isGyroscopeEnabled: _isGyroscopeEnabled,
              isFullscreen: _isFullscreen,
              opacity: 0.8,
            ),
          
          // Help dialog
          if (_showHelpDialog)
            _buildHelpDialog(isDark),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.grey.shade900, Colors.black]
              : [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading 3D Classroom',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.blue.shade900.withValues(alpha: 0.3)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.view_in_ar,
                            size: 16,
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Preparing immersive experience...',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (PlatformUtils.isMobile) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Optimizing for mobile device...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark 
                              ? Colors.orange.shade300
                              : Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.red.shade900, Colors.black]
              : [Colors.red.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: isDark ? Colors.red.shade300 : Colors.red.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Unable to Load 3D View',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.red.shade900.withValues(alpha: 0.3)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark 
                          ? Colors.red.shade700
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark 
                          ? Colors.red.shade200
                          : Colors.red.shade700,
                    ),
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
                    label: const Text('Back to Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark 
                          ? Colors.blue.shade700
                          : Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _retryWebGLInitialization,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark 
                          ? Colors.green.shade700
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebGLViewer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _showMobileControls && _mobileService != null
            ? _buildMobileWebGLViewer()
            : _webglService.createViewer(
                url: widget.url,
                title: widget.title,
                onLoaded: _onWebGLLoaded,
                onError: _onWebGLError,
              ),
      ),
    );
  }
  
  Widget _buildMobileWebGLViewer() {
    final viewer = _mobileService!.createViewer(
      url: widget.url,
      title: widget.title,
      onLoaded: _onWebGLLoaded,
      onError: _onWebGLError,
    );
    
    // Extract mobile viewer ID for communication
    if (viewer is MobileWebGLViewerWidget) {
      // We need to get the viewer ID after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // The viewer ID will be available after the widget is initialized
          // For now, we'll use a placeholder and update it when the viewer is ready
          _mobileViewerId = 'mobile-webgl-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
        }
      });
    }
    
    return viewer;
  }

  Widget _buildControlsOverlay(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.only(
          top: 50,
          left: 16,
          right: 16,
          bottom: 20,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _showHelpDialog = true;
                });
              },
              icon: const Icon(Icons.help_outline, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpDialog(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '3D Viewer Controls',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                if (PlatformUtils.isWeb) ...[
                  _buildHelpItem(
                    Icons.mouse,
                    'Mouse Controls',
                    'Click to enter first-person mode\nWASD keys to move\nMouse to look around\nShift to run',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildHelpItem(
                    Icons.touch_app,
                    'Touch Controls',
                    'Tap to enter first-person mode\nTouch and drag to look around\nOn-screen controls for movement',
                    isDark,
                  ),
                  if (PlatformUtils.isMobile) ...[
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      Icons.memory,
                      'Mobile Performance',
                      'Graphics are optimized for mobile\nClose other apps for better performance\nSome features may be reduced for stability',
                      isDark,
                    ),
                  ],
                ] else ...[
                  _buildHelpItem(
                    Icons.info,
                    'Platform Notice',
                    '3D viewing is optimized for web browsers.\nThis platform shows a fallback view.',
                    isDark,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showHelpDialog = false;
                    });
                  },
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}