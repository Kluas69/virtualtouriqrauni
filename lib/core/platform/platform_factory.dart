import 'platform_service.dart';
import 'platform_service_stub.dart'
    if (dart.library.html) 'platform_service_web.dart';

/// Factory for creating platform-specific service instances
/// 
/// This factory uses Dart's conditional imports to provide the correct
/// implementation based on the target platform. Web builds will get
/// WebPlatformService, while other platforms get StubPlatformService.
class PlatformFactory {
  static PlatformService? _instance;
  
  /// Gets the singleton instance of the platform service
  static PlatformService get instance {
    _instance ??= _createPlatformService();
    return _instance!;
  }
  
  /// Creates the appropriate platform service implementation
  static PlatformService _createPlatformService() {
    // Use conditional compilation to select the right implementation
    return _createPlatformServiceImpl();
  }
  
  /// Platform-specific implementation creation
  /// This will be resolved to the correct implementation at compile time
  static PlatformService _createPlatformServiceImpl() {
    // This will resolve to WebPlatformService on web, StubPlatformService elsewhere
    return createPlatformService();
  }
  
  /// Resets the singleton instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}