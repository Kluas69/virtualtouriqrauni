import 'webgl_service.dart';
import 'webgl_service_unified.dart'
    if (dart.library.html) 'webgl_service_unified.dart';

/// Factory for creating platform-specific WebGL service instances
class WebGLFactory {
  static WebGLService? _instance;
  
  /// Gets the singleton instance of the WebGL service
  static WebGLService get instance {
    _instance ??= _createWebGLService();
    return _instance!;
  }
  
  /// Creates the appropriate WebGL service implementation
  static WebGLService _createWebGLService() {
    // Returns the unified WebGL service
    return WebGLServiceUnified();
  }
  
  /// Resets the singleton instance (useful for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}