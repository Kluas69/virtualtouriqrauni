/// Abstract interface for platform-specific operations
/// 
/// This interface provides a unified API for platform-specific functionality
/// while allowing different implementations for web, mobile, and desktop platforms.
abstract class PlatformService {
  /// Returns true if running on web platform
  bool get isWebPlatform;
  
  /// Returns true if running on mobile platform (iOS/Android)
  bool get isMobilePlatform;
  
  /// Returns true if running on desktop platform (Windows/macOS/Linux)
  bool get isDesktopPlatform;
  
  /// Returns the user agent string (web-specific, empty string on other platforms)
  String get userAgent;
  
  /// Initializes WebGL context and resources (web-only)
  /// Returns true if successful, false if not supported
  Future<bool> initializeWebGL();
  
  /// Registers a web view factory for iframe embedding (web-only)
  /// No-op on other platforms
  void registerWebView(String viewType, Function factory);
  
  /// Posts a message to web context (web-only)
  /// No-op on other platforms
  void postMessage(Map<String, dynamic> message);
  
  /// Stream of messages from web context (web-only)
  /// Empty stream on other platforms
  Stream<Map<String, dynamic>> get messageStream;
  
  /// Gets screen dimensions
  Size getScreenSize();
  
  /// Checks if a specific feature is available on current platform
  bool isFeatureAvailable(String feature);
}

/// Screen size representation
class Size {
  final double width;
  final double height;
  
  const Size(this.width, this.height);
  
  @override
  String toString() => 'Size($width, $height)';
}