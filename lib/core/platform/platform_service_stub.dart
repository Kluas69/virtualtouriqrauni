import 'dart:async';
import 'dart:io' show Platform;
import 'platform_service.dart';

/// Factory function for creating platform service
PlatformService createPlatformService() => StubPlatformService();

/// Stub implementation of PlatformService for non-web platforms
/// 
/// This implementation provides fallback behavior for mobile and desktop
/// platforms where web-specific features are not available.
class StubPlatformService implements PlatformService {
  static final StubPlatformService _instance = StubPlatformService._internal();
  factory StubPlatformService() => _instance;
  StubPlatformService._internal();
  
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  @override
  bool get isWebPlatform => false;
  
  @override
  bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;
  
  @override
  bool get isDesktopPlatform => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  
  @override
  String get userAgent => '';
  
  @override
  Future<bool> initializeWebGL() async {
    // WebGL not available on non-web platforms
    return false;
  }
  
  @override
  void registerWebView(String viewType, Function factory) {
    // No-op on non-web platforms
  }
  
  @override
  void postMessage(Map<String, dynamic> message) {
    // No-op on non-web platforms
  }
  
  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  @override
  Size getScreenSize() {
    // Return default size for non-web platforms
    // In a real implementation, this could use platform-specific APIs
    if (isMobilePlatform) {
      return const Size(375.0, 812.0); // iPhone-like dimensions
    } else {
      return const Size(1920.0, 1080.0); // Desktop dimensions
    }
  }
  
  @override
  bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'webgl':
        return false; // WebGL not available on non-web platforms
      case 'iframe':
        return false; // iframes not available on non-web platforms
      case 'local_storage':
        return true; // Can be implemented with shared_preferences
      case 'session_storage':
        return false; // Session storage not available on non-web platforms
      case 'native_navigation':
        return true; // Native navigation available on mobile/desktop
      case 'file_system':
        return true; // File system access available on mobile/desktop
      default:
        return false;
    }
  }
}