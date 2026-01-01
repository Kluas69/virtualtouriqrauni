import 'package:flutter/material.dart';

/// Abstract interface for WebGL/3D model viewing functionality
abstract class WebGLService {
  /// Check if WebGL is supported on current platform
  Future<bool> isSupported();
  
  /// Create a WebGL viewer widget for the given model URL
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  });
  
  /// Register a web view factory for WebGL content
  void registerViewFactory(String viewType, Function factory);
  
  /// Initialize WebGL context and resources
  Future<void> initialize();
  
  /// Cleanup WebGL resources
  void dispose();
}

/// WebGL viewer configuration
class WebGLConfig {
  final String modelUrl;
  final String title;
  final bool enableControls;
  final bool enableLighting;
  final Color backgroundColor;
  
  const WebGLConfig({
    required this.modelUrl,
    required this.title,
    this.enableControls = true,
    this.enableLighting = true,
    this.backgroundColor = Colors.black,
  });
}