import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/webgl/webgl_service_unified.dart';
import '../core/logging/app_logger.dart';
import '../core/platform/platform_utils.dart';
import '../core/mobile/mobile_game_controller.dart';
import '../core/models/spawn_config.dart';

/// Simplified WebGL Room Screen that properly loads professional_classroom_enhanced.html
class WebGLRoomScreen extends StatefulWidget {
  final String url;
  final String title;
  final SpawnConfig? spawnConfig;

  const WebGLRoomScreen({
    super.key,
    required this.url,
    required this.title,
    this.spawnConfig,
  });

  @override
  State<WebGLRoomScreen> createState() => _WebGLRoomScreenState();
}

class _WebGLRoomScreenState extends State<WebGLRoomScreen> {
  static const String _logComponent = 'WebGLRoomScreen';
  
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late WebGLServiceUnified _webglService;
  html.IFrameElement? _iframe;
  final MobileGameController _gameController = MobileGameController.instance;
  
  @override
  void initState() {
    super.initState();
    _initializeWebGL();
    _setupMessageListener();
  }

  void _setupMessageListener() {
    // Listen for messages from the HTML iframe
    html.window.addEventListener('message', (html.Event event) {
      final html.MessageEvent messageEvent = event as html.MessageEvent;
      final data = messageEvent.data;
      
      if (data is Map && data['type'] == 'game_exit' && data['action'] == 'back_pressed') {
        AppLogger.info('Received exit game message from HTML', component: _logComponent);
        _handleGameExit();
      }
    });
  }

