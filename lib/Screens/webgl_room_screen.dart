import 'dart:html' as html;
import 'dart:ui' as ui_blur;
import 'dart:ui_web' as ui;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as ui_blur;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/themes/Themes.dart';

class WebGlRoomScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebGlRoomScreen({super.key, required this.url, required this.title});

  @override
  State<WebGlRoomScreen> createState() => _WebGlRoomScreenState();
}

class _WebGlRoomScreenState extends State<WebGlRoomScreen>
    with SingleTickerProviderStateMixin {
  static final Set<String> _registeredViewTypes = {};
  late final String _viewType;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _isFullScreen = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _viewType = 'webgl-iframe-${widget.url.hashCode}';

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _registerIframe();
    _hideControlsAfterDelay();
  }

  void _registerIframe() {
    try {
      // Check if view factory is already registered to prevent duplicate registration
      if (!_registeredViewTypes.contains(_viewType)) {
        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
          final iframe =
              html.IFrameElement()
                ..src = widget.url
                ..style.border = '0'
                ..style.width = '100%'
                ..style.height = '100%'
                ..allowFullscreen = true
                ..allow =
                    'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';

          // Listen for load events
          iframe.onLoad.listen((_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          });

          iframe.onError.listen((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          });

          return iframe;
        });

        // Mark this view type as registered
        _registeredViewTypes.add(_viewType);
      }

      // Simulate loading complete after a short delay if already registered
      if (_registeredViewTypes.contains(_viewType)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showControls && !_isFullScreen) {
        setState(() => _showControls = false);
        _fadeController.forward();
      }
    });
  }

  void _toggleControls() {
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

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = true;
      _fadeController.reverse();
    });
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    // Re-register the iframe to force reload
    _registerIframe();
    _showSnackBar('Refreshing...');
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebGL Iframe Content
          if (!_hasError)
            GestureDetector(
              onTap: _toggleControls,
              child: HtmlElementView(viewType: _viewType),
            ),

          // Error State
          if (_hasError)
            Container(
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
                          'Failed to Load Tour',
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
                          'Unable to load the 3D tour. Please check your connection and try again.',
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
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Loading Overlay
          if (_isLoading && !_hasError)
            Container(
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
                        'Loading 3D Tour...',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please wait while we prepare your virtual experience',
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
            ),

          // Fade overlay when controls are hidden
          if (!_showControls && !_isLoading && !_hasError)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),

          // Top Bar Controls with glassmorphism
          if (_showControls && !_isLoading && !_hasError)
            SafeArea(
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
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black.withOpacity(0.5),
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.view_in_ar,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '3D TOUR',
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
            ),

          // Bottom Controls with glassmorphism
          if (_showControls && !_isLoading && !_hasError)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: ui_blur.BackdropFilter(
                        filter: ui_blur.ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ),
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
                                icon:
                                    _isFullScreen
                                        ? Icons.fullscreen_exit
                                        : Icons.fullscreen,
                                tooltip: 'Toggle Fullscreen',
                                onPressed: _toggleFullScreen,
                              ),
                              const SizedBox(width: 16),
                              _buildControlButton(
                                icon: Icons.info_outline,
                                tooltip: 'Tour Info',
                                onPressed:
                                    () => _showSnackBar(
                                      'Navigate using mouse/touch controls',
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Tap to toggle controls hint (shows briefly)
          if (!_showControls && !_isLoading && !_hasError)
            Positioned(
              bottom: 80,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
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
                            'Tap to show controls',
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
            ),
        ],
      ),
    );
  }
}
