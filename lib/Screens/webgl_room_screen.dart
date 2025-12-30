// lib/Screens/webgl_room_screen.dart - OPTIMIZED FOR MOBILE
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:virtualtouriu/core/widgets/circular_control_button.dart';
import 'package:virtualtouriu/core/widgets/error_state.dart';
import 'package:virtualtouriu/core/widgets/glassmorphic_container.dart';
import 'package:virtualtouriu/core/widgets/loading_state.dart';
import 'package:virtualtouriu/core/widgets/tag_badge.dart';
import 'package:virtualtouriu/core/utils/webgl_optimizer.dart';
import 'package:virtualtouriu/themes/Themes.dart';

class WebGlRoomScreen extends StatefulWidget {
  final String url;
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

  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  bool _isFullScreen = false;
  bool _showMobileWarning = false;
  bool _isMobile = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _viewType =
        'webgl-iframe-${widget.url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _initializeAnimations();
    _checkDeviceAndLoad();
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

  void _checkDeviceAndLoad() {
    _isMobile = WebGLOptimizer.isMobileDevice();

    if (_isMobile) {
      setState(() => _showMobileWarning = true);
    } else {
      _registerIframe();
      _hideControlsAfterDelay();
    }
  }

  void _proceedAnyway() {
    setState(() => _showMobileWarning = false);
    _registerIframe();
    _hideControlsAfterDelay();
  }

  void _registerIframe() {
    if (!mounted) return;

    try {
      if (!_registeredViewTypes.contains(_viewType)) {
        ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
          // Optimize URL for mobile
          final optimizedUrl = WebGLOptimizer.optimizeWebGLUrl(
            widget.url,
            _isMobile,
          );

          final iframe =
              html.IFrameElement()
                ..src = optimizedUrl
                ..style.border = '0'
                ..style.width = '100%'
                ..style.height = '100%'
                ..style.display = 'block'
                ..allowFullscreen = true
                ..setAttribute('loading', _isMobile ? 'lazy' : 'eager')
                ..setAttribute('importance', _isMobile ? 'low' : 'high')
                ..allow =
                    'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; xr-spatial-tracking; fullscreen';

          bool hasLoaded = false;
          bool hasTimedOut = false;

          iframe.onLoad.listen((_) {
            if (!hasTimedOut && mounted) {
              hasLoaded = true;
              setState(() {
                _isLoading = false;
                _hasError = false;
              });
            }
          });

          iframe.onError.listen((event) {
            if (!hasTimedOut && mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = 'Failed to load Unity WebGL content';
              });
            }
          });

          // Longer timeout for mobile
          final timeoutDuration =
              _isMobile
                  ? const Duration(seconds: 60)
                  : const Duration(seconds: 45);

          Future.delayed(timeoutDuration, () {
            if (!hasLoaded && mounted) {
              hasTimedOut = true;
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage =
                    'Connection timeout. Please check your internet connection.';
              });
            }
          });

          return iframe;
        });

        _registeredViewTypes.add(_viewType);
      }
    } catch (e) {
      debugPrint('Error registering iframe: $e');
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
      if (mounted && _showControls && !_isFullScreen) {
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

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = true;
      _fadeController.reverse();
    });
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
        _registerIframe();
        _showSnackBar('Refreshing 3D tour...');
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

    if (_showMobileWarning) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildMobileWarning(theme),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_hasError)
            GestureDetector(
              onTap: _toggleControls,
              child: HtmlElementView(viewType: _viewType),
            ),
          if (_hasError)
            ErrorState(
              message:
                  _errorMessage ??
                  'Unable to load the 3D tour. This could be due to:\n\n'
                      '• Poor internet connection\n'
                      '• Unity WebGL compression issues\n'
                      '• Server MIME type configuration\n'
                      '• Browser compatibility\n'
                      '• Device limitations',
              onRetry: _refresh,
              onBack: () => Navigator.pop(context),
            ),
          if (_isLoading && !_hasError)
            LoadingState(
              message:
                  _isMobile
                      ? 'Loading 3D Tour (Mobile Quality)...'
                      : 'Loading 3D Tour...',
              isDark: isDark,
            ),
          if (!_showControls && !_isLoading && !_hasError)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          if (_showControls && !_isLoading && !_hasError)
            _buildTopControls(isDark, theme, themeProvider),
          if (_showControls && !_isLoading && !_hasError)
            _buildBottomControls(isDark, theme),
          if (!_showControls && !_isLoading && !_hasError) _buildControlsHint(),
        ],
      ),
    );
  }

  Widget _buildMobileWarning(ThemeData theme) {
    final warningConfig = WebGLOptimizer.getMobileWarningConfig();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: Colors.orange.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Mobile Device Detected',
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.data_usage,
                            color: Colors.red.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              warningConfig['dataWarning'] as String,
                              style: GoogleFonts.roboto(
                                color: Colors.red.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estimated: ${warningConfig['estimatedSize']}',
                        style: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  '3D tours may experience:\n\n'
                  '• Slow performance\n'
                  '• High battery drain\n'
                  '• Mobile data usage\n'
                  '• Display issues\n'
                  '• Compression errors\n\n'
                  'We recommend using a desktop or laptop computer for the best experience.',
                  style: GoogleFonts.roboto(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _proceedAnyway,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Proceed',
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
              ),
              const SizedBox(height: 40),
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
          child: GlassmorphicContainer(
            isDark: isDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircularControlButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                  size: 48,
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
                          fontSize: _isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TagBadge(text: '3D TOUR', fontSize: 10),
                          if (_isMobile) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                'LOW QUALITY',
                                style: GoogleFonts.roboto(
                                  color: Colors.orange.shade300,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CircularControlButton(
                  icon: isDark ? Icons.light_mode : Icons.dark_mode,
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                  iconColor: isDark ? Colors.amber : Colors.indigo,
                  size: 48,
                ),
              ],
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
            child: GlassmorphicContainer(
              isDark: isDark,
              borderRadius: 30,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularControlButton(
                    icon: Icons.refresh,
                    onPressed: _refresh,
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 16),
                  CircularControlButton(
                    icon:
                        _isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                    onPressed: _toggleFullScreen,
                    tooltip: 'Toggle Fullscreen',
                  ),
                  const SizedBox(width: 16),
                  CircularControlButton(
                    icon: Icons.info_outline,
                    onPressed:
                        () => _showSnackBar(
                          _isMobile
                              ? 'Use touch controls to navigate (Mobile Mode)'
                              : 'Navigate using mouse/touch controls',
                        ),
                    tooltip: 'Tour Info',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsHint() {
    return Positioned(
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
    );
  }
}
