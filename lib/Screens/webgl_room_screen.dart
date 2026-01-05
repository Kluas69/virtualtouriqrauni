import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/webgl/webgl_service_web_simple.dart';
import '../core/logging/app_logger.dart';
import '../core/platform/platform_utils.dart';

/// Simplified WebGL Room Screen that properly loads professional_classroom_enhanced.html
class WebGLRoomScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebGLRoomScreen({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  State<WebGLRoomScreen> createState() => _WebGLRoomScreenState();
}

class _WebGLRoomScreenState extends State<WebGLRoomScreen> {
  static const String _logComponent = 'WebGLRoomScreen';
  
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  late WebGLServiceWebSimple _webglService;
  html.IFrameElement? _iframe;
  
  @override
  void initState() {
    super.initState();
    _initializeWebGL();
  }

  void _initializeWebGL() {
    try {
      _webglService = WebGLServiceWebSimple();
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
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildLoadingView(isDark);
    }
    
    if (_hasError) {
      return _buildErrorView(isDark);
    }
    
    return _build3DViewer(isDark);
  }

  Widget _buildLoadingView(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey.shade900, Colors.black]
              : [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.blue.shade300 : Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading 3D Environment...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Initializing WebGL and loading ${widget.title}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.red.shade900.withOpacity(0.3), Colors.black]
              : [Colors.red.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.red.shade300 : Colors.red.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to Load 3D Viewer',
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
                        ? Colors.red.shade900.withOpacity(0.2)
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
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
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
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                        _errorMessage = null;
                      });
                      _initializeWebGL();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark 
                          ? Colors.green.shade700
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
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

  Widget _buildFallbackViewer(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.blue.shade900, Colors.purple.shade900]
              : [Colors.blue.shade100, Colors.purple.shade100],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.view_in_ar,
                size: 64,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                '3D Viewer',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This platform shows a fallback view.\n3D viewing is optimized for web browsers.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      // Clean up resources
      AppLogger.info('Disposing WebGL room screen', component: _logComponent);
    } catch (e) {
      AppLogger.warning('Error during disposal: $e', component: _logComponent);
    }
    super.dispose();
  }
}