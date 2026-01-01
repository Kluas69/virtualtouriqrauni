import 'webgl_service.dart';
import 'webgl_service_impl.dart'
    if (dart.library.html) 'webgl_service_impl_web.dart';

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
    // On web: returns WebGLServiceWeb()
    // On other platforms: returns WebGLServiceStub()
    return createWebGLService();
  }
  
  /// Resets the singleton instance (useful for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}