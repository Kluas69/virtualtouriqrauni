import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/webgl/webgl_factory.dart';
import '../core/webgl/webgl_service.dart';
import '../core/webgl/webgl_service_web.dart';
import '../core/logging/app_logger.dart';
import '../core/platform/platform_utils.dart';
import '../core/memory/memory_manager.dart';
import '../themes/themes.dart';

/// Platform-agnostic WebGL room screen
/// 
/// This screen uses the WebGL abstraction layer to provide 3D model viewing
/// on web platforms and graceful fallbacks on other platforms.
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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final WebGLService _webglService;
  late final MemoryManager _memoryManager;
  
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _showHelpDialog = false;
  String? _errorMessage;
  bool _isWebGLSupported = false;
  String? _webglContextId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _webglService = WebGLFactory.instance;
    _memoryManager = MemoryManager();
    _initializeAnimations();
    _initializeWebGL();
    _hideControlsAfterDelay();
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
      
      // Use enhanced initialization with retry logic
      await _initializeWebGLWithRetry();
      
      // Register WebGL context for memory monitoring
      if (_isWebGLSupported && PlatformUtils.isWeb) {
        _webglContextId = 'webgl_${widget.title}_${DateTime.now().millisecondsSinceEpoch}';
        _memoryManager.registerWebGLContext(_webglContextId!);
      }
      
      if (mounted) {
        setState(() {
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
        setState(() {
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
        await _webglService.initialize();
        _isWebGLSupported = await _webglService.isSupported();
        
        // Additional GLB capability check for classroom model
        if (_isWebGLSupported && _webglService is WebGLServiceWeb) {
          final canRenderGLB = await _webglService.canRenderGLB();
          
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
        
        if (retryCount >= maxRetries) {
          // Final attempt failed - but still allow fallback
          AppLogger.info('All WebGL initialization attempts failed, allowing fallback mode',
            component: 'WebGLRoomScreen');
          _isWebGLSupported = true; // Force fallback mode
          break;
        }
        
        // Wait before retry
        await Future.delayed(retryDelay);
      }
    }
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
                      'Loading 3D Environment',
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
                    if (PlatformUtils.isMobile) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Optimizing for mobile device...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark 
                              ? Colors.blue.shade300
                              : Colors.blue.shade600,
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
        child: _webglService.createViewer(
          url: widget.url,
          title: widget.title,
          onLoaded: _onWebGLLoaded,
          onError: _onWebGLError,
        ),
      ),
    );
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