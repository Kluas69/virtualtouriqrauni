import 'package:flutter/material.dart';

/// WebGL capabilities information
class WebGLCapabilities {
  final bool webgl2Support;
  final bool webgl1Support;
  final List<String> supportedExtensions;
  final int maxTextureSize;
  final int maxVertexAttributes;
  final String renderer;
  final String vendor;
  final bool instancingSupport;
  final bool floatTextureSupport;
  final bool compressedTextureSupport;
  final Map<String, dynamic> additionalInfo;

  const WebGLCapabilities({
    required this.webgl2Support,
    required this.webgl1Support,
    required this.supportedExtensions,
    required this.maxTextureSize,
    required this.maxVertexAttributes,
    required this.renderer,
    required this.vendor,
    required this.instancingSupport,
    required this.floatTextureSupport,
    required this.compressedTextureSupport,
    this.additionalInfo = const {},
  });

  bool get hasWebGLSupport => webgl2Support || webgl1Support;
  
  String get webglVersion => webgl2Support ? 'WebGL 2.0' : webgl1Support ? 'WebGL 1.0' : 'None';
  
  Map<String, dynamic> toMap() {
    return {
      'webgl2Support': webgl2Support,
      'webgl1Support': webgl1Support,
      'supportedExtensions': supportedExtensions,
      'maxTextureSize': maxTextureSize,
      'maxVertexAttributes': maxVertexAttributes,
      'renderer': renderer,
      'vendor': vendor,
      'instancingSupport': instancingSupport,
      'floatTextureSupport': floatTextureSupport,
      'compressedTextureSupport': compressedTextureSupport,
      'webglVersion': webglVersion,
      ...additionalInfo,
    };
  }
}

/// WebGL performance metrics for monitoring
class WebGLPerformanceMetrics {
  final int triangleCount;
  final int drawCalls;
  final int textureCount;
  final double memoryUsageMB;
  final double currentFPS;
  final bool isOptimized;
  final DateTime timestamp;

  const WebGLPerformanceMetrics({
    required this.triangleCount,
    required this.drawCalls,
    required this.textureCount,
    required this.memoryUsageMB,
    required this.currentFPS,
    required this.isOptimized,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'triangleCount': triangleCount,
      'drawCalls': drawCalls,
      'textureCount': textureCount,
      'memoryUsageMB': memoryUsageMB,
      'currentFPS': currentFPS,
      'isOptimized': isOptimized,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Quality levels for dynamic adjustment
enum QualityLevel {
  low(0.3, 'Low'),
  medium(0.6, 'Medium'), 
  high(1.0, 'High'),
  ultra(1.2, 'Ultra');

  const QualityLevel(this.multiplier, this.displayName);
  
  final double multiplier;
  final String displayName;
}

/// Enhanced WebGL service interface
abstract class WebGLService {
  /// Initialize the WebGL service
  Future<void> initialize();
  
  /// Check if WebGL is supported (legacy method)
  Future<bool> isSupported();
  
  /// Enhanced capability detection with detailed information
  Future<WebGLCapabilities> detectCapabilities();
  
  /// Check if GLB files can be rendered specifically
  Future<bool> canRenderGLB();
  
  /// Check if a specific WebGL extension is supported
  Future<bool> supportsExtension(String extension);
  
  /// Handle WebGL context loss and attempt recovery
  Future<void> handleContextLoss();
  
  /// Attempt to recover from WebGL context loss
  Future<bool> attemptContextRecovery();
  
  /// Get real-time performance metrics stream
  Stream<WebGLPerformanceMetrics> get performanceStream;
  
  /// Set quality level for rendering
  void setQualityLevel(QualityLevel level);
  
  /// Get current quality level
  QualityLevel get currentQuality;
  
  /// Create a WebGL viewer widget
  Widget createViewer({
    required String url,
    required String title,
    VoidCallback? onLoaded,
    Function(String)? onError,
  });
  
  /// Register a view factory for web platform
  void registerViewFactory(String viewType, Function factory);
  
  /// Dispose of resources
  void dispose();
}