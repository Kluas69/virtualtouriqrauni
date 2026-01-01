// lib/Screens/webgl_room_screen.dart - UPDATED FOR THREE.JS
import 'dart:html' as html;
import 'dart:ui' as ui_blur;
import 'dart:ui_web' as ui;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as ui_blur;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/themes/themes.dart';

class WebGlRoomScreen extends StatefulWidget {
  final String url; // This will now be the GLB model URL
  final String title;

  const WebGlRoomScreen({super.key, required this.url, required this.title});

  @override
  State<WebGlRoomScreen> createState() => _WebGlRoomScreenState();
}

class _WebGlRoomScreenState extends State<WebGlRoomScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static final Set<String> _registeredViewTypes = {};
  late final String _viewType;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final html.IFrameElement _iframe;

  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _showHelpDialog = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _viewType =
        'threejs-viewer-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _initializeAnimations();
    _registerThreeJsViewer();
    _hideControlsAfterDelay();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  // ========================================
  // STEP A: Register Three.js Viewer
  // ========================================
  void _registerThreeJsViewer() {
    if (!mounted) return;

    try {
      if (!_registeredViewTypes.contains(_viewType)) {
        ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
          // Create iframe that loads our Three.js HTML
          final iframe =
              html.IFrameElement()
                // Point to our Three.js viewer with model URL as parameter
                ..src =
                    'three_viewer.html?model=${Uri.encodeComponent(widget.url)}'
                ..style.border = '0'
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.display = 'block'
                ..allowFullscreen = true
                ..setAttribute('loading', 'eager');

          bool hasLoaded = false;
          bool hasTimedOut = false;

          // Listen for messages from Three.js viewer
          html.window.onMessage.listen((event) {
            if (event.data is Map) {
              final data = event.data as Map;

              if (data['type'] == 'loaded' && mounted) {
                hasLoaded = true;
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
              } else if (data['type'] == 'error' && mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = data['message'] ?? 'Failed to load model';
                });
              }
            }
          });

          // Success handler
          iframe.onLoad.listen((_) {
            if (!hasTimedOut && mounted && !hasLoaded) {
              // Give Three.js time to initialize
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && !hasLoaded) {
                  setState(() {
                    _isLoading = false;
                    _hasError = false;
                  });
                }
              });
            }
          });

          // Error handler
          iframe.onError.listen((event) {
            if (!hasTimedOut && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = 'Failed to load 3D viewer';
              });
            }
          });

          // Timeout
          Future.delayed(const Duration(seconds: 30), () {
            if (!hasLoaded && mounted) {
              hasTimedOut = true;
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = 'Loading timeout. Please try again.';
              });
            }
          });

          return iframe;
        });

        _registeredViewTypes.add(_viewType);
      }
    } catch (e) {
      debugPrint('Error registering Three.js viewer: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize 3D viewer: $e';
        });
      }
    }
  }

  void _hideControlsAfterDelay() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
        _fadeController.forward();
      }
    });
  }

  void _toggleControls() {
    if (!mounted) return;
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _fadeController.reverse();
        _hideControlsAfterDelay();
      } else {
        _fadeController.forward();
      }
    });
  }

  void _resetCamera() {
    // Send message to Three.js viewer
    _sendMessageToViewer({'type': 'reset'});
    _showSnackBar('Camera position reset');
  }

  void _sendMessageToViewer(Map<String, dynamic> message) {
    // Find iframe and send message
    final iframes = html.document.querySelectorAll('iframe');
    for (var iframe in iframes) {
      if (iframe is html.IFrameElement) {
        iframe.contentWindow?.postMessage(message, '*');
      }
    }
  }

  void _refresh() {
    if (!mounted) return;

    _registeredViewTypes.remove(_viewType);

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _registerThreeJsViewer();
        _showSnackBar('Refreshing 3D model...');
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Three.js Viewer
          if (!_hasError)
            GestureDetector(
              onTap: _toggleControls,
              child: HtmlElementView(viewType: _viewType),
            ),

          // Error State
          if (_hasError) _buildErrorState(theme),

          // Loading State
          if (_isLoading && !_hasError) _buildLoadingState(theme),

          // Fade overlay when controls are hidden
          if (!_showControls && !_isLoading && !_hasError)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),

          // Top Controls
          if (_showControls && !_isLoading && !_hasError)
            _buildTopControls(isDark, theme, themeProvider),

          // Bottom Controls
          if (_showControls && !_isLoading && !_hasError)
            _buildBottomControls(isDark, theme),

          // Controls Hint
          if (!_showControls && !_isLoading && !_hasError) _buildControlsHint(),

          // Help Dialog
          if (_showHelpDialog) _buildHelpDialog(theme),
        ],
      ),
    );
  }

  // ========================================
  // UI Components (same as before)
  // ========================================

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      color: Colors.black,
      child: Center(
        child: FadeIn(
          duration: const Duration(milliseconds: 600),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Failed to Load Model',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Unable to load the 3D model.',
                  style: GoogleFonts.roboto(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Try Again',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      color: Colors.black,
      child: Center(
        child: FadeIn(
          duration: const Duration(milliseconds: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.primaryColor,
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Loading 3D Model...',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Preparing Three.js viewer',
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(
    bool isDark,
    ThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return SafeArea(
      child: FadeInDown(
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ui_blur.BackdropFilter(
              filter: ui_blur.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _buildControlButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.view_in_ar,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'THREE.JS 3D',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      icon: isDark ? Icons.light_mode : Icons.dark_mode,
                      tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                      onPressed: () => themeProvider.toggleTheme(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isDark, ThemeData theme) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: ui_blur.BackdropFilter(
                filter: ui_blur.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildControlButton(
                        icon: Icons.refresh,
                        tooltip: 'Refresh',
                        onPressed: _refresh,
                      ),
                      const SizedBox(width: 16),
                      _buildControlButton(
                        icon: Icons.replay,
                        tooltip: 'Reset Camera',
                        onPressed: _resetCamera,
                      ),
                      const SizedBox(width: 16),
                      _buildControlButton(
                        icon: Icons.help_outline,
                        tooltip: 'Controls Help',
                        onPressed: () => setState(() => _showHelpDialog = true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsHint() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: FadeIn(
        delay: const Duration(seconds: 2),
        duration: const Duration(milliseconds: 800),
        child: FadeOut(
          delay: const Duration(seconds: 5),
          duration: const Duration(milliseconds: 800),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Click to lock pointer • WASD to move',
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpDialog(ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _showHelpDialog = false),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: FadeIn(
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark
                          ? Colors.grey.shade900
                          : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gamepad, size: 56, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Controls',
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildHelpItem(
                      Icons.mouse,
                      'Click anywhere',
                      'Lock mouse pointer',
                    ),
                    _buildHelpItem(Icons.keyboard, 'W A S D', 'Move around'),
                    _buildHelpItem(
                      Icons.directions_run,
                      'Hold Shift',
                      'Run faster',
                    ),
                    _buildHelpItem(
                      Icons.control_camera,
                      'Mouse',
                      'Look around',
                    ),
                    _buildHelpItem(Icons.exit_to_app, 'ESC', 'Unlock pointer'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() => _showHelpDialog = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Got It!',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isEnabled = true,
  }) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  isEnabled
                      ? theme.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: isEnabled ? onPressed : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? theme.primaryColor : Colors.grey.shade600,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
