import 'package:flutter/material.dart';
import 'webgl_service.dart';
import '../logging/app_logger.dart';

/// Stub implementation of WebGL service for non-web platforms
class WebGLServiceStub implements WebGLService {
  static final WebGLServiceStub _instance = WebGLServiceStub._internal();
  factory WebGLServiceStub() => _instance;
  WebGLServiceStub._internal();
  
  @override
  Future<bool> isSupported() async {
    // WebGL is not supported on non-web platforms
    return false;
  }
  
  @override
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  }) {
    return WebGLFallbackWidget(
      title: title,
      url: url,
      onError: onError,
    );
  }
  
  @override
  void registerViewFactory(String viewType, Function factory) {
    // No-op on non-web platforms
    AppLogger.debug('WebGL view factory registration skipped (non-web platform)',
      component: 'WebGLService',
      metadata: {'viewType': viewType});
  }
  
  @override
  Future<void> initialize() async {
    AppLogger.info('WebGL service initialized (stub mode)',
      component: 'WebGLService');
  }
  
  @override
  void dispose() {
    AppLogger.debug('WebGL service disposed (stub mode)',
      component: 'WebGLService');
  }
}

/// Fallback widget for non-web platforms
class WebGLFallbackWidget extends StatelessWidget {
  final String title;
  final String url;
  final Function(String)? onError;
  
  const WebGLFallbackWidget({
    super.key,
    required this.title,
    required this.url,
    this.onError,
  });
  
  @override
  Widget build(BuildContext context) {
    // Notify about the fallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onError?.call('WebGL not available on this platform');
    });
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 80,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '3D View Not Available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WebGL 3D viewing is only available on web browsers.\nUse the panorama view for an immersive experience.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}