import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'webgl_service.dart';
import '../logging/app_logger.dart';

/// Simple web-specific implementation of WebGL service
class WebGLServiceWebSimple implements WebGLService {
  @override
  Future<bool> isSupported() async {
    try {
      final canvas = html.CanvasElement();
      var context = canvas.getContext('webgl2') ?? canvas.getContext('webgl') ?? canvas.getContext('experimental-webgl');
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
      renderer: 'Unknown',
      vendor: 'Unknown',
      instancingSupport: false,
      floatTextureSupport: false,
      compressedTextureSupport: false,
    );
  }
  
  @override
  Future<bool> supportsExtension(String extension) async => false;
  
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
  
  QualityLevel _currentQuality = QualityLevel.high;
  
  @override
  void setQualityLevel(QualityLevel level) {
    _currentQuality = level;
  }
  
  @override
  QualityLevel get currentQuality => _currentQuality;
  
  @override
  Future<bool> canRenderGLB() async => true;
  
  @override
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  }) {
    // Create a stable view type that doesn't change
    final viewType = 'webgl-classroom-viewer-stable';
    
    // Only register once to prevent multiple registrations
    try {
      // Register the HTML view factory
      ui.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = './web/threejs/classroom-viewer-working.html'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.display = 'block'
            ..allow = 'accelerometer; gyroscope; magnetometer'
            ..allowFullscreen = true;
          
          // Handle iframe load events
          iframe.onLoad.listen((_) {
            AppLogger.info('3D classroom viewer loaded successfully',
              component: 'WebGLServiceWebSimple');
            onLoaded?.call();
          });
          
          iframe.onError.listen((event) {
            AppLogger.error('3D classroom viewer failed to load',
              component: 'WebGLServiceWebSimple',
              error: event);
            onError?.call('Failed to load 3D classroom viewer');
          });
          
          // Listen for messages from the iframe
          html.window.onMessage.listen((event) {
            if (event.data is Map && event.data['type'] == 'classroomLoaded') {
              AppLogger.info('Classroom model loaded in iframe',
                component: 'WebGLServiceWebSimple');
              onLoaded?.call();
            }
          });
          
          return iframe;
        },
      );
    } catch (e) {
      // View factory already registered, which is fine
      AppLogger.debug('View factory already registered: $viewType',
        component: 'WebGLServiceWebSimple');
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
  
  @override
  void registerViewFactory(String viewType, Function factory) {
    // No-op for simple implementation
  }
  
  @override
  Future<void> initialize() async {
    // Simple initialization
  }
  
  @override
  Future<void> handleContextLoss() async {
    // No-op
  }
  
  @override
  Future<bool> attemptContextRecovery() async => true;
  
  @override
  void dispose() {
    // No-op
  }
}