  Future<void> _handleGameExit() async {
    try {
      AppLogger.info('Handling game exit request', component: _logComponent);
      
      // Restore normal orientation when leaving the game
      if (_isMobileDevice()) {
        await _gameController.disableLandscapeMode();
      }
      
      // Navigate back to previous screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('Error handling game exit: $e', component: _logComponent);
      // Force navigation even if there's an error
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupMobileGaming();
  }

  void _setupMobileGaming() async {
    // Check if this is a mobile device
    if (_isMobileDevice()) {
      AppLogger.info('Setting up mobile gaming mode', component: _logComponent);
      
      // Enable landscape mode for mobile gaming
      await _gameController.enableLandscapeMode();
    }
  }

  bool _isMobileDevice() {
    // Safe MediaQuery access - only call after dependencies are established
    if (!mounted) return false;
    final screenSize = MediaQuery.of(context).size;
    return screenSize.width < 1024;
  }

  void _initializeWebGL() {
    try {
      _webglService = WebGLServiceUnified();
      AppLogger.info('WebGL service initialized', component: _logComponent);
      
      // Initialize the service
      _webglService.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }).catchError((error) {
        AppLogger.error('WebGL initialization failed: $error', component: _logComponent);
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Failed to initialize 3D viewer: $error';
          });
        }
      });
    } catch (e) {
      AppLogger.error('WebGL service creation failed: $e', component: _logComponent);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to create 3D viewer service: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use simplified UI for all devices - HTML handles mobile controls natively
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Clean up when back navigation happens
          if (_isMobileDevice()) {
            _gameController.disableLandscapeMode();
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: null, // Remove title header completely
        body: _buildGameContent(isDark),
      ),
    );
  }

  Widget _buildGameContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingView(isDark);
    }
    
    if (_hasError) {
      return _buildErrorView(isDark);
    }
    
    return _build3DViewer(isDark);
  }

  Widget _buildLoadingView(bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1024;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    const Color(0xFFF8F9FA),
                    const Color(0xFFE3F2FD),
                    const Color(0xFFBBDEFB),
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background effects
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GameLoadingBackgroundPainter(isDark: isDark),
                    ),
                  ),
                  
                  // Top section - Logo and title (30% of screen)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: constraints.maxHeight * 0.3,
                    child: _buildTopSection(isDark, isSmallScreen, isMediumScreen),
                  ),
                  
                  // Middle section - Progress and status (40% of screen)
                  Positioned(
                    top: constraints.maxHeight * 0.3,
                    left: 0,
                    right: 0,
                    height: constraints.maxHeight * 0.4,
                    child: _buildMiddleSection(isDark, isSmallScreen, isMediumScreen, constraints.maxWidth),
                  ),
                  
                  // Bottom section - Tips and info (30% of screen)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: constraints.maxHeight * 0.3,
                    child: _buildBottomSection(isDark, isSmallScreen, isMediumScreen),
                  ),
                  
                  // Exit button (top right)
                  if (!_isMobileDevice())
                    Positioned(
                      top: 20,
                      right: 20,
                      child: _buildExitButton(isDark),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(bool isDark, bool isSmallScreen, bool isMediumScreen) {
    final logoSize = isSmallScreen ? 80.0 : isMediumScreen ? 100.0 : 120.0;
    final titleSize = isSmallScreen ? 24.0 : isMediumScreen ? 28.0 : 32.0;
    final subtitleSize = isSmallScreen ? 14.0 : isMediumScreen ? 16.0 : 18.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 40,
        vertical: 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Game logo with glow effect
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4285F4),
                  const Color(0xFF1976D2),
                  const Color(0xFF0D47A1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.view_in_ar_rounded,
              size: logoSize * 0.5,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 20 : 24),
          
          // Game title with shader effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isDark
                  ? [Colors.white, const Color(0xFF4285F4)]
                  : [const Color(0xFF1976D2), const Color(0xFF0D47A1)],
            ).createShader(bounds),
            child: Text(
              'IQRA UNIVERSITY',
              style: GoogleFonts.orbitron(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          // Subtitle
          Text(
            '3D Campus Experience',
            style: GoogleFonts.roboto(
              fontSize: subtitleSize,
              fontWeight: FontWeight.w500,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.7),
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleSection(bool isDark, bool isSmallScreen, bool isMediumScreen, double screenWidth) {
    final progressWidth = isSmallScreen ? screenWidth * 0.8 : isMediumScreen ? 400.0 : 500.0;
    final statusSize = isSmallScreen ? 16.0 : isMediumScreen ? 18.0 : 20.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 40,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading status text
          Text(
            'Initializing 3D Environment...',
            style: GoogleFonts.roboto(
              fontSize: statusSize,
              fontWeight: FontWeight.w600,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isSmallScreen ? 30 : 40),
          
          // Progress bar container
          Container(
            width: progressWidth,
            child: Column(
              children: [
                // Linear progress bar
                Container(
                  width: progressWidth,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF4285F4),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 20 : 24),
                
                // Circular progress indicator
                SizedBox(
                  width: isSmallScreen ? 32 : 40,
                  height: isSmallScreen ? 32 : 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF4285F4),
                    ),
                    backgroundColor: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 20 : 30),
          
          // Loading details
          Text(
            'Loading WebGL renderer and ${widget.title}',
            style: GoogleFonts.roboto(
              fontSize: isSmallScreen ? 12.0 : 14.0,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isDark, bool isSmallScreen, bool isMediumScreen) {
    final tipSize = isSmallScreen ? 12.0 : 13.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 40,
        vertical: 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tips container
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : 600,
            ),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                // Tips header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: tipSize + 4,
                      color: const Color(0xFF4285F4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pro Tips',
                      style: GoogleFonts.roboto(
                        fontSize: tipSize + 2,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4285F4),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Tips list
                ...(_getGameTips(isSmallScreen).map((tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4285F4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: GoogleFonts.roboto(
                            fontSize: tipSize,
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))).toList(),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Bottom info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'v1.0.0',
                style: GoogleFonts.roboto(
                  fontSize: tipSize - 1,
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.3),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Powered by ',
                    style: GoogleFonts.roboto(
                      fontSize: tipSize - 1,
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    'Three.js',
                    style: GoogleFonts.roboto(
                      fontSize: tipSize - 1,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExitButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.close_rounded,
          color: isDark ? Colors.white : Colors.black,
        ),
        tooltip: 'Exit',
      ),
    );
  }

  List<String> _getGameTips(bool isSmallScreen) {
    final allTips = [
      'Use WASD keys to move around the campus',
      'Mouse to look around and interact with objects',
      'Press F for fullscreen immersive mode',
      'Click on objects to get detailed information',
      'Explore every corner to discover hidden features',
    ];
    
    return isSmallScreen ? allTips.take(3).toList() : allTips;
  }

  Widget _buildErrorView(bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1024;
    
    // Responsive sizing
    final iconSize = isSmallScreen ? 64.0 : isMediumScreen ? 80.0 : 96.0;
    final titleFontSize = isSmallScreen ? 20.0 : isMediumScreen ? 24.0 : 28.0;
    final bodyFontSize = isSmallScreen ? 14.0 : isMediumScreen ? 16.0 : 18.0;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF2E1A1A),
                  const Color(0xFF3E1616),
                ]
              : [
                  const Color(0xFFFFF8F8),
                  const Color(0xFFFFEBEE),
                  const Color(0xFFFFCDD2),
                ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            width: isSmallScreen ? screenSize.width * 0.9 : 600,
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.9,
              maxHeight: screenSize.height * 0.8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon with animation
                Container(
                  width: iconSize + 20,
                  height: iconSize + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark 
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: iconSize,
                    color: Colors.red.shade400,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Error title
                Text(
                  'Connection Failed',
                  style: GoogleFonts.orbitron(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Error description
                Text(
                  'Unable to initialize the 3D environment.\nPlease check your connection and try again.',
                  style: GoogleFonts.roboto(
                    fontSize: bodyFontSize - 2,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (_errorMessage != null) ...[
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(buttonPadding),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: bodyFontSize,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Technical Details',
                              style: GoogleFonts.roboto(
                                fontSize: bodyFontSize - 2,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.robotoMono(
                            fontSize: bodyFontSize - 4,
                            color: isDark 
                                ? Colors.red.shade200
                                : Colors.red.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: isSmallScreen ? 32 : 40),
                
                // Action buttons
                if (isSmallScreen)
                  Column(
                    children: [
                      _buildErrorButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retry Connection',
                        color: Colors.blue,
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasError = false;
                            _errorMessage = null;
                          });
                          _initializeWebGL();
                        },
                        isFullWidth: true,
                        padding: buttonPadding,
                        fontSize: bodyFontSize,
                      ),
                      const SizedBox(height: 12),
                      _buildErrorButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back to Gallery',
                        color: Colors.grey,
                        onPressed: () => Navigator.of(context).pop(),
                        isFullWidth: true,
                        padding: buttonPadding,
                        fontSize: bodyFontSize,
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildErrorButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retry Connection',
                        color: Colors.blue,
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _hasError = false;
                            _errorMessage = null;
                          });
                          _initializeWebGL();
                        },
                        isFullWidth: false,
                        padding: buttonPadding,
                        fontSize: bodyFontSize,
                      ),
                      const SizedBox(width: 16),
                      _buildErrorButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back to Gallery',
                        color: Colors.grey,
                        onPressed: () => Navigator.of(context).pop(),
                        isFullWidth: false,
                        padding: buttonPadding,
                        fontSize: bodyFontSize,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorButton({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onPressed,
    required bool isFullWidth,
    required double padding,
    required double fontSize,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: fontSize + 2),
        label: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: fontSize - 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color[600],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: padding + 8,
            vertical: padding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _build3DViewer(bool isDark) {
    // Determine the correct URL for the 3D viewer
    String viewerUrl;
    if (widget.url == 'classroom' || widget.url.contains('classroom')) {
      viewerUrl = '/threejs/professional_classroom_enhanced.html';
    } else if (widget.url.startsWith('http')) {
      viewerUrl = widget.url;
    } else {
      viewerUrl = '/threejs/${widget.url}';
    }

    AppLogger.info('Loading 3D viewer with URL: $viewerUrl', component: _logComponent);

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: PlatformUtils.isWeb 
          ? _buildWebViewer(viewerUrl)
          : _buildFallbackViewer(isDark),
    );
  }

  Widget _buildWebViewer(String url) {
    // Create a unique view type for each instance to avoid conflicts
    final viewType = 'webgl-3d-viewer-${DateTime.now().millisecondsSinceEpoch}';
    
    // Register the view factory immediately
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        _iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allowfullscreen', 'true')
          ..setAttribute('webkitallowfullscreen', 'true')
          ..setAttribute('mozallowfullscreen', 'true')
          ..setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture');

        // Add load event listener
        _iframe!.onLoad.listen((_) {
          AppLogger.info('3D viewer iframe loaded successfully', component: _logComponent);
          // Send spawn configuration to WebGL engine
          _sendSpawnConfigToWebGL();
        });

        _iframe!.onError.listen((event) {
          AppLogger.error('3D viewer iframe failed to load: $event', component: _logComponent);
        });

        return _iframe!;
      },
    );

    // Return the HtmlElementView with the registered view type
    return HtmlElementView(
      viewType: viewType,
    );
  }

  /// SPAWN SYSTEM: Send spawn configuration to WebGL engine via postMessage
  void _sendSpawnConfigToWebGL() {
    if (widget.spawnConfig == null) {
      AppLogger.info('No spawn config to send', component: _logComponent);
      return;
    }

    try {
      final spawnData = {
        'type': 'SPAWN_CONFIG',
        'data': widget.spawnConfig!.toJson(),
      };

      final message = jsonEncode(spawnData);
      
      // Send message to iframe
      _iframe?.contentWindow?.postMessage(message, '*');
      
      AppLogger.info('Spawn config sent to WebGL',
        component: _logComponent,
        metadata: {
          'location': widget.spawnConfig!.locationName,
          'position': widget.spawnConfig!.position.toString(),
          'rotation': widget.spawnConfig!.rotation.toString(),
        });
    } catch (e) {
      AppLogger.error('Error sending spawn config to WebGL',
        component: _logComponent,
        error: e);
    }
  }

  Widget _buildFallbackViewer(bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1024;
    
    // Responsive sizing
    final iconSize = isSmallScreen ? 80.0 : isMediumScreen ? 100.0 : 120.0;
    final titleFontSize = isSmallScreen ? 24.0 : isMediumScreen ? 28.0 : 32.0;
    final bodyFontSize = isSmallScreen ? 14.0 : isMediumScreen ? 16.0 : 18.0;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ]
              : [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFE3F2FD),
                  const Color(0xFFBBDEFB),
                ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            width: isSmallScreen ? screenSize.width * 0.9 : 600,
            constraints: BoxConstraints(
              maxWidth: screenSize.width * 0.9,
              maxHeight: screenSize.height * 0.8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D icon with gradient
                Container(
                  width: iconSize + 20,
                  height: iconSize + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4285F4),
                        const Color(0xFF1976D2),
                        const Color(0xFF0D47A1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4285F4).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.view_in_ar_rounded,
                    size: iconSize * 0.6,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 40),
                
                // Title
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      const Color(0xFF4285F4),
                      const Color(0xFF1976D2),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    '3D Viewer',
                    style: GoogleFonts.orbitron(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Description
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: bodyFontSize + 4,
                        color: const Color(0xFF4285F4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Platform Information',
                        style: GoogleFonts.roboto(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4285F4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This platform shows a fallback view.\n3D viewing is optimized for web browsers with WebGL support.',
                        style: GoogleFonts.roboto(
                          fontSize: bodyFontSize - 2,
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 32 : 40),
                
                // Action button
                SizedBox(
                  width: isSmallScreen ? double.infinity : null,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: bodyFontSize + 2,
                    ),
                    label: Text(
                      'Back to Gallery',
                      style: GoogleFonts.roboto(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonPadding + 8,
                        vertical: buttonPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      // Restore normal orientation when leaving the game
      if (mounted && _isMobileDevice()) {
        _gameController.disableLandscapeMode();
      }
      
      // Clean up resources
      AppLogger.info('Disposing WebGL room screen', component: _logComponent);
    } catch (e) {
      AppLogger.warning('Error during disposal: $e', component: _logComponent);
    }
    super.dispose();
  }
}

/// Custom painter for animated background effects in the loading screen
class _GameLoadingBackgroundPainter extends CustomPainter {
  final bool isDark;
  
  _GameLoadingBackgroundPainter({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Create floating particles
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final opacity = random.nextDouble() * 0.3 + 0.1;
      
      paint.color = isDark 
          ? Colors.white.withValues(alpha: opacity)
          : Colors.black.withValues(alpha: opacity);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Create subtle grid pattern
    paint.color = isDark 
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.black.withValues(alpha: 0.02);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    
    const gridSize = 50.0;
    
    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}