import 'dart:html' as html;

class WebGLOptimizer {
  static bool isMobileDevice() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('android') ||
        userAgent.contains('ipad') ||
        userAgent.contains('mobile');
  }

  static String optimizeWebGLUrl(String baseUrl, bool isMobile) {
    if (!isMobile) return baseUrl;

    // Add Unity quality parameters for mobile
    final separator = baseUrl.contains('?') ? '&' : '?';
    return '$baseUrl${separator}quality=low&compression=high&mobile=true';
  }

  static Map<String, dynamic> getMobileWarningConfig() {
    return {
      'showWarning': true,
      'estimatedSize': '50-150 MB',
      'dataWarning': 'This will use significant mobile data',
      'performanceWarning': 'Performance may be limited on mobile devices',
      'recommendDesktop': true,
    };
  }
}
